import * as THREE from 'three';

// Plateau 8×8, dimensions en mètres (échelle "maquette sur table").
export const N = 8;
export const T = 0.09;

const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]];

const COLORS = {
  base: [new THREE.Color('#efe3c4'), new THREE.Color('#e2d3ae')],
  move: new THREE.Color('#7ed957'),
  path: new THREE.Color('#3fb83f'),
  range: new THREE.Color('#79b8ff'),
  target: new THREE.Color('#ff7a59'),
};

export const key = (x, z) => `${x},${z}`;
export const manhattan = (a, b) => Math.abs(a.x - b.x) + Math.abs(a.z - b.z);
export const inBounds = (x, z) => x >= 0 && z >= 0 && x < N && z < N;

export function tileToLocal(x, z, y = 0) {
  return new THREE.Vector3((x - (N - 1) / 2) * T, y, (z - (N - 1) / 2) * T);
}

export function neighbours(x, z) {
  return DIRS.map(([dx, dz]) => ({ x: x + dx, z: z + dz })).filter((p) => inBounds(p.x, p.z));
}

// Parcours en largeur : renvoie toutes les cases atteignables (avec leur
// prédécesseur) depuis `start`, en ignorant les cases bloquées.
export function bfs(start, isBlocked, maxDist = Infinity) {
  const first = { x: start.x, z: start.z, d: 0, prev: null };
  const out = new Map([[key(start.x, start.z), first]]);
  const queue = [first];
  while (queue.length) {
    const cur = queue.shift();
    if (cur.d >= maxDist) continue;
    for (const n of neighbours(cur.x, cur.z)) {
      const k = key(n.x, n.z);
      if (out.has(k) || isBlocked(n.x, n.z)) continue;
      const node = { x: n.x, z: n.z, d: cur.d + 1, prev: cur };
      out.set(k, node);
      queue.push(node);
    }
  }
  return out;
}

export function pathTo(node) {
  const path = [];
  while (node && node.prev) {
    path.unshift({ x: node.x, z: node.z });
    node = node.prev;
  }
  return path;
}

export class Board {
  constructor() {
    this.group = new THREE.Group();
    this.tiles = new Map();

    const geo = new THREE.BoxGeometry(T * 0.94, 0.012, T * 0.94);
    for (let x = 0; x < N; x++) {
      for (let z = 0; z < N; z++) {
        const base = COLORS.base[(x + z) % 2];
        const mat = new THREE.MeshStandardMaterial({ color: base.clone(), roughness: 0.85 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.copy(tileToLocal(x, z, 0.006));
        mesh.receiveShadow = true;
        mesh.userData.pick = { type: 'tile', x, z };
        this.group.add(mesh);
        this.tiles.set(key(x, z), { mesh, base });
      }
    }

    // Socle en pierre sous les cases.
    const plinth = new THREE.Mesh(
      new THREE.BoxGeometry(N * T + 0.03, 0.03, N * T + 0.03),
      new THREE.MeshStandardMaterial({ color: '#8a6f55', roughness: 1 }),
    );
    plinth.position.y = -0.015;
    plinth.receiveShadow = true;
    this.group.add(plinth);
  }

  clearTints() {
    for (const t of this.tiles.values()) {
      t.mesh.material.color.copy(t.base);
      t.mesh.material.emissive.setHex(0x000000);
    }
  }

  tint(x, z, mode) {
    const t = this.tiles.get(key(x, z));
    if (!t) return;
    t.mesh.material.color.copy(t.base).lerp(COLORS[mode], mode === 'range' ? 0.55 : 0.75);
    if (mode === 'path' || mode === 'target') t.mesh.material.emissive.set(COLORS[mode]).multiplyScalar(0.25);
  }
}
