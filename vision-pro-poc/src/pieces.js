import * as THREE from 'three';

// Figurines "jouet" low-poly, lisibles de loin dans le casque.
function shadowed(mesh) {
  mesh.castShadow = true;
  return mesh;
}

export function createHero() {
  const g = new THREE.Group();
  const cloak = new THREE.MeshStandardMaterial({ color: '#ff8a3d', roughness: 0.6, flatShading: true });
  const skin = new THREE.MeshStandardMaterial({ color: '#ffe0bd', roughness: 0.7 });
  const hat = new THREE.MeshStandardMaterial({ color: '#2d3a8c', roughness: 0.5, flatShading: true });

  const body = shadowed(new THREE.Mesh(new THREE.ConeGeometry(0.022, 0.045, 7), cloak));
  body.position.y = 0.0225;
  const head = shadowed(new THREE.Mesh(new THREE.SphereGeometry(0.015, 16, 12), skin));
  head.position.y = 0.055;
  const brim = shadowed(new THREE.Mesh(new THREE.CylinderGeometry(0.022, 0.022, 0.003, 16), hat));
  brim.position.y = 0.064;
  const top = shadowed(new THREE.Mesh(new THREE.ConeGeometry(0.013, 0.035, 8), hat));
  top.position.set(0, 0.082, -0.003);
  top.rotation.x = -0.25;
  // Petit anneau torique flottant : la signature TORIX.
  const halo = new THREE.Mesh(
    new THREE.TorusGeometry(0.012, 0.0025, 8, 24),
    new THREE.MeshStandardMaterial({ color: '#7ff6ff', emissive: '#29d3ff', emissiveIntensity: 1.2 }),
  );
  halo.position.set(0.024, 0.06, 0.01);
  halo.name = 'halo';

  const eyes = new THREE.Mesh(
    new THREE.BoxGeometry(0.014, 0.004, 0.002),
    new THREE.MeshBasicMaterial({ color: '#1b1b2f' }),
  );
  eyes.position.set(0, 0.057, 0.0145);

  g.add(body, head, brim, top, halo, eyes);
  return g;
}

export function createGlitch() {
  const g = new THREE.Group();
  const inner = new THREE.Group();
  inner.name = 'bob';
  const shell = shadowed(new THREE.Mesh(
    new THREE.IcosahedronGeometry(0.022, 0),
    new THREE.MeshStandardMaterial({ color: '#8b3dff', emissive: '#3b0a8c', emissiveIntensity: 0.6, flatShading: true }),
  ));
  const eye = new THREE.Mesh(new THREE.SphereGeometry(0.008, 12, 8), new THREE.MeshBasicMaterial({ color: '#ffffff' }));
  eye.position.set(0, 0.004, 0.018);
  const pupil = new THREE.Mesh(new THREE.SphereGeometry(0.004, 8, 6), new THREE.MeshBasicMaterial({ color: '#ff2e63' }));
  pupil.position.set(0, 0.004, 0.0245);
  inner.add(shell, eye, pupil);
  inner.position.y = 0.035;
  g.add(inner);
  return g;
}

export function createPortal() {
  const g = new THREE.Group();
  const ringMat = new THREE.MeshStandardMaterial({ color: '#5ef2ff', emissive: '#00b7ff', emissiveIntensity: 1.4, roughness: 0.3 });
  const ring = shadowed(new THREE.Mesh(new THREE.TorusGeometry(0.03, 0.007, 12, 40), ringMat));
  ring.name = 'ring';

  // Voile tourbillonnant à l'intérieur de l'anneau.
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 128;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createRadialGradient(64, 64, 4, 64, 64, 64);
  grad.addColorStop(0, 'rgba(255,255,255,0.95)');
  grad.addColorStop(0.35, 'rgba(140,90,255,0.85)');
  grad.addColorStop(1, 'rgba(20,200,255,0.0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, 128, 128);
  ctx.strokeStyle = 'rgba(255,255,255,0.5)';
  ctx.lineWidth = 3;
  for (let i = 0; i < 4; i++) {
    ctx.beginPath();
    ctx.arc(64, 64, 14 + i * 12, i, i + 2.4);
    ctx.stroke();
  }
  const veil = new THREE.Mesh(
    new THREE.CircleGeometry(0.026, 32),
    new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(canvas), transparent: true, side: THREE.DoubleSide, depthWrite: false }),
  );
  veil.name = 'veil';

  const spinner = new THREE.Group();
  spinner.name = 'spinner';
  spinner.add(ring, veil);
  spinner.position.y = 0.045;
  g.add(spinner);

  const base = shadowed(new THREE.Mesh(
    new THREE.CylinderGeometry(0.03, 0.036, 0.01, 8),
    new THREE.MeshStandardMaterial({ color: '#4a4466', flatShading: true }),
  ));
  base.position.y = 0.005;
  g.add(base);
  return g;
}

export function createRock(seed = 0) {
  const rock = shadowed(new THREE.Mesh(
    new THREE.DodecahedronGeometry(0.03, 0),
    new THREE.MeshStandardMaterial({ color: '#8d8a9b', flatShading: true, roughness: 1 }),
  ));
  rock.scale.set(1, 0.8, 1);
  rock.rotation.set(seed, seed * 2.1, seed * 0.7);
  rock.position.y = 0.022;
  return rock;
}

// Barre de vie en sprite (toujours face au joueur).
export function createHpBar(color) {
  const canvas = document.createElement('canvas');
  canvas.width = 128;
  canvas.height = 20;
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: texture, depthTest: false }));
  sprite.scale.set(0.05, 0.008, 1);
  sprite.renderOrder = 10;
  sprite.raycast = () => {}; // décoratif : ne doit jamais intercepter un pincement
  sprite.update = (hp, max) => {
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, 128, 20);
    ctx.fillStyle = 'rgba(20,16,40,0.85)';
    ctx.fillRect(0, 0, 128, 20);
    ctx.fillStyle = color;
    ctx.fillRect(3, 3, Math.max(0, (hp / max) * 122), 14);
    texture.needsUpdate = true;
  };
  return sprite;
}
