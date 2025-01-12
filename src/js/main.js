import * as THREE from 'three';
import TWEEN from '@tweenjs/tween.js';
import { loadTexture } from '@js/assetLoader.js';
import { SphereManager } from '@js/sphereManager.js';
import { InteractionManager } from '@js/interactionManager.js';
import { addStylizedPortals } from './PortalFunctions.js';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { BrightnessContrastShader } from 'three/examples/jsm/shaders/BrightnessContrastShader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

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
    `${basePath}artwork-final-V1.jpg`,
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

window.addEventListener('mousemove', (event) => {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
});

window.addEventListener('click', handleMouseClick);

// Ajouter un gestionnaire pour le tap sur mobile
window.addEventListener('touchstart', handleTouchStart);

function handleTouchStart(event) {
    // Prévenir la propagation de l'événement pour éviter toute interaction non souhaitée
    event.preventDefault(); 
    handleMouseClick(event); // Utiliser la même fonction pour gérer le clic ou le tap
}

// Postprocessing
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const brightnessContrastPass = new ShaderPass(BrightnessContrastShader);
brightnessContrastPass.uniforms.brightness.value = 0.0;
brightnessContrastPass.uniforms.contrast.value = 0.0;
composer.addPass(brightnessContrastPass);

// Raycaster & mouse interaction
let sphereManager;

function initialize() {
    loadTextures(texturePaths)
        .then((loadedTextures) => {
            console.log('Textures chargées:', loadedTextures);
            sphereManager = initializeSpheres(loadedTextures); 
            const interactionManager = new InteractionManager(camera, renderer, sphereManager, interactiveAssets); 
            animate(interactionManager);
        })
        .catch((err) => {
            console.error('Erreur lors du chargement des textures :', err);
        });
}

function loadTextures(paths) {
    return Promise.all(paths.map(loadTexture))
        .then(loadedTextures => {
            console.log("Textures chargées:", loadedTextures);
            return loadedTextures;
        })
        .catch(err => {
            console.error('Erreur lors du chargement des textures:', err);
            throw err;
        });
}

function initializeSpheres(loadedTextures) {
    const sphereManager = new SphereManager(scene, loadedTextures, renderer);
    sphereManager.createSpheres(); 
    addStylizedPortals(scene, interactiveAssets, handlePortalClick); 
    return sphereManager;
}

function handlePortalClick(index) {
    console.log(`Portail ${index} cliqué. Téléportation...`);
    if (sphereManager) {
        sphereManager.navigateToSphere((index + 1) % sphereManager.spheres.length, 1000); 
    } else {
        console.error('sphereManager n\'est pas défini. Impossible de naviguer vers la sphère.');
    }
}

function animate(interactionManager) {
    requestAnimationFrame(() => animate(interactionManager));

    controls.update();
    interactionManager.update();

    TWEEN.update();

    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveAssets.map(asset => asset.object), true);

    interactiveAssets.forEach((asset) => {
        const isHovered = intersects.some((intersect) => intersect.object === asset.object || asset.object?.children?.includes(intersect.object));
        asset.onHover(isHovered);
    });

    composer.render();
}

function handleMouseClick() {
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(interactiveAssets.map(asset => asset.object), true);
    console.log('Objets détectés :', intersects);

    if (intersects.length > 0) {
        const clickedObject = intersects[0].object;
        console.log('Objet cliqué :', clickedObject);

        const interactiveAsset = interactiveAssets.find((asset) => asset.object === clickedObject);

        if (interactiveAsset) {
            console.log('Asset interactif cliqué :', interactiveAsset);
            interactiveAsset.onClick();
        }
    }
}

initialize();