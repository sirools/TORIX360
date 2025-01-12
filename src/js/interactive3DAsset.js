// import * as THREE from 'three'; // Si tu n'utilises plus cette dépendance, tu peux aussi la supprimer

// export class Interactive3DAsset {
//     constructor(path, radius, scale, texture, onTransition, scene) {
//         this.path = path;
//         this.radius = radius;
//         this.scale = scale;
//         this.texture = texture;
//         this.onTransition = onTransition;
//         this.scene = scene;
//         this.object = null; // Objet 3D que l'on va charger
//     }

//     // Méthode pour charger le modèle 3D
//     loadModel() {
//         // Logique de chargement du modèle 3D avec GLTFLoader, par exemple
//         console.log('Chargement du modèle 3D à partir de:', this.path);
//     }

//     // Méthode de gestion du survol
//     onHover(isHovered) {
//         // Logique pour gérer visuellement le survol
//         console.log('Survol de l\'objet:', isHovered);
//     }

//     // Méthode de gestion du clic
//     onClick() {
//         // Logique pour gérer le clic sur l'asset
//         console.log('Clic détecté sur l\'asset 3D');
//     }
// }