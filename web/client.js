import * as THREE from "https://cdn.jsdelivr.net/npm/three@0.164.1/build/three.module.js";

const $ = id => document.getElementById(id);
const intro = $("intro"), lobby = $("lobby"), game = $("game"), statusEl = $("status");
let socket = null, renderer, scene, camera, me, yaw = 0, pitch = 0, last = performance.now();
let peers = new Map(), move = {forward:false,back:false,left:false,right:false};
let touchLook = false, lastTouch = null, joined = false, onlineMode = false;
let objectives = [], objectiveIndex = 0, timeLeft = 180, missionEnded = false;
let weapon, muzzleFlash, ammo = 30, reserveAmmo = 120, reloading = false, reloadAt = 0;
let recoil = 0, fireCooldown = 0, aiming = false, shotCount = 0, walkPhase = 0;
const playerId = crypto.randomUUID ? crypto.randomUUID() : String(Math.random()).slice(2);
const palette = [0x7b8970,0x8b8d7b,0x697d70,0x9a9277,0x6d7776,0x8d806e];
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
window.addEventListener("contextmenu",e=>{if(joined)e.preventDefault();});
window.addEventListener("mousedown",e=>{if(!joined)return;if(e.button===2){aiming=true;}if(e.button===0)fireWeapon();});
window.addEventListener("mouseup",e=>{if(e.button===2)aiming=false;});
window.addEventListener("keydown",e=>{if(e.key.toLowerCase()==="r")startReload();});
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
 weapon=createFirstPersonWeapon();
 camera.add(weapon.root);
 scene.add(camera);
 installCombatHud();
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
function createFirstPersonWeapon(){
 const root=new THREE.Group();
 const metal=new THREE.MeshStandardMaterial({color:0x20262a,roughness:.48,metalness:.72});
 const polymer=new THREE.MeshStandardMaterial({color:0x303932,roughness:.86,metalness:.08});
 const rubber=new THREE.MeshStandardMaterial({color:0x151a19,roughness:1});
 const sight=new THREE.MeshStandardMaterial({color:0x0d1214,roughness:.3,metalness:.55});
 const add=(geo,mat,pos,scale)=>{const m=new THREE.Mesh(geo,mat);m.position.set(...pos);if(scale)m.scale.set(...scale);root.add(m);return m;};
 // Stylized fictional first-person rifle, built from low-cost local geometry.
 add(new THREE.BoxGeometry(.19,.16,.57),polymer,[.23,-.23,-.58]);
 add(new THREE.BoxGeometry(.16,.19,.23),rubber,[.23,-.25,-.23]); // stock
 add(new THREE.BoxGeometry(.12,.19,.2),polymer,[.23,-.31,-.82]); // receiver
 add(new THREE.BoxGeometry(.075,.1,.28),metal,[.23,-.23,-1.01]); // handguard
 add(new THREE.CylinderGeometry(.026,.026,.58,10),metal,[.23,-.22,-1.35]).rotation.x=Math.PI/2;
 add(new THREE.BoxGeometry(.035,.04,.18),rubber,[.23,-.33,-.8]); // magazine
 add(new THREE.BoxGeometry(.055,.035,.16),sight,[.23,-.13,-.82]);
 add(new THREE.BoxGeometry(.045,.04,.07),sight,[.23,-.12,-1.12]);
 add(new THREE.BoxGeometry(.045,.055,.13),polymer,[.23,-.36,-.54]); // grip
 const flashMat=new THREE.MeshBasicMaterial({color:0xffd27a,transparent:true,opacity:.95});
 muzzleFlash=new THREE.Mesh(new THREE.ConeGeometry(.075,.22,8),flashMat);
 muzzleFlash.rotation.x=-Math.PI/2;muzzleFlash.position.set(.23,-.22,-1.68);muzzleFlash.visible=false;root.add(muzzleFlash);
 root.position.set(.0,-.02,-.02);
 return {root,baseX:0,baseY:-.02,baseZ:-.02};
}
function installCombatHud(){
 let hud=document.getElementById("combatHud");
 if(!hud){hud=document.createElement("div");hud.id="combatHud";hud.innerHTML='<div class="ammoReadout"><span id="ammoNow">30</span><span class="ammoSlash"> / </span><span id="ammoReserve">120</span><small id="weaponLabel">ASSAULT RIFLE</small><small id="reloadLabel"></small></div><div class="hitMarker" id="hitMarker">×</div><button id="fireButton" type="button">FIRE</button><button id="reloadButton" type="button">RELOAD</button>';game.appendChild(hud);}
 $("fireButton").onclick=fireWeapon;$("reloadButton").onclick=startReload;updateAmmoHud();
}
function updateAmmoHud(){
 if($("ammoNow"))$("ammoNow").textContent=String(ammo);
 if($("ammoReserve"))$("ammoReserve").textContent=String(reserveAmmo);
 if($("reloadLabel"))$("reloadLabel").textContent=reloading?"RELOADING…":"";
}
function startReload(){
 if(!joined||reloading||ammo>=30||reserveAmmo<=0)return;
 reloading=true;reloadAt=performance.now()+1450;updateAmmoHud();
}
function fireWeapon(){
 if(!joined||missionEnded||reloading||fireCooldown>0)return;
 if(ammo<=0){startReload();return;}
 ammo--;shotCount++;fireCooldown=.105;recoil=Math.min(recoil+.075,.22);
 if(muzzleFlash){muzzleFlash.visible=true;muzzleFlash.scale.setScalar(.7+Math.random()*.7);}
 if($("hitMarker")){$("hitMarker").classList.remove("show");void $("hitMarker").offsetWidth;$("hitMarker").classList.add("show");}
 updateAmmoHud();
}
function addBox(x,y,z,sx,sy,sz,color){
 const m=new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),new THREE.MeshStandardMaterial({color,roughness:.92}));
 m.position.set(x,y,z);scene.add(m);return m;
}
function resize(){if(!renderer||!camera)return;camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);}
function makeFabricTexture(seed=1){
 const canvas=document.createElement("canvas");canvas.width=canvas.height=256;
 const ctx=canvas.getContext("2d");let state=(seed|0)||1;
 const rand=()=>{state=(Math.imul(state,1664525)+1013904223)|0;return (state>>>0)/4294967296;};
 ctx.fillStyle="#777b68";ctx.fillRect(0,0,256,256);
 const camo=["#4c5948","#626b52","#8b8b70","#343e37","#9a9276"];
 for(let i=0;i<95;i++){
  ctx.fillStyle=camo[Math.floor(rand()*camo.length)];
  ctx.beginPath();let x=rand()*256,y=rand()*256;ctx.moveTo(x,y);
  for(let j=0;j<5;j++){x+=(rand()-.5)*34;y+=(rand()-.5)*30;ctx.lineTo(x,y);}
  ctx.closePath();ctx.fill();
 }
 for(let i=0;i<1800;i++){
  const v=Math.floor(75+rand()*90);
  ctx.fillStyle="rgba("+v+","+v+","+v+","+(rand()*.12)+")";
  ctx.fillRect(rand()*256,rand()*256,1+rand()*2,1);
 }
 ctx.strokeStyle="rgba(25,30,26,.22)";ctx.lineWidth=1;
 for(let y=8;y<256;y+=16){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(256,y);ctx.stroke();}
 const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
 texture.wrapS=texture.wrapT=THREE.RepeatWrapping;texture.repeat.set(1.5,2.2);texture.anisotropy=1;
 return texture;
}
function makeGearTexture(){
 const canvas=document.createElement("canvas");canvas.width=canvas.height=256;
 const ctx=canvas.getContext("2d");ctx.fillStyle="#454e49";ctx.fillRect(0,0,256,256);
 for(let y=0;y<256;y+=32){for(let x=0;x<256;x+=32){
  ctx.fillStyle=((x+y)/32)%2?"#505951":"#3b4540";ctx.fillRect(x+2,y+2,28,28);
  ctx.strokeStyle="#697167";ctx.lineWidth=2;ctx.strokeRect(x+4,y+4,24,24);
  ctx.fillStyle="#262f2a";ctx.fillRect(x+7,y+7,18,18);
 }}
 for(let i=0;i<500;i++){const v=Math.floor(45+Math.random()*45);ctx.fillStyle="rgba("+v+","+v+","+v+",.18)";ctx.fillRect(Math.random()*256,Math.random()*256,1,1);}
 const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;
 texture.wrapS=texture.wrapT=THREE.RepeatWrapping;texture.repeat.set(1.5,1.5);return texture;
}
function createSoldier(color){
 const root=new THREE.Group();
 const clothTexture=makeFabricTexture(Math.round(color));
 const gearTexture=makeGearTexture();
 const cloth=new THREE.MeshStandardMaterial({color:0xc2c6b3,map:clothTexture,roughness:1});
 const dark=new THREE.MeshStandardMaterial({color:0x202722,roughness:.96});
 const gear=new THREE.MeshStandardMaterial({color:0xc4c7b9,map:gearTexture,roughness:.94,metalness:.04});
 const skin=new THREE.MeshStandardMaterial({color:0xb88e70,roughness:.92});
 const part=(geometry,material,parent,position)=>{
  const mesh=new THREE.Mesh(geometry,material);mesh.position.copy(position);parent.add(mesh);return mesh;
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
 // A simple low-poly rifle silhouette held across the chest.
 const rifle=new THREE.Group();root.add(rifle);
 part(new THREE.BoxGeometry(.12,.12,.72),dark,rifle,new THREE.Vector3(.12,1.27,-.22));
 part(new THREE.CylinderGeometry(.018,.018,.48,6),gear,rifle,new THREE.Vector3(.12,1.3,-.69)).rotation.x=Math.PI/2;
 rifle.rotation.x=-.08;
 return {root,leftArm,rightArm,leftLeg,rightLeg,rifle,target:new THREE.Vector3(),targetYaw:0,lastX:0,lastZ:0,speed:0,phase:0,cloth, dark,gear,skin};
}
function animateSoldier(s,dt,now){
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
 for(const [id,obj] of peers){if(!alive.has(id)){scene?.remove(obj.root);peers.delete(id);}}
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
 if(muzzleFlash&&muzzleFlash.visible){muzzleFlash.visible=false;}
 if(reloading&&now>=reloadAt){const need=30-ammo,loaded=Math.min(need,reserveAmmo);ammo+=loaded;reserveAmmo-=loaded;reloading=false;updateAmmoHud();}
 recoil=THREE.MathUtils.damp(recoil,0,15,dt);
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
 walkPhase+=dt*(speed>0?Math.min(14,speed*2.2):1.4);
 const bob=(speed>0?Math.sin(walkPhase)*.012:Math.sin(now*.0018)*.002);
 camera.position.y=1.65+bob;
 camera.rotation.order="YXZ";camera.rotation.y=yaw;camera.rotation.x=pitch;
 if(weapon){
  const targetX=aiming?-.115:0,targetY=aiming?-.095:-.02,targetZ=aiming?.18:-.02;
  weapon.root.position.x=THREE.MathUtils.damp(weapon.root.position.x,targetX,12,dt);
  weapon.root.position.y=THREE.MathUtils.damp(weapon.root.position.y,targetY+bob*1.4,12,dt)-recoil*.28;
  weapon.root.position.z=THREE.MathUtils.damp(weapon.root.position.z,targetZ,12,dt)+recoil;
  weapon.root.rotation.x=THREE.MathUtils.damp(weapon.root.rotation.x,aiming?-.02:0,10,dt)+recoil*.8;
  weapon.root.rotation.z=THREE.MathUtils.damp(weapon.root.rotation.z,speed>0?Math.sin(walkPhase)*.012:0,8,dt);
 }
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
 scene=null;camera=null;me=null;peers.clear();objectives=[];weapon=null;muzzleFlash=null;reloading=false;ammo=30;reserveAmmo=120;aiming=false;
 const combatHud=$("combatHud");if(combatHud)combatHud.remove();
 game.classList.add("hidden");lobby.classList.remove("hidden");
 $("onlinePanel").classList.add("hidden");
 statusEl.textContent="メニューに戻りました。";
}
window.shiftPressed=false;
window.addEventListener("keydown",e=>{if(e.key==="Shift")window.shiftPressed=true;});
window.addEventListener("keyup",e=>{if(e.key==="Shift")window.shiftPressed=false;});
