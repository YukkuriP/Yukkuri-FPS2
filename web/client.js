import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

const $ = id => document.getElementById(id);
const intro = $("intro"), lobby = $("lobby"), game = $("game"), statusEl = $("status");
let socket = null, renderer, scene, camera, me, yaw = 0, pitch = 0, last = performance.now();
let peers = new Map(), move = {forward:false,back:false,left:false,right:false};
let viewModel = null, bobPhase = 0, previousCameraPosition = new THREE.Vector3();
const characterLoader = new GLTFLoader();
const characterModelUrl = "./assets/characters/operator.glb";
const characterMixers = new Set();
let trainingBots = [];
let joined = false, onlineMode = false, lastNetSend = 0, connectionTimer = null, lastServerError = "";
const collisionBoxes = [];
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
 b.addEventListener("pointerdown",e=>{e.preventDefault();b.setPointerCapture?.(e.pointerId);move[key]=true;});
 const release=()=>{move[key]=false;};
 for(const ev of ["pointerup","pointercancel","lostpointercapture"])b.addEventListener(ev,release);
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
const lookpad=document.querySelector(".lookpad");
let lookPointerId=null,lastLookPoint=null;
lookpad?.addEventListener("pointerdown",e=>{
 e.preventDefault();lookPointerId=e.pointerId;lastLookPoint={x:e.clientX,y:e.clientY};lookpad.setPointerCapture?.(e.pointerId);
});
lookpad?.addEventListener("pointermove",e=>{
 if(lookPointerId!==e.pointerId||!lastLookPoint)return;
 e.preventDefault();yaw-=(e.clientX-lastLookPoint.x)*.008;
 pitch=Math.max(-1.2,Math.min(1.2,pitch-(e.clientY-lastLookPoint.y)*.008));
 lastLookPoint={x:e.clientX,y:e.clientY};
});
const endLook=e=>{if(lookPointerId===e.pointerId){lookPointerId=null;lastLookPoint=null;}};
for(const ev of ["pointerup","pointercancel","lostpointercapture"])lookpad?.addEventListener(ev,endLook);

