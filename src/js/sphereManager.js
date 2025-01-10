import * as THREE from 'three';

export class SphereManager {
    constructor(scene, textures, renderer) {
        this.scene = scene;
        this.textures = textures;
        this.renderer = renderer;
        this.spheres = [];
        this.currentIndex = 0;
    }

    createSpheres() {
        this.spheres = this.textures.map((texture, index) => {
            const material = new THREE.MeshBasicMaterial({
                map: texture,
                transparent: true,
                opacity: index === 0 ? 1 : 0,
            });
            const sphere = new THREE.Mesh(new THREE.SphereGeometry(500, 60, 40), material);
            sphere.geometry.scale(-1, 1, 1);
            this.scene.add(sphere);
            return sphere;
        });
    }
}