import * as THREE from "three";
export function addRoadNetwork(scene) {
 const mat=(c,r=0.95,m=0)=>new THREE.MeshStandardMaterial({color:c,roughness:r,metalness:m});
 const roadMat=mat(0x34383a), patchMat=mat(0x45494a), white=mat(0xd6d0b5), amber=mat(0xc6a94e), curbMat=mat(0x777c7b), walkMat=mat(0x92938c), iron=mat(0x4d5556,.8,.5), poleMat=mat(0x77776e);
 // Gently uneven, subdivided asphalt strips form a four-way junction.
 for(const horizontal of [false,true]){
  const g=new THREE.PlaneGeometry(8.6,38,34,120),p=g.attributes.position;
  for(let i=0;i<p.count;i++){const x=p.getX(i),z=p.getY(i);p.setZ(i,Math.sin(x*1.7+z*.42)*.012+Math.sin(z*2.4-x*.7)*.008);}
  g.computeVertexNormals();const m=new THREE.Mesh(g,roadMat);m.rotation.x=-Math.PI/2;m.rotation.z=horizontal?Math.PI/2:0;m.position.y=.035;m.receiveShadow=true;scene.add(m);
 }
 let seed=90210;const rand=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
 for(let i=0;i<24;i++){const h=i%2===0,a=-16+rand()*32,b=(rand()-.5)*5.8,m=new THREE.Mesh(new THREE.CircleGeometry(.5+rand()*.65,7),patchMat);m.rotation.x=-Math.PI/2;m.rotation.z=rand()*Math.PI;m.scale.set(.7+rand(),.45+rand()*.5,1);m.position.set(h?a:b,.049,h?b:a);scene.add(m);}
 for(let z=-17;z<18;z+=4.3){const m=new THREE.Mesh(new THREE.BoxGeometry(.1,.012,2.1),amber);m.position.set(0,.055,z);scene.add(m);}
 for(let i=-3;i<=3;i++){const m=new THREE.Mesh(new THREE.BoxGeometry(.72,.014,.12),white);m.position.set(i*1.02,.058,-4.9);scene.add(m);}
 for(const side of [-1,1])for(const horizontal of [false,true]){
  const curb=new THREE.Mesh(new THREE.BoxGeometry(horizontal?38:.34,.22,horizontal?.34:38),curbMat);curb.position.set(horizontal?0:side*4.48,.11,horizontal?side*4.48:0);scene.add(curb);
  const walk=new THREE.Mesh(new THREE.BoxGeometry(horizontal?38:2.6,.18,horizontal?2.6:38),walkMat);walk.position.set(horizontal?0:side*5.9,.09,horizontal?side*5.9:0);scene.add(walk);
  const edge=new THREE.Mesh(new THREE.BoxGeometry(horizontal?38:.09,.014,horizontal?.09:38),white);edge.position.set(horizontal?0:side*4.08,.052,horizontal?side*4.08:0);scene.add(edge);
 }
 for(const [x,z] of [[-2.7,7.5],[2.5,-12.5],[7.1,2.8],[-7.1,-2.2]]){const m=new THREE.Mesh(new THREE.CylinderGeometry(.42,.42,.035,24),iron);m.position.set(x,.06,z);scene.add(m);}
 for(const side of [-1,1])for(let z=-15;z<=15;z+=6){const m=new THREE.Mesh(new THREE.BoxGeometry(.16,.025,.72),iron);m.position.set(side*4.23,.065,z);scene.add(m);}
 // Utility poles and suspended lines.
 const cableMat=mat(0x202729,.75,.3),poleZ=[-15,-5,5,15];
 for(const x of [-8.2,8.2]){
  for(const z of poleZ){const g=new THREE.Group();g.position.set(x,0,z);const shaft=new THREE.Mesh(new THREE.CylinderGeometry(.16,.23,7.8,9),poleMat);shaft.position.y=3.9;shaft.castShadow=true;g.add(shaft);const arm=new THREE.Mesh(new THREE.BoxGeometry(1.55,.13,.16),poleMat);arm.position.y=7.48;g.add(arm);for(const side of [-1,0,1]){const pin=new THREE.Mesh(new THREE.CylinderGeometry(.045,.055,.28,8),iron);pin.position.set(side*.56,7.68,0);g.add(pin);}const foot=new THREE.Mesh(new THREE.CylinderGeometry(.25,.29,.42,9),curbMat);foot.position.y=.21;g.add(foot);scene.add(g);}
  for(const offset of [-.56,0,.56]){const pts=poleZ.map((z,i)=>new THREE.Vector3(x+offset,7.72-Math.sin(i/3*Math.PI)*.62,z));scene.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts),48,.018,5,false),cableMat));}
 }
 for(const z of [-5,5])for(const offset of [-.45,.45]){const c=new THREE.CatmullRomCurve3([new THREE.Vector3(-8.2,7.72,z+offset),new THREE.Vector3(-3,7.12,z+offset),new THREE.Vector3(3,7.12,z+offset),new THREE.Vector3(8.2,7.72,z+offset)]);scene.add(new THREE.Mesh(new THREE.TubeGeometry(c,40,.016,5,false),cableMat));}
}