import * as THREE from 'three';

export class SphereManager {
    constructor(scene, textures) {
        this.scene = scene;
        this.textures = textures;
        this.spheres = [];
        this.currentIndex = 0;
    }

    createSpheres() {
        const sphereGeometry = new THREE.SphereGeometry(500, 60, 40);
        sphereGeometry.scale(-1, 1, 1); // Vue interne

        this.spheres = this.textures.map((texture, index) => {
            const material = new THREE.MeshBasicMaterial({
                map: texture,
                transparent: true,
                opacity: index === 0 ? 1 : 0, // La première texture est visible
            });
            material.renderOrder = index;
            const sphere = new THREE.Mesh(sphereGeometry, material);
            this.scene.add(sphere);
            return sphere;
        });
    }

    crossfadeTransition(duration) {
        const startTime = Date.now();
        const nextIndex = (this.currentIndex + 1) % this.textures.length;

        const animateFade = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);

            this.spheres[this.currentIndex].material.opacity = 1 - progress;
            this.spheres[nextIndex].material.opacity = progress;

            if (progress < 1) {
                requestAnimationFrame(animateFade);
            } else {
                this.currentIndex = nextIndex;
                console.log(`Transition terminée vers la texture ${this.currentIndex}`);
            }
        };

        animateFade();
    }
}