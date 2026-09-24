import * as THREE from 'three';

// Décor : ciel dégradé, île sous les pieds du joueur, îles flottantes
// et grand anneau TORIX dans le ciel. Tout reste léger pour tenir 90 fps.
function sky() {
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide,
    depthWrite: false,
    uniforms: {
      top: { value: new THREE.Color('#5aa9ff') },
      horizon: { value: new THREE.Color('#ffd9b0') },
      bottom: { value: new THREE.Color('#6a4fa3') },
    },
    vertexShader: /* glsl */ `
      varying vec3 vDir;
      void main() {
        vDir = normalize(position);
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: /* glsl */ `
      uniform vec3 top; uniform vec3 horizon; uniform vec3 bottom;
      varying vec3 vDir;
      void main() {
        float h = vDir.y;
        vec3 c = h > 0.0 ? mix(horizon, top, pow(h, 0.6)) : mix(horizon, bottom, pow(-h, 0.5));
        gl_FragColor = vec4(c, 1.0);
      }`,
  });
  return new THREE.Mesh(new THREE.SphereGeometry(90, 32, 16), mat);
}

function island(radius, height, seed) {
  const g = new THREE.Group();
  const rock = new THREE.Mesh(
    new THREE.ConeGeometry(radius, height, 7, 2),
    new THREE.MeshStandardMaterial({ color: '#9b7653', flatShading: true, roughness: 1 }),
  );
  rock.rotation.x = Math.PI;
  rock.rotation.y = seed;
  rock.position.y = -height / 2;
  const grass = new THREE.Mesh(
    new THREE.CylinderGeometry(radius * 1.02, radius, radius * 0.12, 7),
    new THREE.MeshStandardMaterial({ color: '#78c850', flatShading: true, roughness: 0.9 }),
  );
  grass.rotation.y = seed;
  grass.position.y = radius * 0.06 - 0.001;
  grass.receiveShadow = true;
  g.add(rock, grass);
  return g;
}

function cloud(rand) {
  const g = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 1, flatShading: true });
  const puffs = 3 + Math.floor(rand() * 3);
  for (let i = 0; i < puffs; i++) {
    const s = 0.6 + rand() * 0.8;
    const puff = new THREE.Mesh(new THREE.IcosahedronGeometry(s, 0), mat);
    puff.position.set(i * 0.9 - puffs * 0.45, rand() * 0.4, rand() * 0.5);
    g.add(puff);
  }
  return g;
}

function mulberry32(a) {
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function createWorld(scene) {
  const rand = mulberry32(360);
  const animated = [];

  scene.add(sky());
  scene.fog = new THREE.Fog('#ffd9b0', 25, 85);

  scene.add(new THREE.HemisphereLight('#dff1ff', '#6a4f7a', 1.4));
  const sun = new THREE.DirectionalLight('#fff3dd', 2.2);
  sun.position.set(1.5, 3, 1);
  sun.target.position.set(0, 0.8, -0.7);
  sun.castShadow = true;
  sun.shadow.mapSize.set(1024, 1024);
  Object.assign(sun.shadow.camera, { left: -0.6, right: 0.6, top: 0.6, bottom: -0.6, near: 1, far: 6 });
  sun.shadow.bias = -0.0005;
  scene.add(sun, sun.target);

  // Île sur laquelle se tient le joueur (évite l'effet de vide sous les pieds).
  const home = island(2.2, 3.5, 0.3);
  scene.add(home);

  // Colonne qui porte le plateau de jeu.
  const pillar = new THREE.Mesh(
    new THREE.CylinderGeometry(0.3, 0.38, 0.8, 7),
    new THREE.MeshStandardMaterial({ color: '#a58a6b', flatShading: true, roughness: 1 }),
  );
  pillar.position.set(0, 0.4, -0.7);
  pillar.receiveShadow = true;
  scene.add(pillar);

  for (let i = 0; i < 14; i++) {
    const r = 0.5 + rand() * 2.5;
    const isl = island(r, r * 2.2, rand() * 6);
    const angle = rand() * Math.PI * 2;
    const dist = 9 + rand() * 30;
    isl.position.set(Math.cos(angle) * dist, -3 + rand() * 9, Math.sin(angle) * dist);
    isl.userData.bob = { base: isl.position.y, speed: 0.2 + rand() * 0.3, phase: rand() * 6 };
    animated.push(isl);
    scene.add(isl);
  }

  for (let i = 0; i < 16; i++) {
    const c = cloud(rand);
    const angle = rand() * Math.PI * 2;
    const dist = 15 + rand() * 40;
    c.position.set(Math.cos(angle) * dist, -6 + rand() * 16, Math.sin(angle) * dist);
    c.scale.setScalar(1 + rand() * 2);
    c.lookAt(0, c.position.y, 0);
    scene.add(c);
  }

  // Le grand anneau TORIX qui domine le monde.
  const torix = new THREE.Mesh(
    new THREE.TorusGeometry(9, 0.7, 20, 90),
    new THREE.MeshStandardMaterial({ color: '#7ff6ff', emissive: '#1e90ff', emissiveIntensity: 0.9, roughness: 0.3 }),
  );
  torix.position.set(0, 9, -45);
  scene.add(torix);

  return {
    update(t) {
      for (const isl of animated) {
        const b = isl.userData.bob;
        isl.position.y = b.base + Math.sin(t * b.speed + b.phase) * 0.3;
      }
      torix.rotation.y = t * 0.08;
      torix.rotation.z = Math.sin(t * 0.1) * 0.2;
    },
  };
}
