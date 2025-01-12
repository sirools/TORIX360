import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

console.log('THREE version:', THREE.REVISION);


// Fonction pour charger le modèle 3D et lui appliquer une couleur unie
// export function load3DModel(path) {
//     return new Promise((resolve, reject) => {
//         const loader = new GLTFLoader();
        
//         loader.load(
//             path,
//             (gltf) => {
//                 console.log("Modèle 3D chargé:", path);
                
//                 // Appliquer une couleur bleue au modèle 3D
//                 gltf.scene.traverse((child) => {
//                     if (child.isMesh) {
//                         // Appliquer un matériau bleu
//                         child.material = new THREE.MeshBasicMaterial({ color: 0x0000ff });  // Bleu
//                     }
//                 });
                
//                 resolve(gltf.scene);  // Retourne la scène du modèle 3D
//             },
//             undefined,  // Progress callback (si besoin)
//             (error) => {
//                 console.error("Erreur lors du chargement du modèle:", error);
//                 reject(error);
//             }
//         );
//     });
// }


// Fonction pour charger une texture avec gestion d'encodage
export function loadTexture(path) {
    return new Promise((resolve, reject) => {
        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(
            path,
            (texture) => resolve(texture),  // Si la texture est chargée, on la renvoie
            undefined,
            (err) => reject(`Erreur de chargement de la texture ${path}: ${err}`)  // Gestion d'erreur
        );
    });
}