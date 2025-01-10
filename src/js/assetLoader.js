import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

console.log('THREE version:', THREE.REVISION);


// Fonction pour charger le modèle 3D et lui appliquer une couleur unie
export function load3DModel(path) {
    return new Promise((resolve, reject) => {
        const loader = new GLTFLoader();
        
        loader.load(
            path,
            (gltf) => {
                console.log("Modèle 3D chargé:", path);
                
                // Appliquer une couleur bleue au modèle 3D
                gltf.scene.traverse((child) => {
                    if (child.isMesh) {
                        // Appliquer un matériau bleu
                        child.material = new THREE.MeshBasicMaterial({ color: 0x0000ff });  // Bleu
                    }
                });
                
                resolve(gltf.scene);  // Retourne la scène du modèle 3D
            },
            undefined,  // Progress callback (si besoin)
            (error) => {
                console.error("Erreur lors du chargement du modèle:", error);
                reject(error);
            }
        );
    });
}


// Fonction pour charger une texture avec gestion d'encodage
export function loadTexture(url) {
    return new Promise((resolve, reject) => {
        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(
            url,
            (texture) => {
                // Appliquer l'encodage
                texture.encoding = 3001; // Utiliser la valeur numérique pour sRGBEncoding
                console.log(`Texture chargée depuis ${url}`, {
                    encoding: texture.encoding,
                    texture,
                });
                resolve(texture);
            },
            undefined,
            (err) => {
                console.error(`Erreur lors du chargement de la texture depuis ${url}`, err);
                reject(new Error(`Erreur critique lors du chargement de ${url}: ${err.message}`));
            }
        );
    });
}