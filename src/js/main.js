import * as THREE from 'three';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';
import { InteractionManager } from '@js/interactionManager.js';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';

// Détection des environnements
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const isProd = !isLocal;

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
renderer.setClearColor(0x000000, 1); // Fond noir
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

// Postprocessing
const composer = new EffectComposer(renderer);
const renderPass = new RenderPass(scene, camera);
composer.addPass(renderPass);

const brightnessContrastPass = new ShaderPass(BrightnessContrastShader);
brightnessContrastPass.uniforms.brightness.value = 0.0; // Ajuste la luminosité
brightnessContrastPass.uniforms.contrast.value = 0.0; // Ajuste le contraste
composer.addPass(brightnessContrastPass);

// Charger les textures et initialiser les sphères
Promise.all(texturePaths.map(loadTexture))
    .then((loadedTextures) => {
        const sphereManager = new SphereManager(scene, loadedTextures, renderer);
        sphereManager.createSpheres();

        // Initialiser le gestionnaire d'interactions
        const interactionManager = new InteractionManager(camera, renderer, sphereManager);
        interactionManager.initializeInteractions();

        animate(interactionManager); // Passer l'InteractionManager à la boucle d'animation
    })
    .catch((err) => {
        console.error('Erreur lors du chargement des textures :', err);
    });

// Boucle d'animation
function animate(interactionManager) {
    requestAnimationFrame(() => animate(interactionManager));
    interactionManager.update(); // Mise à jour des OrbitControls via InteractionManager
    composer.render(); // Utilise le composer pour le rendu
}

// Gestion du redimensionnement
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    composer.setSize(window.innerWidth, window.innerHeight);
});