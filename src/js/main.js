import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';

// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1); // Fond noir
document.body.appendChild(renderer.domElement);

// Détecter l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// Définir la base des chemins
const basePath = isLocal ? './' : '/TORIX360/';

// Tableau des chemins des textures
const texturePaths = [
    `${basePath}assets/images/artwork1.jpg`,
    `${basePath}assets/images/artwork2.jpg`,
    `${basePath}assets/images/artwork3.jpg`,
    `${basePath}assets/images/artwork4.jpg`,
    `${basePath}assets/images/artwork-final-V1.jpg`,
];

Promise.all(texturePaths.map(loadTexture))
    .then((loadedTextures) => {
        const sphereManager = new SphereManager(scene, loadedTextures, renderer);
        sphereManager.createSpheres();
        // Ajouter d'autres logiques ou contrôles ici
        animate();
    })
    .catch((err) => {
        console.error("Erreur lors du chargement des textures :", err);
    });

// Initialisation des OrbitControls
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;

// Boucle d'animation
function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}

// Gestion du redimensionnement
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});