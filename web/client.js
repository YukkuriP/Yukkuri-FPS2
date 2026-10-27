import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

const $ = id => document.getElementById(id);
const intro = $("intro"), lobby = $("lobby"), game = $("game"), statusEl = $("status");
let socket = null, renderer, scene, camera, me, yaw = 0, pitch = 0, last = performance.now();
let peers = new Map(), move = {forward:false,back:false,left:false,right:false};
const characterLoader = new GLTFLoader();
const characterModelUrl = "./assets/characters/operator.glb";
const characterMixers = new Set();
let trainingBots = [];
let viewArms = null, cameraBob = 0;
let touchLook = false, lastTouch = null, joined = false, onlineMode = false;
let objectives = [], objectiveIndex = 0, timeLeft = 180, missionEnded = false;
let ammo = 30, reserveAmmo = 120, reloading = false, reloadUntil = 0, hitMarkerUntil = 0, fireCooldown = 0;
const raycaster = new THREE.Raycaster();
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
$("reloadBtn")?.addEventListener("click", reloadWeapon);
$("fireBtn")?.addEventListener("pointerdown", e=>{e.preventDefault();fireWeapon();});
document.addEventListener("mousedown", e=>{if(e.button===0 && joined && !matchMedia("(pointer:coarse)").matches) fireWeapon();});
window.addEventListener("keydown", e=>{if(e.key.toLowerCase()==="r")reloadWeapon();});
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
$("view").addEventListener("contextmenu",e=>e.preventDefault());
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
 ammo=30;reserveAmmo=120;reloading=false;reloadUntil=0;hitMarkerUntil=0;fireCooldown=0;
 lobby.classList.add("hidden");game.classList.remove("hidden");
 initScene();
 updateMissionHud();
 $("objectiveBanner").textContent="作戦開始 — 3か所の目標地点を確保せよ";
}
function initScene(){
 if(renderer){renderer.dispose();renderer=null;}
 viewArms=null;cameraBob=0;
 scene=new THREE.Scene();
 scene.background=new THREE.Color(0x748795);
 scene.fog=new THREE.Fog(0x748795,25,75);
 camera=new THREE.PerspectiveCamera(76,innerWidth/innerHeight,.1,120);
 camera.position.set(0,1.65,15);
 scene.add(camera);
 renderer=new THREE.WebGLRenderer({canvas:$("view"),antialias:true,powerPreference:"high-performance"});
 renderer.shadowMap.enabled=true;
 renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));
 renderer.setSize(innerWidth,innerHeight);
 renderer.outputColorSpace=THREE.SRGBColorSpace;
 renderer.toneMapping=THREE.ACESFilmicToneMapping;
 renderer.toneMappingExposure=1.08;
 scene.add(new THREE.HemisphereLight(0xd9e8f4,0x28333b,1.65));
 createFirstPersonArms();
 const sun=new THREE.DirectionalLight(0xffe7c4,2.6);sun.position.set(-12,18,8);sun.castShadow=true;
 sun.shadow.mapSize.set(1024,1024);sun.shadow.camera.left=-24;sun.shadow.camera.right=24;
 sun.shadow.camera.top=24;sun.shadow.camera.bottom=-24;sun.shadow.bias=-0.00025;scene.add(sun);
 const mat=(color,roughness=.88)=>new THREE.MeshStandardMaterial({color,roughness,metalness:.08});
 const groundTexture=createGroundTexture();
 groundTexture.wrapS=groundTexture.wrapT=THREE.RepeatWrapping;groundTexture.repeat.set(18,18);
 const groundMat=new THREE.MeshStandardMaterial({color:0x66727a,map:groundTexture,roughness:1});
 const floor=new THREE.Mesh(new THREE.BoxGeometry(42,1,42),groundMat);floor.position.y=-.5;floor.receiveShadow=true;scene.add(floor);
 addEnvironmentDetails();
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
 spawnTrainingBots();
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
function createFirstPersonArms(){
 if(!camera)return;
 const root=new THREE.Group();root.name="FirstPersonArms";
 root.position.set(.29,-.34,-.42);camera.add(root);
 const sleeve=new THREE.MeshStandardMaterial({color:0x394951,roughness:.94});
 const glove=new THREE.MeshStandardMaterial({color:0x20282d,roughness:.88});
 const seam=new THREE.MeshStandardMaterial({color:0x657780,roughness:.86});
 const weapon=new THREE.MeshStandardMaterial({color:0x20282b,roughness:.42,metalness:.68});
 const weaponDetail=new THREE.MeshStandardMaterial({color:0x59656a,roughness:.5,metalness:.55});
 const add=(geo,mat,pos,rot)=>{const m=new THREE.Mesh(geo,mat);m.position.set(...pos);if(rot)m.rotation.set(...rot);root.add(m);return m;};
 add(new THREE.CapsuleGeometry(.105,.39,4,8),sleeve,[.11,-.11,.02],[.12,0,-.34]);
 add(new THREE.CapsuleGeometry(.09,.31,4,8),sleeve,[-.17,-.15,.12],[.2,0,.42]);
 add(new THREE.SphereGeometry(.105,12,10),glove,[.18,-.29,-.06]);
 add(new THREE.SphereGeometry(.095,12,10),glove,[-.24,-.29,.04]);
 add(new THREE.BoxGeometry(.12,.025,.15),seam,[.11,-.19,.02],[.12,0,-.34]);
 add(new THREE.BoxGeometry(.12,.025,.15),seam,[-.17,-.22,.12],[.2,0,.42]);
 // Lightweight first-person carbine silhouette; procedural, no external asset required.
 add(new THREE.BoxGeometry(.16,.14,.62),weapon,[.015,-.23,-.35],[.02,0,0]);
 add(new THREE.CylinderGeometry(.025,.025,.42,10),weaponDetail,[.015,-.205,-.83],[Math.PI/2,0,0]);
 add(new THREE.BoxGeometry(.09,.18,.12),weapon,[-.005,-.36,-.24],[.12,0,0]);
 add(new THREE.BoxGeometry(.075,.07,.16),weaponDetail,[.015,-.145,-.34],[0,0,0]);
 viewArms=root;
}
function addBox(x,y,z,sx,sy,sz,color){
 const m=new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),new THREE.MeshStandardMaterial({color,roughness:.92}));
 m.position.set(x,y,z);scene.add(m);return m;
}
function resize(){if(!renderer||!camera)return;camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);}
function createSoldier(color){
 const root=new THREE.Group();
 const cloth=new THREE.MeshStandardMaterial({color,roughness:.92});
 const dark=new THREE.MeshStandardMaterial({color:0x26323a,roughness:.95});
 const gear=new THREE.MeshStandardMaterial({color:0x46545b,roughness:.9});
 const skin=new THREE.MeshStandardMaterial({color:0xb88e70,roughness:.9});
 const part=(geometry,material,parent,position)=>{
  const mesh=new THREE.Mesh(geometry,material);mesh.position.copy(position);mesh.castShadow=true;mesh.receiveShadow=true;parent.add(mesh);return mesh;
 };
 // Ground-level root; pivoted limbs make the stride read clearly from other players' view.
 part(new THREE.CapsuleGeometry(.24,.48,4,8),cloth,root,new THREE.Vector3(0,1.12,0));
 part(new THREE.BoxGeometry(.42,.42,.24),gear,root,new THREE.Vector3(0,1.18,.17)); // plate carrier
 part(new THREE.SphereGeometry(.145,12,10),gear,root,new THREE.Vector3(0,1.57,0));
 part(new THREE.SphereGeometry(.115,12,10),skin,root,new THREE.Vector3(0,1.78,0));
 part(new THREE.BoxGeometry(.27,.13,.27),dark,root,new THREE.Vector3(0,1.88,0)); // helmet
 const makeLimb=(x,y,length,width,material)=>{
  const pivot=new THREE.Group();pivot.position.set(x,y,0);root.add(pivot);
  part(new THREE.CapsuleGeometry(width*.5,length-width,4,6),material,pivot,new THREE.Vector3(0,-length*.42,0));
  return pivot;
 };
 const leftArm=makeLimb(-.29,1.36,.48,.14,cloth);
 const rightArm=makeLimb(.29,1.36,.48,.14,cloth);
 const leftLeg=makeLimb(-.14,.91,.55,.17,cloth);
 const rightLeg=makeLimb(.14,.91,.55,.17,cloth);
 for(const [x,leg] of [[-.14,leftLeg],[.14,rightLeg]]){
  part(new THREE.BoxGeometry(.19,.12,.31),dark,leg,new THREE.Vector3(0,-.48,-.055));
 }
 const soldier={root,leftArm,rightArm,leftLeg,rightLeg,target:new THREE.Vector3(),targetYaw:0,lastX:0,lastZ:0,speed:0,phase:0,cloth,dark,gear,skin,mixer:null,modelLoaded:false};
 loadExternalCharacter(soldier);
 return soldier;
}
function loadExternalCharacter(soldier){
 // If a licensed GLB is added at this path, it replaces the procedural fallback automatically.
 characterLoader.load(characterModelUrl,gltf=>{
  if(!scene||!soldier.root.parent)return;
  const model=gltf.scene;
  const bounds=new THREE.Box3().setFromObject(model);
  const size=bounds.getSize(new THREE.Vector3());
  const height=Math.max(size.y,.001);
  model.scale.setScalar(1.82/height);
  const center=bounds.getCenter(new THREE.Vector3());
  model.position.set(-center.x*model.scale.x,-bounds.min.y*model.scale.y,-center.z*model.scale.z);
  model.traverse(node=>{if(node.isMesh){node.castShadow=true;node.receiveShadow=true;node.frustumCulled=true;}});
  for(const child of [...soldier.root.children]){
   soldier.root.remove(child);
   child.traverse?.(node=>{if(node.geometry)node.geometry.dispose();});
  }
  soldier.root.add(model);
  if(gltf.animations?.length){
   soldier.mixer=new THREE.AnimationMixer(model);
   const clips=gltf.animations;
   const preferred=clips.find(a=>/idle|stand/i.test(a.name))||clips[0];
   soldier.mixer.clipAction(preferred).play();
   soldier.animationClips=clips;
   characterMixers.add(soldier);
  }
  soldier.modelLoaded=true;
 },undefined,()=>{/* Keep the procedural character if no local model is installed. */});
}
function createGroundTexture(){
 const canvas=document.createElement("canvas");canvas.width=canvas.height=256;
 const ctx=canvas.getContext("2d");ctx.fillStyle="#66727a";ctx.fillRect(0,0,256,256);
 let seed=127;const rand=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
 for(let i=0;i<1400;i++){const v=Math.floor(75+rand()*70);ctx.fillStyle="rgba("+v+","+v+","+v+","+(0.08+rand()*.12)+")";ctx.fillRect(rand()*256,rand()*256,1+rand()*3,1+rand()*2);}
 ctx.strokeStyle="rgba(205,218,224,.12)";ctx.lineWidth=1;
 for(let i=0;i<=256;i+=32){ctx.beginPath();ctx.moveTo(i,0);ctx.lineTo(i,256);ctx.stroke();ctx.beginPath();ctx.moveTo(0,i);ctx.lineTo(256,i);ctx.stroke();}
 const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;return texture;
}
function addEnvironmentDetails(){
 const stripeMat=new THREE.MeshStandardMaterial({color:0x9aa8ad,roughness:.8,metalness:.1});
 for(let z=-10;z<=10;z+=4){
  const stripe=new THREE.Mesh(new THREE.BoxGeometry(28,.025,.06),stripeMat);stripe.position.set(0,.025,z);stripe.receiveShadow=true;scene.add(stripe);
 }
 // Low skyline silhouettes make the training yard feel larger without expensive geometry.
 for(let i=0;i<16;i++){
  const x=-23+i*3.05;const h=3+(i*7%6);
  const block=new THREE.Mesh(new THREE.BoxGeometry(2.4,h,1.8),new THREE.MeshStandardMaterial({color:i%2?0x303e49:0x3a4852,roughness:1}));
  block.position.set(x,h/2-0.02,-22);scene.add(block);
  for(let y=1;y<h-0.4;y+=1.15){
   const windowMat=new THREE.MeshBasicMaterial({color:(i+y)%3===0?0xc9a46a:0x536b78});
   const win=new THREE.Mesh(new THREE.PlaneGeometry(.22,.3),windowMat);win.position.set(x-.35,y,-21.08);scene.add(win);
  }
 }
}
function spawnTrainingBots(){
 trainingBots=[];
 const spots=[new THREE.Vector3(-7,0,-2),new THREE.Vector3(7,0,-7),new THREE.Vector3(5,0,9)];
 for(let i=0;i<spots.length;i++){
  const root=new THREE.Group();root.position.copy(spots[i]);
  const shell=new THREE.MeshStandardMaterial({color:[0x75b9ca,0x90a8b8,0x9db8a4][i],roughness:.5,metalness:.35});
  const dark=new THREE.MeshStandardMaterial({color:0x263741,roughness:.65,metalness:.2});
  const body=new THREE.Mesh(new THREE.SphereGeometry(.38,16,12),shell);body.scale.set(1.25,.72,1);body.position.y=1.15;body.castShadow=true;root.add(body);
  const eye=new THREE.Mesh(new THREE.SphereGeometry(.09,12,8),new THREE.MeshBasicMaterial({color:0x8eeaff}));eye.position.set(0,1.18,-.36);root.add(eye);
  for(const side of [-1,1]){
   const pod=new THREE.Mesh(new THREE.CylinderGeometry(.07,.11,.48,8),dark);pod.position.set(side*.42,.92,0);pod.rotation.z=side*.2;root.add(pod);
   const light=new THREE.PointLight(0x66d9ff,.6,2);light.position.set(side*.42,1.0,-.15);root.add(light);
  }
  const ring=new THREE.Mesh(new THREE.TorusGeometry(.48,.025,6,24),new THREE.MeshBasicMaterial({color:0x67cce5,transparent:true,opacity:.8}));ring.rotation.x=Math.PI/2;ring.position.y=.65;root.add(ring);
  scene.add(root);
  trainingBots.push({root,home:spots[i].clone(),phase:i*2.1,state:"patrol",lastSeen:null,speed:1.1+i*.15,health:100,maxHealth:100,alive:true});
 }
}
function reloadWeapon(){
 if(!joined||reloading||ammo===30||reserveAmmo<=0)return;
 reloading=true;reloadUntil=performance.now()+1450;
 $("objectiveBanner").textContent="RELOADING — マガジン交換中";
}
function fireWeapon(){
 if(!joined||missionEnded||reloading||fireCooldown>0)return;
 if(ammo<=0){reloadWeapon();return;}
 ammo--;fireCooldown=.105;
 const now=performance.now();
 // Short synthetic shot sound avoids requiring external audio files.
 try{const C=window.AudioContext||window.webkitAudioContext;if(C){const ctx=fireWeapon.ctx||(fireWeapon.ctx=new C());if(ctx.state==="suspended")ctx.resume();const osc=ctx.createOscillator(),gain=ctx.createGain();osc.type="sawtooth";osc.frequency.setValueAtTime(105,ctx.currentTime);osc.frequency.exponentialRampToValueAtTime(42,ctx.currentTime+.075);gain.gain.setValueAtTime(.055,ctx.currentTime);gain.gain.exponentialRampToValueAtTime(.001,ctx.currentTime+.09);osc.connect(gain);gain.connect(ctx.destination);osc.start();osc.stop(ctx.currentTime+.095);}}catch{}
 if(camera&&scene){
  raycaster.setFromCamera(new THREE.Vector2(0,0),camera);
  const targets=trainingBots.filter(b=>b.alive).flatMap(b=>b.root.children);
  const hit=raycaster.intersectObjects(targets,true)[0];
  if(hit){let node=hit.object;while(node&&node.parent!==scene)node=node.parent;const bot=trainingBots.find(b=>b.alive&&b.root===node);
   if(bot){bot.health-=34;hitMarkerUntil=now+180;
    if(bot.health<=0){bot.alive=false;scene.remove(bot.root);$("objectiveBanner").textContent="TARGET NEUTRALIZED — 敵訓練ドローンを撃破";}
    else $("objectiveBanner").textContent="HIT CONFIRMED — 残り耐久 "+Math.max(0,bot.health)+"%";
   }
  }
 }
 updateCombatHud();
}
function updateCombatHud(){
 const ammoEl=$("ammoHud");if(ammoEl)ammoEl.textContent=(reloading?"RELOAD… ":"")+String(ammo).padStart(2,"0")+" / "+String(reserveAmmo).padStart(3,"0");
 const cross=$("crosshair");if(cross){cross.textContent=performance.now()<hitMarkerUntil?"×":"+";cross.style.color=performance.now()<hitMarkerUntil?"#ffcf83":"#ffffff";}
}
function updateTrainingBots(dt,now){
 for(const bot of trainingBots){
  const p=bot.root.position,player=new THREE.Vector3(camera.position.x,0,camera.position.z);
  const distance=p.distanceTo(player);
  if(distance<7) {bot.state="observe";bot.lastSeen=player.clone();}
  else if(bot.state==="observe"&&bot.lastSeen&&p.distanceTo(bot.lastSeen)>1.2)bot.state="return";
  let target;
  if(bot.state==="observe")target=bot.lastSeen;
  else if(bot.state==="return")target=bot.home;
  else target=new THREE.Vector3(bot.home.x+Math.sin(now*.00045+bot.phase)*2,0,bot.home.z+Math.cos(now*.0004+bot.phase)*2);
  const delta=target.clone().sub(p);delta.y=0;
  if(delta.length()>.15){
   const step=Math.min(delta.length(),bot.speed*dt);delta.normalize().multiplyScalar(step);p.add(delta);
   bot.root.rotation.y=Math.atan2(delta.x,delta.z);
  }else if(bot.state==="return")bot.state="patrol";
  bot.root.position.y=0.08+Math.sin(now*.002+bot.phase)*.12;
  bot.root.children[0].rotation.z=Math.sin(now*.003+bot.phase)*.06;
 }
}
function animateSoldier(s,dt,now){
 // GLB characters use their authored animation clips; only procedural characters need pivoted limbs.
 if(s.modelLoaded){s.root.rotation.y=THREE.MathUtils.dampAngle(s.root.rotation.y,s.targetYaw,12,dt);return;}
 const dx=s.root.position.x-s.lastX,dz=s.root.position.z-s.lastZ;
 const measured=dt>0?Math.hypot(dx,dz)/dt:0;
 s.speed=THREE.MathUtils.damp(s.speed,Math.min(measured,8),12,dt);
 s.lastX=s.root.position.x;s.lastZ=s.root.position.z;
 s.phase+=dt*(s.speed>.15?Math.min(13,s.speed*2.5):1.3);
 const stride=Math.min(1,s.speed/4.2);
 const swing=Math.sin(s.phase)*.62*stride;
 s.leftLeg.rotation.x=swing;s.rightLeg.rotation.x=-swing;
 s.leftArm.rotation.x=-swing*.7-.18;s.rightArm.rotation.x=swing*.7-.55;
 // Small torso motion, reduced while nearly stationary to avoid idle jitter.
 s.root.position.y=.018*Math.sin(now*.004)*(s.speed>.15?1:.25);
 s.root.rotation.y=THREE.MathUtils.dampAngle(s.root.rotation.y,s.targetYaw,12,dt);
}
function updatePeers(list){
 const alive=new Set();
 for(const p of list){
  if(p.id===playerId)continue;
  alive.add(p.id);let obj=peers.get(p.id);
  if(!obj){obj=createSoldier(palette[peers.size%palette.length]);obj.root.position.set(Number(p.x)||0,0,Number(p.z)||0);obj.lastX=obj.root.position.x;obj.lastZ=obj.root.position.z;scene?.add(obj.root);peers.set(p.id,obj);}
  obj.target.set(Number(p.x)||0,0,Number(p.z)||0);
  obj.targetYaw=Number(p.yaw)||0;
 }
 for(const [id,obj] of peers){if(!alive.has(id)){scene?.remove(obj.root);if(obj.mixer)characterMixers.delete(obj);peers.delete(id);}}
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
 fireCooldown=Math.max(0,fireCooldown-dt);
 if(reloading&&now>=reloadUntil){const needed=30-ammo,take=Math.min(needed,reserveAmmo);ammo+=take;reserveAmmo-=take;reloading=false;$("objectiveBanner").textContent="MAGAZINE READY — 戦闘を継続せよ";}
 updateCombatHud();
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
 if(viewArms){cameraBob=THREE.MathUtils.damp(cameraBob,speed>0?.018:0,10,dt);viewArms.position.y=-.34+Math.abs(Math.sin(now*.009))*cameraBob;viewArms.position.x=.29+Math.sin(now*.006)*cameraBob*.6;viewArms.rotation.z=Math.sin(now*.006)*cameraBob*1.6;}
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
 updateTrainingBots(dt,now);
 for(const soldier of characterMixers)soldier.mixer?.update(dt);
 // Smooth remote-player motion between network snapshots instead of teleporting each update.
 for(const obj of peers.values()){
  obj.root.position.x=THREE.MathUtils.damp(obj.root.position.x,obj.target.x,14,dt);
  obj.root.position.z=THREE.MathUtils.damp(obj.root.position.z,obj.target.z,14,dt);
  animateSoldier(obj,dt,now);
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
 scene=null;camera=null;me=null;peers.clear();objectives=[];trainingBots=[];characterMixers.clear();reloading=false;
 game.classList.add("hidden");lobby.classList.remove("hidden");
 $("onlinePanel").classList.add("hidden");
 statusEl.textContent="メニューに戻りました。";
}
window.shiftPressed=false;
window.addEventListener("keydown",e=>{if(e.key==="Shift")window.shiftPressed=true;});
window.addEventListener("keyup",e=>{if(e.key==="Shift")window.shiftPressed=false;});