function startOffline(){
 if(connectionTimer){clearTimeout(connectionTimer);connectionTimer=null;}
 if(socket){const old=socket;socket=null;old.close();}
 onlineMode=false;
 $("roomLabel").textContent="TRAINING";
 $("players").textContent="オフライン訓練";
 beginGame();
}
function connectOnline(){
 const url=$("serverUrl").value.trim(), name=$("playerName").value.trim()||"Operator", room=$("roomCode").value.trim().toUpperCase()||"IRON-01";
 if(!url.startsWith("wss://")){statusEl.textContent="wss:// で始まる安全なサーバーURLを入力してください。";return;}
 if(connectionTimer){clearTimeout(connectionTimer);connectionTimer=null;}
 lastServerError="";statusEl.textContent="サーバーへ接続中…";
 $("joinBtn").disabled=true;
 try{socket=new WebSocket(url)}catch(e){statusEl.textContent="URLを確認してください: "+e.message;$("joinBtn").disabled=false;return;}
 const current=socket;
 current.onopen=()=>{
  if(connectionTimer){clearTimeout(connectionTimer);connectionTimer=null;}
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
  if(data.type==="error"){lastServerError=data.message||"サーバーが接続を拒否しました。";statusEl.textContent=lastServerError;current.close();}
 };
 current.onerror=()=>{
  if(socket!==current)return;
  statusEl.textContent="接続できません。サーバー状態・URL・ネットワークの許可設定を確認してください。オフラインモードは引き続き利用できます。";
  $("joinBtn").disabled=false;
 };
 current.onclose=()=>{
  if(connectionTimer){clearTimeout(connectionTimer);connectionTimer=null;}
  $("joinBtn").disabled=false;
  if(socket===current)socket=null;
  if(joined&&onlineMode){
   joined=false;onlineMode=false;
   disposeScene();
   game.classList.add("hidden");lobby.classList.remove("hidden");
   $("onlinePanel").classList.remove("hidden");
   statusEl.textContent=lastServerError||"サーバーから切断されました。オフラインモードは引き続き利用できます。";
  }
 };
 connectionTimer=setTimeout(()=>{
  if(socket===current&&current.readyState===WebSocket.CONNECTING){
   lastServerError="接続がタイムアウトしました。サーバーURLと接続状態を確認してください。";
   statusEl.textContent=lastServerError;current.close();
  }
 },12000);
}
function beginGame(){
 disposeScene();
 joined=true;missionEnded=false;objectiveIndex=0;timeLeft=180;yaw=0;pitch=0;last=performance.now();lastNetSend=0;
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
 renderer=new THREE.WebGLRenderer({canvas:$("view"),antialias:true,powerPreference:"high-performance"});
 renderer.shadowMap.enabled=true;
 renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));
 renderer.setSize(innerWidth,innerHeight);
 renderer.outputColorSpace=THREE.SRGBColorSpace;
 scene.add(new THREE.HemisphereLight(0xd9e8f4,0x28333b,1.65));
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
 me=null;
 viewModel=createFirstPersonViewModel();
 camera.add(viewModel);
 previousCameraPosition.copy(camera.position);
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
 requestAnimationFrame(frame);
}
function addBox(x,y,z,sx,sy,sz,color){
 const m=new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),new THREE.MeshStandardMaterial({color,roughness:.92}));
 m.position.set(x,y,z);scene.add(m);
 if(y+sy*.5>.25&&y-sy*.5<1.85)collisionBoxes.push({minX:x-sx*.5,maxX:x+sx*.5,minZ:z-sz*.5,maxZ:z+sz*.5});
 return m;
}
function collidesAt(x,z){
 const radius=.38;
 return collisionBoxes.some(b=>x+radius>b.minX&&x-radius<b.maxX&&z+radius>b.minZ&&z-radius<b.maxZ);
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
 // Layered field equipment: helmet rim, eye protection, face covering and plate-carrier webbing.
 const webbing=new THREE.MeshStandardMaterial({color:0x59604c,roughness:.96});
 const lens=new THREE.MeshStandardMaterial({color:0x263b40,roughness:.24,metalness:.18});
 part(new THREE.BoxGeometry(.31,.035,.30),dark,root,new THREE.Vector3(0,1.84,-.015));
 part(new THREE.BoxGeometry(.22,.055,.045),lens,root,new THREE.Vector3(0,1.79,-.115));
 part(new THREE.BoxGeometry(.19,.075,.08),dark,root,new THREE.Vector3(0,1.69,-.105));
 part(new THREE.BoxGeometry(.09,.23,.055),webbing,root,new THREE.Vector3(-.12,1.34,-.145));
 part(new THREE.BoxGeometry(.09,.23,.055),webbing,root,new THREE.Vector3(.12,1.34,-.145));
 part(new THREE.BoxGeometry(.46,.07,.27),dark,root,new THREE.Vector3(0,.91,.02)); // waist belt
 for(let i=0;i<4;i++){
  const x=-.18+i*.12;
  part(new THREE.BoxGeometry(.095,.12,.075),webbing,root,new THREE.Vector3(x,1.02,-.17));
  part(new THREE.BoxGeometry(.075,.018,.012),dark,root,new THREE.Vector3(x,1.06,-.211));
 }
 part(new THREE.BoxGeometry(.28,.37,.16),dark,root,new THREE.Vector3(0,1.25,.19)); // compact pack
 part(new THREE.BoxGeometry(.34,.13,.08),webbing,root,new THREE.Vector3(0,1.48,.17));
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
  part(new THREE.BoxGeometry(.19,.16,.07),webbing,leg,new THREE.Vector3(0,-.27,-.085)); // knee pad
  part(new THREE.BoxGeometry(.205,.11,.34),dark,leg,new THREE.Vector3(0,-.52,-.11)); // boot
  part(new THREE.BoxGeometry(.18,.035,.25),webbing,leg,new THREE.Vector3(0,-.43,-.12)); // boot cuff
 }
 for(const arm of [leftArm,rightArm]){
  part(new THREE.BoxGeometry(.14,.11,.12),dark,arm,new THREE.Vector3(0,-.39,-.02)); // glove
  part(new THREE.BoxGeometry(.17,.10,.13),webbing,arm,new THREE.Vector3(0,-.12,-.015)); // shoulder pad
 }
 // A simple low-poly rifle silhouette held across the chest.
 const rifle=new THREE.Group();root.add(rifle);
 part(new THREE.BoxGeometry(.12,.12,.72),dark,rifle,new THREE.Vector3(.12,1.27,-.22));
 part(new THREE.BoxGeometry(.14,.16,.22),dark,rifle,new THREE.Vector3(.12,1.20,-.04)); // magazine silhouette
 part(new THREE.BoxGeometry(.08,.035,.16),gear,rifle,new THREE.Vector3(.12,1.36,-.25)); // top rail
 part(new THREE.BoxGeometry(.09,.055,.11),dark,rifle,new THREE.Vector3(.12,1.40,-.24)); // optic housing
 part(new THREE.CylinderGeometry(.018,.018,.48,6),gear,rifle,new THREE.Vector3(.12,1.3,-.69)).rotation.x=Math.PI/2;
 rifle.rotation.x=-.08;
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

