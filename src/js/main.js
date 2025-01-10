import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';
import { transitionManager } from '@js/transitionManager.js';
import { interactionManager } from '@js/interactionManager.js';

// Exemple de chargement
const texturePath = './assets/images/artwork1.jpg';
loadTexture(texturePath)
    .then((texture) => {
        console.log('Texture chargée et prête à être utilisée:', texture);
    })
    .catch((err) => {
        console.error('Erreur lors du chargement de la texture:', err);
    });

// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
camera.fov = 50;
camera.updateProjectionMatrix();

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1); // Définir le fond noir
document.body.appendChild(renderer.domElement);

// Détecter l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// Définir la base des chemins
const basePath = isLocal ? './' : './dist/';

// Tableau des chemins des textures
const texturePaths = [
    `${basePath}assets/images/artwork1.jpg`,
    `${basePath}assets/images/artwork2.jpg`,
    `${basePath}assets/images/artwork3.jpg`,
    `${basePath}assets/images/artwork4.jpg`,
    `${basePath}assets/images/artwork-final-V1.jpg`,
];

// Charger les textures et initialiser les sphères
Promise.all(texturePaths.map(loadTexture))
    .then((loadedTextures) => {
        const sphereManager = new SphereManager(scene, loadedTextures);
        sphereManager.createSpheres();

        // Matrice d'adjacence pour définir les connexions logiques entre sphères
        const adjacencyMatrix = [
            [1, 2],    // La sphère 0 est connectée aux sphères 1 et 2
            [0, 3],    // La sphère 1 est connectée aux sphères 0 et 3
            [0, 3],    // La sphère 2 est connectée aux sphères 0 et 3
            [1, 2, 4], // La sphère 3 est connectée aux sphères 1, 2 et 4
            [3],       // La sphère 4 est connectée uniquement à la sphère 3
        ];
        sphereManager.setAdjacencyMatrix(adjacencyMatrix);

        // Gestion des transitions avec les touches du clavier
        document.addEventListener('keydown', (event) => {
            if (event.key === 'ArrowRight') {
                const nextIndex = (sphereManager.currentIndex + 1) % sphereManager.spheres.length; // Passer à la sphère suivante
                sphereManager.navigateToSphere(nextIndex, 1000);
            } else if (event.key === 'ArrowLeft') {
                const prevIndex = (sphereManager.currentIndex - 1 + sphereManager.spheres.length) % sphereManager.spheres.length; // Revenir à la sphère précédente
                sphereManager.navigateToSphere(prevIndex, 1000);
            }
        });

        // Naviguer entre les sphères sur mobile
        document.getElementById("prevSphere").addEventListener("click", () => {
            sphereManager.navigateToSphere(
                sphereManager.currentIndex - 1 < 0 
                    ? sphereManager.spheres.length - 1 
                    : sphereManager.currentIndex - 1, 
                1000
            );
        });

        document.getElementById("nextSphere").addEventListener("click", () => {
            sphereManager.navigateToSphere(
                (sphereManager.currentIndex + 1) % sphereManager.spheres.length, 
                1000
            );
        });

        // Boucle d'animation
        animate();
    })
    .catch((err) => {
        console.error("Erreur lors du chargement des textures :", err);
    });

// Initialisation des OrbitControls
function initControls() {
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.minDistance = 10;
    controls.maxDistance = 480;
    controls.zoomSpeed = 2;
    controls.update(); // Mettre à jour à chaque frame
}

// Animation
function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}

// Ajuster la taille au redimensionnement de la fenêtre
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});

// Initialisation
initControls();