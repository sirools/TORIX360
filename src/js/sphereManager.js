import * as THREE from 'three';

export class SphereManager {
    constructor(scene, textures, renderer) {
        this.scene = scene;
        this.textures = textures;
        this.renderer = renderer;
        this.spheres = [];
        this.currentIndex = 0;
        this.adjacencyMatrix = [];
        this.sphereGeometry = new THREE.SphereGeometry(500, 60, 40);
        this.sphereGeometry.scale(-1, 1, 1);
    }

    createSpheres() {
        this.spheres = this.textures.map((texture, index) => {
            const material = new THREE.MeshBasicMaterial({
                map: texture,
                transparent: true,
                opacity: index === 0 ? 1 : 0,
            });
            material.renderOrder = index;
            const sphere = new THREE.Mesh(this.sphereGeometry, material);
            this.scene.add(sphere);
            return sphere;
        });
    }

    updateSphereOpacity(index, opacity) {
        if (this.spheres[index]) {
            this.spheres[index].material.opacity = opacity;
        }
    }

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
            this.crossfadeTransition(duration);
        }
    }
}