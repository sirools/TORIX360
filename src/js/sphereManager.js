// Dans sphereManager.js

import * as THREE from 'three';

export class SphereManager {
    constructor(scene, textures, renderer) {
        this.scene = scene;
        this.textures = textures;
        this.renderer = renderer;
        this.spheres = [];
        this.currentIndex = 0;
        this.adjacencyMatrix = []; // Matrice d'adjacence pour les connexions logiques
        this.sphereGeometry = new THREE.SphereGeometry(500, 60, 40);
        this.sphereGeometry.scale(-1, 1, 1); // Vue interne
    }

    createSpheres() {
        // Charger les textures avant de les utiliser
        const texture1 = new THREE.TextureLoader().load('./assets/images/artwork1.jpg');
        const texture2 = new THREE.TextureLoader().load('./assets/images/artwork2.jpg');
        const texture3 = new THREE.TextureLoader().load('./assets/images/artwork3.jpg');
        const texture4 = new THREE.TextureLoader().load('./assets/images/artwork4.jpg');
        const texture5 = new THREE.TextureLoader().load('./assets/images/artwork5.jpg');
        const texture6 = new THREE.TextureLoader().load('./assets/images/artwork-final-V1.jpg');

        // Tableau des textures
        const newTextures = [texture1, texture2, texture3, texture4, texture5, texture6];

        this.spheres = newTextures.map((texture, index) => {
            const material = new THREE.MeshBasicMaterial({
                map: texture,
                transparent: true,
                opacity: index === 0 ? 1 : 0, // La première texture est visible
            });

            material.renderOrder = index; // On garde l'ordre de rendu basé sur l'index

            const sphere = new THREE.Mesh(this.sphereGeometry, material);
            this.scene.add(sphere);

            console.log(`Sphère ${index} créée avec texture :`, texture);
            return sphere;
        });
    }

    navigateToSphere(nextIndex, duration) {
        if (this.spheres[nextIndex]) {
            console.log(`Navigation vers la sphère ${nextIndex}`);
            this.crossfadeTransition(duration, nextIndex);
        } else {
            console.warn(`Aucune sphère à l'indice ${nextIndex}`);
        }
    }

    crossfadeTransition(duration, nextIndex) {
        const startTime = Date.now();
        const animateFade = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const easedProgress = SphereManager.easeInOut(progress);

            this.updateSphereOpacity(this.currentIndex, 1 - easedProgress);
            this.updateSphereOpacity(nextIndex, easedProgress);

            if (progress < 1) {
                requestAnimationFrame(animateFade);
            } else {
                this.currentIndex = nextIndex;
                console.log(`Transition terminée vers la sphère ${this.currentIndex}`);
            }
        };

        animateFade();
    }

    updateSphereOpacity(index, opacity) {
        if (this.spheres[index]) {
            this.spheres[index].material.opacity = opacity;
        } else {
            console.warn(`Sphère à l'indice ${index} introuvable.`);
        }
    }

    static easeInOut(t) {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
    }
}