import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

// Configuration de base
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.z = 480;
camera.fov = 50;
camera.updateProjectionMatrix();

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

// Ajout d'une géométrie simple
const geometry = new THREE.BoxGeometry();
const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
const cube = new THREE.Mesh(geometry, material);
scene.add(cube);



// GESTION DES TEXTURES
const textureLoader = new THREE.TextureLoader();
const textures = [];

    // Charger les textures avec mipmapping
    function loadTexture(url) {
        return new Promise((resolve, reject) => {
            textureLoader.load(
                url,
                (texture) => {
                    texture.minFilter = THREE.LinearMipMapLinearFilter; // Mipmapping
                    texture.magFilter = THREE.LinearFilter;
                    resolve(texture);
                },
                undefined,
                (err) => {
                    console.error(`Erreur de chargement pour ${url}`, err);
                    reject(err);
                }
            );
        });
    }

    // Charger toutes les textures
    Promise.all([
        loadTexture('./dist/assets/images/artwork1.jpg'),
        loadTexture('./dist/assets/images/artwork2.jpg'),
        loadTexture('./dist/assets/images/artwork3.jpg'),
        loadTexture('./dist/assets/images/artwork4.jpg'),
    ]).then((loadedTextures) => {
        loadedTextures.forEach((texture, index) => {
            textures[index] = texture;
            console.log(`Texture ${index} chargée`);
        });
        startScene();
    }).catch((err) => {
        console.error("Erreur lors du chargement des textures :", err);
    });

// Variables globales
let currentIndex = 0;


// DECLARATION DES SPHERES
function startScene() {
    const sphereGeometry = new THREE.SphereGeometry(500, 60, 40);
    sphereGeometry.scale(-1, 1, 1); // Vue interne

    const materials = textures.map((texture, index) => {
        const material = new THREE.MeshBasicMaterial({
            map: texture,
            transparent: true,
            opacity: index === 0 ? 1 : 0, // La première texture est visible
        });
        material.renderOrder = index; // Priorité de rendu
        return material;
    });

    const spheres = materials.map((material) => {
        const sphere = new THREE.Mesh(sphereGeometry, material);
        sphere.renderOrder = material.renderOrder; // Assurer un rendu correct
        scene.add(sphere);
        return sphere;
    });


    // Fonction de fondu croisé
    function fadeTexturesCrossfade(duration) {
        const startTime = Date.now();
        const nextIndex = (currentIndex + 1) % textures.length;

        function animateFade() {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);

            materials[currentIndex].opacity = 1 - progress;
            materials[nextIndex].opacity = progress;

            if (progress < 1) {
                requestAnimationFrame(animateFade);
            } else {
                currentIndex = nextIndex;
                console.log(`Transition terminée vers la texture ${currentIndex}`);
            }
        }

        animateFade();
    }

    // Déclencher le fondu toutes les 10 secondes
    setInterval(() => {
        fadeTexturesCrossfade(1000); // Durée du fondu : 1 seconde
    }, 10000);






// Initialisation des OrbitControls
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true; // Ajoute un effet d'inertie
controls.dampingFactor = 0.05;
controls.minDistance = 10;
controls.maxDistance = 480;
controls.zoomSpeed = 2;




// Animation
function animate() {
    requestAnimationFrame(animate);
    controls.update(); // Nécessaire pour les OrbitControls
    renderer.render(scene, camera);
}
animate();

// Ajuster la taille au redimensionnement de la fenêtre
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
}
