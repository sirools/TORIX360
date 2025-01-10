import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';

<<<<<<< HEAD
=======
// Postprocessing
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';

>>>>>>> main
// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
<<<<<<< HEAD
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1); // Fond noir
document.body.appendChild(renderer.domElement);

// Détecter l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// Définir la base des chemins
=======
camera.fov = 50;
camera.updateProjectionMatrix();

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

// Postprocessing
const composer = new EffectComposer(renderer);
const renderPass = new RenderPass(scene, camera);
composer.addPass(renderPass);

const brightnessContrastPass = new ShaderPass(BrightnessContrastShader);
brightnessContrastPass.uniforms.brightness.value = 0.0;
brightnessContrastPass.uniforms.contrast.value = 0.0;
composer.addPass(brightnessContrastPass);

// Détecter l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
>>>>>>> main
const basePath = isLocal ? './' : '/TORIX360/';

// Tableau des chemins des textures
const texturePaths = [
    `${basePath}assets/images/artwork1.jpg`,
    `${basePath}assets/images/artwork2.jpg`,
    `${basePath}assets/images/artwork3.jpg`,
    `${basePath}assets/images/artwork4.jpg`,
    `${basePath}assets/images/artwork-final-V1.jpg`,
];

<<<<<<< HEAD
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
=======
// Charger les textures et initialiser les sphères
Promise.all(texturePaths.map(loadTexture))
    .then((loadedTextures) => {
        const sphereManager = new SphereManager(scene, loadedTextures, renderer);

        sphereManager.createSpheres();

        const adjacencyMatrix = [
            [1, 2],
            [0, 3],
            [0, 3],
            [1, 2, 4],
            [3],
        ];
        sphereManager.setAdjacencyMatrix(adjacencyMatrix);

        // Gestion des transitions avec les touches du clavier
        document.addEventListener('keydown', (event) => {
            if (event.key === 'ArrowRight') {
                const nextIndex = (sphereManager.currentIndex + 1) % sphereManager.spheres.length;
                sphereManager.navigateToSphere(nextIndex, 1000);
            } else if (event.key === 'ArrowLeft') {
                const prevIndex = (sphereManager.currentIndex - 1 + sphereManager.spheres.length) % sphereManager.spheres.length;
                sphereManager.navigateToSphere(prevIndex, 1000);
            }
        });

        // Naviguer entre les sphères sur mobile
        document.getElementById('prevSphere').addEventListener('click', () => {
            const prevIndex = (sphereManager.currentIndex - 1 + sphereManager.spheres.length) % sphereManager.spheres.length;
            sphereManager.navigateToSphere(prevIndex, 1000);
        });

        document.getElementById('nextSphere').addEventListener('click', () => {
            const nextIndex = (sphereManager.currentIndex + 1) % sphereManager.spheres.length;
            sphereManager.navigateToSphere(nextIndex, 1000);
        });

        animate();
    })
    .catch((err) => {
        console.error('Erreur lors du chargement des textures :', err);
    });

// Animation
function animate() {
    requestAnimationFrame(animate);
    controls.update(); // Assure la mise à jour des OrbitControls
    composer.render();
}

>>>>>>> main
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
<<<<<<< HEAD
=======
    composer.setSize(window.innerWidth, window.innerHeight);
>>>>>>> main
});