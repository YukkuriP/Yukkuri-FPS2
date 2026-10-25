import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.164.1/build/three.module.js";

const $ = id => document.getElementById(id);
const intro = $("intro"), lobby = $("lobby"), game = $("game"), statusEl = $("status");
let socket = null, renderer, scene, camera, me, yaw = 0, pitch = 0, last = performance.now();
let peers = new Map(), move = {forward:false,back:false,left:false,right:false};
let touchLook = false, lastTouch = null, joined = false;
const playerId = crypto.randomUUID ? crypto.randomUUID() : String(Math.random()).slice(2);
const palette = [0x8db9d9,0xd2a56e,0x9cc8a4,0xc5a1db,0xd58c8c,0xd7d7a0];
setTimeout(() => { intro.classList.add("hidden"); lobby.classList.remove("hidden"); }, 2700);

$("joinBtn").addEventListener("click", connectOnline);
$("leaveBtn").addEventListener("click", leaveGame);
window.addEventListener("keydown", e => setKey(e.key,true));
window.addEventListener("keyup", e => setKey(e.key,false));
function setKey(key,on){const k=key.toLowerCase();if(k==="w"||k==="arrowup")move.forward=on;if(k==="s"||k==="arrowdown")move.back=on;if(k==="a"||k==="arrowleft")move.left=on;if(k==="d"||k==="arrowright")move.right=on;}
document.querySelectorAll("[data-move]").forEach(b=>{const key=b.dataset.move;b.addEventListener("pointerdown",e=>{e.preventDefault();move[key]=true});for(const ev of ["pointerup","pointercancel","pointerleave"])b.addEventListener(ev,()=>move[key]=false)});
$("view").addEventListener("click",()=>{if(!matchMedia("(pointer:coarse)").matches && document.pointerLockElement!==$("view"))$("view").requestPointerLock?.()});
document.addEventListener("mousemove",e=>{if(joined && document.pointerLockElement===$("view")){yaw-=e.movementX*.002;pitch=Math.max(-1.2,Math.min(1.2,pitch-e.movementY*.002));}});
$("view").addEventListener("pointerdown",e=>{if(e.pointerType==="touch" && e.clientX>innerWidth*.48){touchLook=true;lastTouch={x:e.clientX,y:e.clientY};}});
$("view").addEventListener("pointermove",e=>{if(touchLook&&lastTouch){yaw-=(e.clientX-lastTouch.x)*.008;pitch=Math.max(-1.2,Math.min(1.2,pitch-(e.clientY-lastTouch.y)*.008));lastTouch={x:e.clientX,y:e.clientY};}});
for(const ev of ["pointerup","pointercancel"])$("view").addEventListener(ev,()=>{touchLook=false;lastTouch=null});

