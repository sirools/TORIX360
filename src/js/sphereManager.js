import * as THREE from 'three';

export class SphereManager {
    constructor(scene, textures) {
        this.scene = scene;
        this.textures = textures;
        this.spheres = [];
        this.currentIndex = 0;
        this.adjacencyMatrix = []; // Matrice d'adjacence pour les connexions logiques
        this.sphereGeometry = new THREE.SphereGeometry(500, 60, 40);
        this.sphereGeometry.scale(-1, 1, 1); // Vue interne
    }

    createSpheres() {
        this.spheres = this.textures.map((texture, index) => {
            const material = new THREE.MeshBasicMaterial({
                map: texture,
                transparent: true,
                opacity: index === 0 ? 1 : 0, // La première texture est visible
            });

            // Ajoutez un log pour confirmer :
            console.log(`Material ${index}:`, material);

            material.renderOrder = index;
            const sphere = new THREE.Mesh(this.sphereGeometry, material);
            this.scene.add(sphere);

            // Log pour vérifier le matériau utilisé
            console.log(`Sphere ${index} material:`, material);

            return sphere;
        });

        // Forcer l'opacité de la première sphère à 100%
        this.updateSphereOpacity(0, 1);

        // Vérification et log de l'opacité de la première sphère
        if (this.spheres[0]) {
            console.log(
                'Opacité actuelle de la sphère 0 après création:',
                this.spheres[0].material.opacity
            );
        }
    }

    updateSphereOpacity(index, opacity) {
        if (this.spheres[index]) {
            this.spheres[index].material.opacity = opacity;
        } else {
            console.warn(`Sphère à l'indice ${index} introuvable.`);
        }
    }

    // Fonction easing
    static easeInOut(t) {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
    }

    crossfadeTransition(duration) {
        const startTime = Date.now();
        const nextIndex = (this.currentIndex + 1) % this.spheres.length;

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
                console.log(`Transition terminée vers la texture ${this.currentIndex}`);
            }
        };

        animateFade();
    }

    setAdjacencyMatrix(matrix) {
        this.adjacencyMatrix = matrix;
    }

    getNextSphereIndices() {
        return this.adjacencyMatrix[this.currentIndex] || [];
    }

    navigateToSphere(nextIndex, duration) {
        if (this.spheres[nextIndex]) {
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
                    console.log(`Navigué vers la sphère ${this.currentIndex}`);
                }
            };

            animateFade();
        } else {
            console.warn(`Aucune sphère à l'indice ${nextIndex}`);
        }
    }
}