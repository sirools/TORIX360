import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';

// Détection des environnements
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const isProd = !isLocal; // Si ce n'est pas local, on considère que c'est production

// Définition du chemin de base en fonction de l'environnement
const basePath = isProd ? '/TORIX360/dist/assets/images/' : './assets/images/';

// Tableau des chemins des textures
const texturePaths = [
    `${basePath}artwork1.jpg`,
    `${basePath}artwork2.jpg`,
    `${basePath}artwork3.jpg`,
    `${basePath}artwork4.jpg`,
    `${basePath}artwork-final-V1.jpg`,
];

// Configuration Three.js
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1);
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

// Initialisation des OrbitControls
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.05;
controls.minDistance = 10;
controls.maxDistance = 480;
controls.zoomSpeed = 2;

// Charger les textures et initialiser les sphères
Promise.all(texturePaths.map(loadTexture))
    .then((loadedTextures) => {
        const sphereManager = new SphereManager(scene, loadedTextures, renderer);
        sphereManager.createSpheres();

        // Ajouter la logique des interactions et des transitions ici si nécessaire

        animate();
    })
    .catch((err) => {
        console.error('Erreur lors du chargement des textures :', err);
    });

// Boucle d'animation
function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
}

// Gestion du redimensionnement
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});