import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';

// Postprocessing
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';

// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
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

// Définir la base des chemins
const basePath = isLocal ? './assets/images/' : './TORIX360/assets/images/';

// Tableau des chemins des textures
const texturePaths = [
    `${basePath}artwork1.jpg`,
    `${basePath}artwork2.jpg`,
    `${basePath}artwork3.jpg`,
    `${basePath}artwork4.jpg`,
    `${basePath}artwork-final-V1.jpg`,
];

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

window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    composer.setSize(window.innerWidth, window.innerHeight);
});