function createFirstPersonViewModel(){
 const root=new THREE.Group();
 root.position.set(.34,-.31,-.58);
 const mat=(color,roughness=.82,metalness=.08)=>new THREE.MeshStandardMaterial({color,roughness,metalness});
 const cloth=mat(0x414b43,.96), clothEdge=mat(0x596254,.94), glove=mat(0x252c2a,.92), glovePad=mat(0x424b45,.9);
 const polymer=mat(0x202729,.72), metal=mat(0x3a4243,.48,.42), dark=mat(0x111719,.56,.38), rail=mat(0x596164,.62,.35);
 const add=(geo,material,pos,rot,parent=root)=>{const m=new THREE.Mesh(geo,material);m.position.set(...pos);if(rot)m.rotation.set(...rot);m.castShadow=true;m.receiveShadow=true;parent.add(m);return m;};
 const box=(pos,size,material,rot=[0,0,0])=>add(new THREE.BoxGeometry(...size),material,pos,rot);
 const cyl=(pos,r,h,material,rot=[Math.PI/2,0,0])=>add(new THREE.CylinderGeometry(r,r,h,12),material,pos,rot);
 // Sleeves, articulated-looking cuffs, gloves and individual fingers.
 const arm=(side)=>{
  const g=new THREE.Group();g.position.set(side<0?-.27:.28,side<0?-.12:-.17,side<0?-.23:.08);g.rotation.z=side<0?-.38:.22;root.add(g);
  add(new THREE.CapsuleGeometry(.082,.43,5,9),cloth,[0,0,.02],[.86,0,side<0?-.12:.08],g);
  add(new THREE.CylinderGeometry(.087,.083,.075,10),clothEdge,[0,-.01,-.20],[Math.PI/2,0,0],g);
  add(new THREE.BoxGeometry(.16,.105,.13),glove,[0,-.04,-.28],[.1,0,0],g);
  for(let i=0;i<4;i++)add(new THREE.CapsuleGeometry(.018,.075,3,6),glove,[((i-1.5)*.032),-.085,-.33],[.25,0,0],g);
  add(new THREE.CapsuleGeometry(.018,.06,3,6),glove,[side<0?.085:-.085,-.015,-.31],[0,0,side<0?-.55:.55],g);
  add(new THREE.BoxGeometry(.105,.018,.075),glovePad,[0,.016,-.28],null,g);
 };
 arm(-1);arm(1);
 // Compact modern carbine silhouette with receiver, handguard, rail, barrel, optic, grip and magazine.
 box([.13,-.015,-.29],[.16,.13,.39],polymer);
 box([.13,.055,-.32],[.13,.035,.42],dark);
 box([.13,-.075,-.24],[.13,.09,.23],polymer);
 box([.13,-.005,-.59],[.13,.105,.34],polymer);
 box([.045,-.005,-.59],[.018,.055,.30],rail);box([.215,-.005,-.59],[.018,.055,.30],rail);
 for(let i=0;i<6;i++){const z=-.46-i*.045;box([.028,-.005,z],[.012,.018,.024],dark);box([.232,-.005,z],[.012,.018,.024],dark);}
 cyl([.13,.002,-.86],.022,.42,dark);
 cyl([.13,.002,-1.08],.031,.09,metal);
 cyl([.13,.002,-1.135],.025,.025,dark);
 box([.13,.115,-.34],[.085,.025,.14],dark);
 cyl([.13,.16,-.34],.039,.13,dark);
 cyl([.13,.16,-.415],.027,.008,mat(0x49676b,.24,.25));
 box([.13,-.17,-.18],[.095,.20,.11],polymer,[-.22,0,0]);
 box([.13,-.28,-.20],[.10,.12,.12],dark,[-.12,0,0]);
 box([.13,-.005,-.015],[.13,.095,.24],polymer);
 box([.13,-.005,.105],[.14,.12,.035],glove);
 // Subtle handguard fasteners and sling mount.
 for(const side of [-1,1])for(let i=0;i<4;i++)cyl([.13+side*.071,-.005,-.48-i*.07],.008,.012,metal,[0,0,Math.PI/2]);
 root.userData.basePosition=root.position.clone();
 return root;
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
 const uniforms=[0x4b5947,0x59604d,0x414d48];
 for(let i=0;i<spots.length;i++){
  const soldier=createSoldier(uniforms[i]);
  soldier.root.position.copy(spots[i]);
  soldier.lastX=spots[i].x;soldier.lastZ=spots[i].z;
  scene.add(soldier.root);
  trainingBots.push({root:soldier.root,soldier,home:spots[i].clone(),phase:i*2.1,state:"patrol",lastSeen:null,speed:1.1+i*.15});
 }
}
function updateTrainingBots(dt,now){
 for(const bot of trainingBots){
  const p=bot.root.position,player=new THREE.Vector3(camera.position.x,0,camera.position.z);
  const distance=p.distanceTo(player);
  if(distance<7){bot.state="observe";bot.lastSeen=player.clone();}
  else if(bot.state==="observe"&&bot.lastSeen&&p.distanceTo(bot.lastSeen)>1.2)bot.state="return";
  let target;
  if(bot.state==="observe")target=bot.lastSeen;
  else if(bot.state==="return")target=bot.home;
  else target=new THREE.Vector3(bot.home.x+Math.sin(now*.00045+bot.phase)*2,0,bot.home.z+Math.cos(now*.0004+bot.phase)*2);
  const delta=target.clone().sub(p);delta.y=0;
  if(delta.length()>.15){
   const step=Math.min(delta.length(),bot.speed*dt);delta.normalize().multiplyScalar(step);p.add(delta);
   bot.soldier.targetYaw=Math.atan2(delta.x,delta.z);
  }else if(bot.state==="return")bot.state="patrol";
  animateSoldier(bot.soldier,dt,now);
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
  const nextX=Math.max(-19,Math.min(19,camera.position.x+dx));
  if(!collidesAt(nextX,camera.position.z))camera.position.x=nextX;
  const nextZ=Math.max(-19,Math.min(19,camera.position.z+dz));
  if(!collidesAt(camera.position.x,nextZ))camera.position.z=nextZ;
 }
 camera.position.y=1.65;
 camera.rotation.order="YXZ";camera.rotation.y=yaw;camera.rotation.x=pitch;
 const travelled=camera.position.distanceTo(previousCameraPosition);
 previousCameraPosition.copy(camera.position);
 const moving=travelled>0.0005;
 bobPhase+=dt*(moving?11:2.2);
 if(viewModel){
  const bob=moving?1:0;
  viewModel.position.set(.34+Math.sin(bobPhase*.5)*.012*bob,-.31+Math.abs(Math.cos(bobPhase))*.014*bob,-.58);
  viewModel.rotation.set(pitch*.08+Math.sin(bobPhase)*.012*bob,Math.sin(yaw*.35)*.012,Math.sin(bobPhase*.5)*.018*bob);
 }
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
 if(onlineMode&&socket?.readyState===WebSocket.OPEN&&now-lastNetSend>=70){
  lastNetSend=now;
  socket.send(JSON.stringify({type:"move",id:playerId,x:camera.position.x,z:camera.position.z,yaw}));
 }
 renderer.render(scene,camera);
 requestAnimationFrame(frame);
}
function disposeScene(){
 if(renderer){renderer.dispose();renderer=null;}
 if(scene){scene.traverse(o=>{
  if(o.geometry)o.geometry.dispose();
  if(o.material){const materials=Array.isArray(o.material)?o.material:[o.material];
   for(const material of materials){for(const value of Object.values(material)){if(value?.isTexture)value.dispose();}material.dispose();}
  }
 });}
 scene=null;camera=null;me=null;viewModel=null;peers.clear();objectives=[];trainingBots=[];characterMixers.clear();collisionBoxes.length=0;
}
function leaveGame(){
 joined=false;onlineMode=false;
 if(connectionTimer){clearTimeout(connectionTimer);connectionTimer=null;}
 if(socket){const old=socket;socket=null;old.close();}
 if(document.pointerLockElement===$("view"))document.exitPointerLock?.();
 for(const key of Object.keys(move))move[key]=false;
 disposeScene();
 game.classList.add("hidden");lobby.classList.remove("hidden");
 $("onlinePanel").classList.add("hidden");
 statusEl.textContent="メニューに戻りました。";
}
window.shiftPressed=false;
window.addEventListener("keydown",e=>{if(e.key==="Shift")window.shiftPressed=true;});
window.addEventListener("keyup",e=>{if(e.key==="Shift")window.shiftPressed=false;});
window.addEventListener("blur",()=>{for(const key of Object.keys(move))move[key]=false;window.shiftPressed=false;});
window.addEventListener("resize",resize,{passive:true});
