import * as THREE from 'three';
import TWEEN from '@tweenjs/tween.js';

import '../styles/main.css'; // Assure-toi que ce chemin est correct

import { InteractionManager } from './interactionManager.js';
import { SphereManager } from './sphereManager.js';
import { addStylizedPortals } from './PortalFunctions.js';
import { showInterstitial, hideInterstitial } from './interstitialComponent.js';
import { loadTexture } from './assetLoader.js';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

console.log('Code exécuté');

// Constantes de l'environnement
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const isProd = !isLocal;
const basePath = isProd ? '/TORIX360/dist/assets/images/' : './assets/images/';
let interactiveAssets = []; // Tableau des assets interactifs

const texturePaths = [
    `${basePath}artwork1.jpg`,
    `${basePath}artwork2.jpg`,
    `${basePath}artwork3.jpg`,
    `${basePath}artwork4.jpg`,
    `${basePath}artwork5.jpg`,
    `${basePath}artwork-final-V1.jpg`
];

console.log("Texte des textures:", texturePaths);

// Configuration Three.js
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1);
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.25;
controls.screenSpacePanning = true;
controls.maxDistance = 500;
controls.minDistance = 100;

const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
directionalLight.position.set(0, 500, 500);
scene.add(directionalLight);

const pointLight = new THREE.PointLight(0xffffff, 1, 1000);
pointLight.position.set(0, -500, 0);
scene.add(pointLight);

const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
window.addEventListener('mousemove', function(event) {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
});
window.addEventListener('click', handleMouseClick);

// Ajouter un gestionnaire pour le tap sur mobile
window.addEventListener('touchstart', handleTouchStart);

function handleTouchStart(event) {
    event.preventDefault();
    handleMouseClick(event); // Utiliser la même fonction pour gérer le clic ou le tap
}

// Fonction pour adapter la taille du canvas lors du redimensionnement de la fenêtre
window.addEventListener('resize', function() {
    const width = window.innerWidth;
    const height = window.innerHeight;

    // Mettre à jour la taille du renderer
    renderer.setSize(width, height);

    // Mettre à jour le ratio de la caméra pour le redimensionnement
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
});

// Postprocessing
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const brightnessContrastPass = new ShaderPass(BrightnessContrastShader);
brightnessContrastPass.uniforms.brightness.value = 0.0;
brightnessContrastPass.uniforms.contrast.value = 0.0;
composer.addPass(brightnessContrastPass);

// Raycaster & mouse interaction
let sphereManager;
let currentIndex = 0; // Initialisation de l'index du monde actuel

function initialize() {
    loadTextures(texturePaths)
        .then(function(loadedTextures) {
            console.log('Textures chargées:', loadedTextures);
            sphereManager = initializeSpheres(loadedTextures);
            const interactionManager = new InteractionManager(camera, renderer, sphereManager, interactiveAssets);
            animate(interactionManager);
        })
        .catch(function(err) {
            console.error('Erreur lors du chargement des textures :', err);
        });
}

function loadTextures(paths) {
    return Promise.all(paths.map(loadTexture))
        .then(function(loadedTextures) {
            console.log("Textures chargées:", loadedTextures);
            return loadedTextures;
        })
        .catch(function(err) {
            console.error('Erreur lors du chargement des textures:', err);
            throw err;
        });
}

function initializeSpheres(loadedTextures) {
    const sphereManager = new SphereManager(scene, loadedTextures, renderer);
    sphereManager.createSpheres();
    if (typeof currentIndex === 'undefined') {
        console.error('currentIndex is undefined');
    } else {
        addStylizedPortals(scene, interactiveAssets, handlePortalClick, currentIndex);
    }
    return sphereManager;
}

let currentWorldIndex = 0; // Indice du monde actuel, à ajuster lors des transitions

function handlePortalClick(index) {
    console.log(`Portail ${index} cliqué. Téléportation...`);

    // Mettre à jour l'index du monde actuel
    currentIndex = index;

    // Transition vers la nouvelle sphère
    sphereManager.navigateToSphere(index, 1000); // Navigation avec un délai de 1000 ms

    // Afficher l'interstitiel correspondant à la nouvelle sphère
    showInterstitial(currentIndex);

    // Appeler addStylizedPortals avec le bon index pour le monde actuel
    addStylizedPortals(scene, interactiveAssets, handlePortalClick, currentIndex);
}

// Lors de l'initialisation, tu peux afficher l'interstitiel du premier monde
showInterstitial(currentWorldIndex);
document.getElementById("interstitial-close").addEventListener("click", function() {
    hideInterstitial(); // Masquer l'interstitiel quand le bouton est cliqué
});

let isAnimating = false; // Ajouter un état pour vérifier si l'animation doit continuer

function animate(interactionManager) {
    if (isAnimating) return; // Si déjà en animation, on ne fait rien

    isAnimating = true; // Marque l'animation comme en cours
    requestAnimationFrame(function() {
        return animate(interactionManager);
    }); // Demande une nouvelle animation

    controls.update();
    interactionManager.update();
    _tweenjs_tween_js__WEBPACK_IMPORTED_MODULE_0__["default"].update();
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveAssets.map(function(asset) {
        return asset.object;
    }), true);
    interactiveAssets.forEach(function(asset) {
        const isHovered = intersects.some(function(intersect) {
            return intersect.object === asset.object || (asset.object?.children?.includes(intersect.object));
        });
        asset.onHover(isHovered);
    });
    composer.render();
    isAnimating = false; // L'animation est terminée
}

function handleMouseClick() {
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveAssets.map(function(asset) {
        return asset.object;
    }), true);
    console.log('Objets détectés :', intersects);
    if (intersects.length > 0) {
        const clickedObject = intersects[0].object;
        console.log('Objet cliqué :', clickedObject);
        const interactiveAsset = interactiveAssets.find(function(asset) {
            return asset.object === clickedObject;
        });
        if (interactiveAsset) {
            console.log('Asset interactif cliqué :', interactiveAsset);
            interactiveAsset.onClick();
        }
    }
}
initialize();