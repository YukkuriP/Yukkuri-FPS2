import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.164.1/build/three.module.js";

const $ = id => document.getElementById(id);
const intro = $("intro"), lobby = $("lobby"), game = $("game"), statusEl = $("status");
let socket = null, renderer, scene, camera, me, yaw = 0, pitch = 0, last = performance.now();
let peers = new Map(), move = {forward:false,back:false,left:false,right:false};
let touchLook = false, lastTouch = null, joined = false, onlineMode = false;
let objectives = [], objectiveIndex = 0, timeLeft = 180, missionEnded = false;
const playerId = crypto.randomUUID ? crypto.randomUUID() : String(Math.random()).slice(2);
const palette = [0x8db9d9,0xd2a56e,0x9cc8a4,0xc5a1db,0xd58c8c,0xd7d7a0];
setTimeout(() => { intro.classList.add("hidden"); lobby.classList.remove("hidden"); }, 1700);

$("offlineBtn").addEventListener("click", startOffline);
$("showOnlineBtn").addEventListener("click", () => {
 $("onlinePanel").classList.remove("hidden");
 statusEl.textContent="接続先を確認してから接続してください。";
});
$("backModesBtn").addEventListener("click", () => $("onlinePanel").classList.add("hidden"));
$("joinBtn").addEventListener("click", connectOnline);
$("leaveBtn").addEventListener("click", leaveGame);
window.addEventListener("keydown", e => setKey(e.key,true));
window.addEventListener("keyup", e => setKey(e.key,false));
function setKey(key,on){
 const k=key.toLowerCase();
 if(k==="w"||k==="arrowup")move.forward=on;
 if(k==="s"||k==="arrowdown")move.back=on;
 if(k==="a"||k==="arrowleft")move.left=on;
 if(k==="d"||k==="arrowright")move.right=on;
}
document.querySelectorAll("[data-move]").forEach(b=>{
 const key=b.dataset.move;
 b.addEventListener("pointerdown",e=>{e.preventDefault();move[key]=true});
 for(const ev of ["pointerup","pointercancel","pointerleave"])b.addEventListener(ev,()=>move[key]=false);
});
$("view").addEventListener("click",()=>{
 if(!matchMedia("(pointer:coarse)").matches && document.pointerLockElement!==$("view"))$("view").requestPointerLock?.();
});
document.addEventListener("mousemove",e=>{
 if(joined && document.pointerLockElement===$("view")){
  yaw-=e.movementX*.002;
  pitch=Math.max(-1.2,Math.min(1.2,pitch-e.movementY*.002));
 }
});
$("view").addEventListener("pointerdown",e=>{
 if(e.pointerType==="touch" && e.clientX>innerWidth*.48){touchLook=true;lastTouch={x:e.clientX,y:e.clientY};}
});
$("view").addEventListener("pointermove",e=>{
 if(touchLook&&lastTouch){
  yaw-=(e.clientX-lastTouch.x)*.008;
  pitch=Math.max(-1.2,Math.min(1.2,pitch-(e.clientY-lastTouch.y)*.008));
  lastTouch={x:e.clientX,y:e.clientY};
 }
});
for(const ev of ["pointerup","pointercancel"])$("view").addEventListener(ev,()=>{touchLook=false;lastTouch=null});

