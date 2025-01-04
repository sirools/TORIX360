import * as THREE from 'three';
import { SphereManager } from './sphereManager';
import { TransitionManager } from './transitionManager';
import { InteractionManager } from './interactionManager';
import { AssetLoader } from './assetLoader';

// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
camera.fov = 50;
camera.updateProjectionMatrix();

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Gestion des assets
const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
const basePath = isLocal ? './' : './dist/';
const assetLoader = new AssetLoader(basePath);

assetLoader
    .loadTextures(['assets/images/artwork1.jpg', 'assets/images/artwork2.jpg', 'assets/images/artwork3.jpg'])
    .then((textures) => {
        console.log('Textures chargées');

        // Gérer les sphères
        const sphereManager = new SphereManager(scene, textures);
        sphereManager.createSpheres();

        // Gérer les transitions
        const transitionManager = new TransitionManager(sphereManager, 1000);
        transitionManager.startAutoTransition(10000);

        // Gérer les interactions
        const interactionManager = new InteractionManager(camera, renderer);

        // Animation
        function animate() {
            interactionManager.update();
            renderer.render(scene, camera);
            requestAnimationFrame(animate);
        }
        animate();

        // Redimensionnement
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
    })
    .catch((err) => {
        console.error('Erreur lors du chargement des textures :', err);
    });