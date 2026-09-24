import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { VRButton } from 'three/addons/webxr/VRButton.js';
import { createWorld } from './world.js';
import { Game } from './game.js';
import { Input } from './input.js';
import { updateTweens } from './tween.js';

// Emplacement du plateau, en mètres dans l'espace "local-floor" :
// à hauteur de table, à portée de regard, devant le joueur.
const BOARD_POSITION = new THREE.Vector3(0, 0.82, -0.7);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.xr.enabled = true;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.01, 200);
camera.position.set(0, 1.45, 0.15);

const controls = new OrbitControls(camera, renderer.domElement);
controls.target.copy(BOARD_POSITION);
controls.enableDamping = true;
controls.minDistance = 0.5;
controls.maxDistance = 2.5;
controls.maxPolarAngle = Math.PI * 0.45;
controls.update();

const world = createWorld(scene);
const game = new Game();
game.group.position.copy(BOARD_POSITION);
scene.add(game.group);

const input = new Input(renderer, camera, game.group, {
  onPick: (pick) => game.onPick(pick),
  onHover: (pick) => game.onHover(pick),
});

const enterButton = VRButton.createButton(renderer);
enterButton.id = 'xr-button';
document.getElementById('xr-slot').appendChild(enterButton);

renderer.xr.addEventListener('sessionstart', () => document.body.classList.add('in-xr'));
renderer.xr.addEventListener('sessionend', () => document.body.classList.remove('in-xr'));

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// Accès de debug / tests automatisés.
window.__torix = { game, scene, camera, renderer };

const clock = new THREE.Clock();
renderer.setAnimationLoop(() => {
  const dt = Math.min(clock.getDelta(), 0.05);
  const t = clock.elapsedTime;
  if (!renderer.xr.isPresenting) controls.update();
  input.update();
  updateTweens(dt);
  world.update(t);
  game.update(t);
  renderer.render(scene, camera);
});