function startOffline(){
 if(socket){const old=socket;socket=null;old.close();}
 onlineMode=false;
 $("roomLabel").textContent="TRAINING";
 $("players").textContent="オフライン訓練";
 beginGame();
}
function connectOnline(){
 const url=$("serverUrl").value.trim(), name=$("playerName").value.trim()||"Operator", room=$("roomCode").value.trim().toUpperCase()||"IRON-01";
 if(!url.startsWith("wss://")){statusEl.textContent="wss:// で始まる安全なサーバーURLを入力してください。";return;}
 statusEl.textContent="サーバーへ接続中…";
 $("joinBtn").disabled=true;
 try{socket=new WebSocket(url)}catch(e){statusEl.textContent="URLを確認してください: "+e.message;$("joinBtn").disabled=false;return;}
 const current=socket;
 current.onopen=()=>{
  if(socket!==current)return;
  onlineMode=true;
  current.send(JSON.stringify({type:"join",id:playerId,name,room}));
  statusEl.textContent="接続しました。";
  $("roomLabel").textContent=room;
  $("joinBtn").disabled=false;
  beginGame();
 };
 current.onmessage=e=>{
  let data;try{data=JSON.parse(e.data)}catch{return;}
  if(data.type==="state")updatePeers(data.players||[]);
  if(data.type==="notice")statusEl.textContent=data.message||"";
 };
 current.onerror=()=>{
  if(socket!==current)return;
  statusEl.textContent="接続できません。サーバー状態・URL・ネットワークの許可設定を確認してください。オフラインモードは引き続き利用できます。";
  $("joinBtn").disabled=false;
 };
 current.onclose=()=>{
  $("joinBtn").disabled=false;
  if(socket===current)socket=null;
  if(joined&&onlineMode){
   joined=false;onlineMode=false;
   game.classList.add("hidden");lobby.classList.remove("hidden");
   $("onlinePanel").classList.remove("hidden");
   statusEl.textContent="サーバーから切断されました。オフラインモードは引き続き利用できます。";
  }
 };
}
function beginGame(){
 joined=true;missionEnded=false;objectiveIndex=0;timeLeft=180;yaw=0;pitch=0;last=performance.now();
 lobby.classList.add("hidden");game.classList.remove("hidden");
 initScene();
 updateMissionHud();
 $("objectiveBanner").textContent="作戦開始 — 3か所の目標地点を確保せよ";
}
function initScene(){
 if(renderer){renderer.dispose();renderer=null;}
 scene=new THREE.Scene();
 scene.background=new THREE.Color(0x748795);
 scene.fog=new THREE.Fog(0x748795,25,75);
 camera=new THREE.PerspectiveCamera(76,innerWidth/innerHeight,.1,120);
 camera.position.set(0,1.65,15);
 renderer=new THREE.WebGLRenderer({canvas:$("view"),antialias:false,powerPreference:"low-power"});
 renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));
 renderer.setSize(innerWidth,innerHeight);
 renderer.outputColorSpace=THREE.SRGBColorSpace;
 scene.add(new THREE.HemisphereLight(0xd9e8f4,0x28333b,2.0));
 const sun=new THREE.DirectionalLight(0xffe7c4,2.0);sun.position.set(-12,18,8);scene.add(sun);
 const mat=(color,roughness=.88)=>new THREE.MeshStandardMaterial({color,roughness});
 const floor=new THREE.Mesh(new THREE.BoxGeometry(42,1,42),mat(0x35434b));floor.position.y=-.5;scene.add(floor);
 for(let i=0;i<11;i++){
  const x=-16+i*3.2;
  addBox(x,1,-13,1.35,2,1.35,0x58666e);
  addBox(x,1,13,1.35,2,1.35,0x58666e);
  addBox(x,.012,0,.045,.02,25,i%2?0x71818a:0x9aa5a7);
 }
 addBox(-10,1.25,1,2.5,2.5,5,0x53616a);
 addBox(10,1.25,-2,2.5,2.5,5,0x53616a);
 addBox(-4,.8,-5,3,1.6,2.2,0x65737a);
 addBox(5,.7,6,3.2,1.4,2.4,0x65737a);
 addBox(0,.95,0,3.8,1.9,2,0x7c898d);
 addBox(-7,.7,7,2.5,1.4,2.2,0x4c5c65);
 addBox(8,.65,7,2.2,1.3,2.5,0x4c5c65);
 for(const x of [-12,-4,4,12]){
  addBox(x,4,-8,.18,.18,.18,0xffc76a);
  const lamp=new THREE.PointLight(0xffbd69,7,8);lamp.position.set(x,3.8,-8);scene.add(lamp);
 }
 me=new THREE.Mesh(new THREE.CapsuleGeometry(.35,.9,4,8),mat(0x8db9d9));
 me.position.set(0,.8,15);scene.add(me);
 const points=[new THREE.Vector3(-12,0,-9),new THREE.Vector3(12,0,-7),new THREE.Vector3(0,0,8)];
 objectives=points.map(p=>{
  const group=new THREE.Group();group.position.copy(p);
  const ring=new THREE.Mesh(new THREE.TorusGeometry(1.5,.09,8,40),new THREE.MeshStandardMaterial({color:0xffc45e,emissive:0x5a3000,emissiveIntensity:.8}));
  ring.rotation.x=Math.PI/2;ring.position.y=.08;group.add(ring);
  const pillar=new THREE.Mesh(new THREE.CylinderGeometry(.08,.16,2.4,8),new THREE.MeshStandardMaterial({color:0xe2b65f,emissive:0x4c2900}));
  pillar.position.y=1.2;group.add(pillar);
  const beacon=new THREE.PointLight(0xffb84d,4,7);beacon.position.y=1.8;group.add(beacon);
  scene.add(group);return {group,ring,pillar,beacon,position:p,done:false};
 });
 window.addEventListener("resize",resize);
 requestAnimationFrame(frame);
}
function addBox(x,y,z,sx,sy,sz,color){
 const m=new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),new THREE.MeshStandardMaterial({color,roughness:.92}));
 m.position.set(x,y,z);scene.add(m);return m;
}
function resize(){if(!renderer||!camera)return;camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);}
function updatePeers(list){
 const alive=new Set();
 for(const p of list){
  if(p.id===playerId)continue;
  alive.add(p.id);let obj=peers.get(p.id);
  if(!obj){obj=new THREE.Mesh(new THREE.CapsuleGeometry(.35,.9,4,8),new THREE.MeshStandardMaterial({color:palette[peers.size%palette.length]}));scene?.add(obj);peers.set(p.id,obj);}
  obj.position.set(Number(p.x)||0,.8,Number(p.z)||0);obj.rotation.y=Number(p.yaw)||0;
 }
 for(const [id,obj] of peers){if(!alive.has(id)){scene?.remove(obj);obj.geometry.dispose();obj.material.dispose();peers.delete(id);}}
 $("players").textContent="接続プレイヤー: "+(list.length||1);
}
function updateMissionHud(){
 $("missionHud").textContent=missionEnded?(objectiveIndex===3?"任務達成":"任務終了"):"目標 "+Math.min(objectiveIndex+1,3)+"/3";
}
function finishMission(won){
 missionEnded=true;
 $("objectiveBanner").textContent=won?"MISSION COMPLETE — 全目標を確保した！":"TIME EXPIRED — メニューから再挑戦できる";
 updateMissionHud();
}
function frame(now){
 if(!joined||!renderer||!scene)return;
 const dt=Math.min((now-last)/1000,.05);last=now;
 if(!missionEnded&&!onlineMode){
  timeLeft-=dt;
  if(timeLeft<=0){timeLeft=0;finishMission(false);}
  const mins=Math.floor(timeLeft/60),secs=Math.floor(timeLeft%60);
  $("timer").textContent=String(mins).padStart(2,"0")+":"+String(secs).padStart(2,"0");
 }
 const forward=Number(move.forward)-Number(move.back), side=Number(move.right)-Number(move.left);
 const len=Math.hypot(forward,side)||1;
 const speed=(move.forward||move.back||move.left||move.right)?(window.shiftPressed?7:4.2):0;
 const dx=(Math.sin(yaw)*forward+Math.cos(yaw)*side)/len*speed*dt;
 const dz=(-Math.cos(yaw)*forward+Math.sin(yaw)*side)/len*speed*dt;
 if(!missionEnded){
  camera.position.x=Math.max(-19,Math.min(19,camera.position.x+dx));
  camera.position.z=Math.max(-19,Math.min(19,camera.position.z+dz));
 }
 camera.position.y=1.65;
 camera.rotation.order="YXZ";camera.rotation.y=yaw;camera.rotation.x=pitch;
 me.position.set(camera.position.x,.8,camera.position.z);me.rotation.y=yaw;
 for(let i=0;i<objectives.length;i++){
  const o=objectives[i];
  if(!o.done){o.group.rotation.y=now*.00035;o.beacon.intensity=i===objectiveIndex?4.5:1.1;}
 }
 if(!missionEnded&&!onlineMode&&objectiveIndex<objectives.length){
  const target=objectives[objectiveIndex].position;
  if(Math.hypot(camera.position.x-target.x,camera.position.z-target.z)<2.1){
   const o=objectives[objectiveIndex];o.done=true;
   o.ring.material.color.setHex(0x6be0a0);o.ring.material.emissive.setHex(0x164b2a);
   o.pillar.material.color.setHex(0x6be0a0);o.beacon.color.setHex(0x6be0a0);
   objectiveIndex++;updateMissionHud();
   if(objectiveIndex===3)finishMission(true);
   else $("objectiveBanner").textContent="目標確保！ 次の地点へ移動せよ";
  }
 }
 if(onlineMode&&socket?.readyState===WebSocket.OPEN){
  socket.send(JSON.stringify({type:"move",id:playerId,x:camera.position.x,z:camera.position.z,yaw}));
 }
 renderer.render(scene,camera);
 requestAnimationFrame(frame);
}
function leaveGame(){
 joined=false;onlineMode=false;
 if(socket){const old=socket;socket=null;old.close();}
 if(renderer){renderer.dispose();renderer=null;}
 if(scene){scene.traverse(o=>{if(o.geometry)o.geometry.dispose();if(o.material){if(Array.isArray(o.material))o.material.forEach(m=>m.dispose());else o.material.dispose();}});}
 scene=null;camera=null;me=null;peers.clear();objectives=[];
 game.classList.add("hidden");lobby.classList.remove("hidden");
 $("onlinePanel").classList.add("hidden");
 statusEl.textContent="メニューに戻りました。";
}
window.shiftPressed=false;
window.addEventListener("keydown",e=>{if(e.key==="Shift")window.shiftPressed=true;});
window.addEventListener("keyup",e=>{if(e.key==="Shift")window.shiftPressed=false;});
