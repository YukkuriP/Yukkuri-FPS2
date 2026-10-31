import * as THREE from "three";

export function addUrbanDetails(scene, collisionBoxes = []) {
  const material = (color, roughness = .9, metalness = .04) =>
    new THREE.MeshStandardMaterial({ color, roughness, metalness });
  const concrete = material(0x777d7c);
  const darkConcrete = material(0x454e52);
  const trim = material(0x303a3e, .72, .18);
  const glass = material(0x526b73, .28, .28);
  const litGlass = material(0x9b9278, .38, .12,);
  const metal = material(0x596368, .58, .55);
  const signFace = material(0x31515a, .72, .12);
  const fadedPaint = material(0x9a8c70);
  const wood = material(0x554b3d);
  const box = (x,y,z,sx,sy,sz,mat,parent=scene) => {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(sx,sy,sz),mat);
    mesh.position.set(x,y,z); mesh.castShadow = true; mesh.receiveShadow = true;
    parent.add(mesh); return mesh;
  };
  const cylinder = (x,y,z,r1,r2,h,mat,parent=scene) => {
    const mesh = new THREE.Mesh(new THREE.CylinderGeometry(r1,r2,h,10),mat);
    mesh.position.set(x,y,z); mesh.castShadow = true; mesh.receiveShadow = true;
    parent.add(mesh); return mesh;
  };

  // Weathered facade layers on the existing low-rise structures.
  const buildings = [
    {x:-10,z:1,w:2.5,h:2.5,d:5},
    {x:10,z:-2,w:2.5,h:2.5,d:5},
    {x:-4,z:-5,w:3,h:1.6,d:2.2},
    {x:5,z:6,w:3.2,h:1.4,d:2.4},
    {x:0,z:0,w:3.8,h:1.9,d:2},
    {x:-7,z:7,w:2.5,h:1.4,d:2.2},
    {x:8,z:7,w:2.2,h:1.3,d:2.5}
  ];
  for (let i=0;i<buildings.length;i++) {
    // Dress both street-facing sides so the facade remains detailed when approached from either direction.
    const rows=Math.max(1,Math.floor((b.h-.35)/.85));
    const cols=Math.max(1,Math.floor(b.w/.82));
    for(const face of [-1,1]) {
      const front=b.z+face*(b.d/2+.018), outward=face;
      for(let row=0;row<rows;row++) for(let col=0;col<cols;col++) {
        const x=b.x+(col-(cols-1)/2)*.78;
        const y=.42+row*.78;
        if(y>b.h-.22) continue;
        box(x,y,front,.43,.38,.035,trim);
        box(x,y,front+outward*.022,.34,.29,.018,(row+col+i)%4===0?litGlass:glass);
        box(x,y+.205,front+outward*.025,.49,.045,.055,concrete);
        box(x,y-.205,front+outward*.025,.49,.045,.055,concrete);
        box(x-.205,y,front+outward*.025,.045,.38,.055,concrete);
        box(x+.205,y,front+outward*.025,.045,.38,.055,concrete);
      }
      if(b.h>1.5) {
        const ax=b.x+b.w*.32, ay=Math.min(b.h-.35,1.45);
        box(ax,ay,front+outward*.16,.62,.34,.22,metal);
        box(ax,ay-.02,front+outward*.285,.43,.18,.025,darkConcrete);
        for(let k=-1;k<=1;k++) box(ax+k*.12,ay-.02,front+outward*.305,.025,.14,.018,concrete);
        cylinder(ax+.39,ay-.13,front+outward*.16,.035,.035,.55,metal).rotation.z=Math.PI/2;
      }
      box(b.x,b.h>.5?.19:.1,front-outward*.025,b.w+.04,.16,.08,darkConcrete);
      for(let k=0;k<2;k++) {
        const x=b.x+(k?1:-1)*b.w*.38;
        box(x,b.h*.52,front-outward*.012,.035,b.h*.72,.025,fadedPaint);
      }
    }
  }

  // Utility cabinets, waste bins and bollards along the sidewalks.
  for(const [x,z] of [[-6.8,-8.1],[6.8,8.1],[-6.8,8.1],[6.8,-8.1]]) {
    box(x,.62,z,.72,1.12,.48,concrete);
    collisionBoxes.push({minX:x-.36,maxX:x+.36,minZ:z-.24,maxZ:z+.24});
    box(x,.65,z-.251,.58,.82,.025,darkConcrete);
    box(x,.94,z-.27,.34,.08,.035,metal);
    for(let k=0;k<3;k++) box(x-.2+k*.2,.23,z-.27,.025,.035,.025,fadedPaint);
  }
  const bollards = new THREE.InstancedMesh(new THREE.CylinderGeometry(.095,.12,.72,8),metal,26);
  const dummy=new THREE.Object3D(); let n=0;
  for(const side of [-1,1]) for(let z=-15;z<=15;z+=2.5) {
    dummy.position.set(side*6.95,.36,z); dummy.rotation.set(0,0,0); dummy.updateMatrix();
    bollards.setMatrixAt(n++,dummy.matrix);
  }
  bollards.count=n; bollards.instanceMatrix.needsUpdate=true; bollards.castShadow=true; scene.add(bollards);

  // Street-name signs at the junction, with a second contrasting plate.
  for(const [x,z,rot] of [[-5.2,-6.8,0],[5.2,6.8,Math.PI]]) {
    const g=new THREE.Group();g.position.set(x,0,z);g.rotation.y=rot;scene.add(g);
    cylinder(0,1.55,0,.055,.075,3.1,metal,g);
    box(.38,2.72,0,1.15,.34,.09,signFace,g);
    box(.38,2.72,.052,.98,.035,.012,litGlass,g);
    box(.38,2.72,-.052,.98,.035,.012,trim,g);
    box(.38,2.48,0,1.15,.035,.09,trim,g);
  }

  // Two restrained street lamps; emissive fixtures read clearly without expensive point lights.
  const lampMat=material(0x343c3f,.55,.45), glow=material(0xd5bd83,.32,.08);
  for(const [x,z] of [[-6.1,-12.2],[6.1,12.2]]) {
    const g=new THREE.Group();g.position.set(x,0,z);scene.add(g);
    cylinder(0,2.65,0,.075,.12,5.3,lampMat,g);
    const arm=box(.38,5.18,0,.9,.075,.075,lampMat,g);arm.rotation.z=-.13;
    box(.78,5.03,0,.42,.12,.24,lampMat,g);
    box(.78,4.95,0,.28,.035,.16,glow,g);
  }

  // Small roadside service details: drain channels and access covers.
  for(const side of [-1,1]) for(let z=-13;z<=13;z+=6.5) {
    box(side*4.12,.055,z,.16,.025,1.05,darkConcrete);
    for(let k=0;k<5;k++) box(side*4.12,.071,z-.42+k*.21,.17,.012,.035,metal);
  }
  for(const [x,z] of [[-3.2,8.8],[3.4,-10.2]]) {
    cylinder(x,.065,z,.34,.34,.06,darkConcrete);
    cylinder(x,.101,z,.27,.27,.012,metal);
    for(let k=0;k<8;k++) {
      const a=k*Math.PI/4;
      box(x+Math.cos(a)*.14,.11,z+Math.sin(a)*.14,.018,.008,.23,trim).rotation.y=-a;
    }
  }

  // Low piles of weathered boards and masonry add variation at building edges.
  for(let i=0;i<8;i++) {
    const x=(i%2?1:-1)*(8.8+(i%3)*.5), z=-11+(i*3.1);
    const plank=box(x,.13,z,.95,.12,.22,wood);
    plank.rotation.y=(i%3)*.16;
    box(x+.08,.27,z+.08,.38,.16,.34,darkConcrete);
  }
}