function connectOnline(){
 const url=$("serverUrl").value.trim(), name=$("playerName").value.trim()||"Operator", room=$("roomCode").value.trim().toUpperCase()||"IRON-01";
 if(!url.startsWith("wss://")&&!url.startsWith("ws://")){statusEl.textContent="WebSocketサーバーURLを入力してください。公開サイトでは通常 wss:// が必要です。";return;}
 statusEl.textContent="サーバーへ接続中…";
 try{socket=new WebSocket(url)}catch(e){statusEl.textContent="URLを確認してください: "+e.message;return;}
 socket.onopen=()=>{socket.send(JSON.stringify({type:"join",id:playerId,name,room}));statusEl.textContent="接続しました。ルームに参加しています。";joined=true;lobby.classList.add("hidden");game.classList.remove("hidden");initScene();};
 socket.onmessage=e=>{let data;try{data=JSON.parse(e.data)}catch{return;}if(data.type==="state")updatePeers(data.players||[]);if(data.type==="notice")statusEl.textContent=data.message||"";};
 socket.onerror=()=>{statusEl.textContent="接続できません。サーバーURLとサーバーの起動状態を確認してください。";};
 socket.onclose=()=>{if(joined){joined=false;game.classList.add("hidden");lobby.classList.remove("hidden");statusEl.textContent="サーバーから切断されました。";}};
}
function initScene(){
 scene=new THREE.Scene();scene.background=new THREE.Color(0x8295a5);scene.fog=new THREE.Fog(0x8295a5,24,70);
 camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,.1,100);camera.position.set(0,1.65,10);
 renderer=new THREE.WebGLRenderer({canvas:$("view"),antialias:false,powerPreference:"low-power"});renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);renderer.outputColorSpace=THREE.SRGBColorSpace;
 scene.add(new THREE.HemisphereLight(0xcbd9e5,0x303944,2));
 const sun=new THREE.DirectionalLight(0xffffff,1.4);sun.position.set(-5,12,6);scene.add(sun);
 const mat=(color)=>new THREE.MeshStandardMaterial({color,roughness:.9});
 const floor=new THREE.Mesh(new THREE.BoxGeometry(40,1,40),mat(0x414c53));floor.position.y=-.5;scene.add(floor);
 for(let i=0;i<10;i++){const x=-15+i*3.3;addBox(x,1,-10,1.4,2,1.4,0x66747c);addBox(x,1,10,1.4,2,1.4,0x66747c);}
 addBox(-10,1.3,0,2,2.6,5,0x59666d);addBox(10,1.3,-2,2,2.6,5,0x59666d);addBox(0,.9,0,4,1.8,2,0x7b8588);
 me=new THREE.Mesh(new THREE.CapsuleGeometry(.35,.9,4,8),mat(0x8db9d9));me.position.set(0,.8,10);scene.add(me);
 window.addEventListener("resize",resize);requestAnimationFrame(frame);
}
function addBox(x,y,z,sx,sy,sz,color){const m=new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),new THREE.MeshStandardMaterial({color,roughness:.95}));m.position.set(x,y,z);scene.add(m);}
function resize(){if(!renderer||!camera)return;camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);}
function updatePeers(list){const alive=new Set();for(const p of list){if(p.id===playerId)continue;alive.add(p.id);let obj=peers.get(p.id);if(!obj){obj=new THREE.Mesh(new THREE.CapsuleGeometry(.35,.9,4,8),new THREE.MeshStandardMaterial({color:palette[peers.size%palette.length]}));scene?.add(obj);peers.set(p.id,obj);}obj.position.set(Number(p.x)||0,.8,Number(p.z)||0);obj.rotation.y=Number(p.yaw)||0;}for(const [id,obj] of peers){if(!alive.has(id)){scene?.remove(obj);obj.geometry.dispose();obj.material.dispose();peers.delete(id);}}$("players").textContent="接続プレイヤー: "+list.length;}
function frame(now){if(!joined||!renderer||!scene)return;const dt=Math.min((now-last)/1000,.05);last=now;
 const forward=Number(move.forward)-Number(move.back), side=Number(move.right)-Number(move.left);const len=Math.hypot(forward,side)||1;
 const dx=(Math.sin(yaw)*forward+Math.cos(yaw)*side)/len*4*dt;const dz=(-Math.cos(yaw)*forward+Math.sin(yaw)*side)/len*4*dt;
 camera.position.x=Math.max(-17,Math.min(17,camera.position.x+dx));camera.position.z=Math.max(-17,Math.min(17,camera.position.z+dz));camera.position.y=1.65;
 camera.rotation.order="YXZ";camera.rotation.y=yaw;camera.rotation.x=pitch;me.position.set(camera.position.x,.8,camera.position.z);me.rotation.y=yaw;
 if(socket?.readyState===WebSocket.OPEN)socket.send(JSON.stringify({type:"move",id:playerId,x:camera.position.x,z:camera.position.z,yaw}));
 renderer.render(scene,camera);requestAnimationFrame(frame);
}
function leaveGame(){joined=false;if(socket){socket.close();socket=null;}if(renderer){renderer.dispose();renderer=null;}scene=null;camera=null;me=null;peers.clear();game.classList.add("hidden");lobby.classList.remove("hidden");statusEl.textContent="ロビーに戻りました。";}
