import * as THREE from 'three';
import { loadTexture } from '@js/assetLoader.js';
import { load3DModel } from './assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';
import { InteractionManager } from '@js/interactionManager.js';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';
import { Interactive3DAsset } from './interactive3DAsset.js';

// Constantes de l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const isProd = !isLocal;
const basePath = isProd ? '/TORIX360/dist/assets/images/' : './assets/images/';

// Tableau des textures
const texturePaths = [
    `${basePath}artwork1.jpg`,
    `${basePath}artwork2.jpg`,
    `${basePath}artwork3.jpg`,
    `${basePath}artwork4.jpg`,
    `${basePath}artwork5.jpg`,
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

// Postprocessing
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const brightnessContrastPass = new ShaderPass(BrightnessContrastShader);
brightnessContrastPass.uniforms.brightness.value = 0.0;
brightnessContrastPass.uniforms.contrast.value = 0.0;
composer.addPass(brightnessContrastPass);

// Fonction principale pour démarrer le projet
function initialize() {
    // Charger les textures et initialiser la scène
    loadTextures(texturePaths)
        .then(loadedTextures => {
            const sphereManager = initializeSpheres(loadedTextures);
            const interactionManager = new InteractionManager(camera, renderer, sphereManager);
            interactionManager.initializeInteractions();
            loadAndPosition3DAssets();
            animate(interactionManager);
        })
        .catch(err => {
            console.error('Erreur lors du chargement des textures :', err);
        });
}

// Charger les textures
function loadTextures(paths) {
    return Promise.all(paths.map(loadTexture));
}

// Créer et positionner les sphères dans la scène
function initializeSpheres(loadedTextures) {
    const sphereManager = new SphereManager(scene, loadedTextures, renderer);
    sphereManager.createSpheres();
    return sphereManager;
}

// Charger et positionner les modèles 3D dans la scène
function loadAndPosition3DAssets() {
    const modelPaths = ['./assets/models/champagne.gltf', './assets/models/pearl.gltf'];
    const radius = 500;
    const numObjects = 2;
    const angleStep = Math.PI * 2 / numObjects;
    const verticalAngleStep = Math.PI / 3;

    modelPaths.forEach((path, index) => {
        load3DModel(path).then((model) => {
            const angle = angleStep * index;
            const verticalAngle = (index % 2 === 0 ? verticalAngleStep : -verticalAngleStep); // Alternance de la position verticale

            model.position.set(
                radius * Math.cos(angle) * Math.cos(verticalAngle),
                radius * Math.sin(verticalAngle),
                radius * Math.sin(angle) * Math.cos(verticalAngle)
            );

            model.scale.set(50, 50, 50);
            scene.add(model);
        }).catch((error) => {
            console.error(`Erreur lors du chargement du modèle ${path}:`, error);
        });
    });
}

// Boucle d'animation
function animate(interactionManager) {
    requestAnimationFrame(() => animate(interactionManager));
    interactionManager.update();
    composer.render();
}

// Gestion du redimensionnement
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    composer.setSize(window.innerWidth, window.innerHeight);
});

// Lancer l'application
initialize();