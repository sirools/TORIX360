import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

export class InteractionManager {
    constructor(camera, renderer, sphereManager) {
        // Initialisation des OrbitControls
        this.controls = new OrbitControls(camera, renderer.domElement);
        this.initControls();

        // Stocker le sphereManager pour la navigation
        this.sphereManager = sphereManager;
    }

    initControls() {
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.minDistance = 10;
        this.controls.maxDistance = 480;
        this.controls.zoomSpeed = 2;
    }

    initializeInteractions() {
        // Gestion des touches clavier
        document.addEventListener('keydown', (event) => {
            if (event.key === 'ArrowRight') {
                this.navigateToNextSphere();
            } else if (event.key === 'ArrowLeft') {
                this.navigateToPrevSphere();
            }
        });

        // Gestion des clics sur les boutons
        const prevButton = document.getElementById('prevSphere');
        const nextButton = document.getElementById('nextSphere');

        if (prevButton) {
            prevButton.addEventListener('click', () => this.navigateToPrevSphere());
        }

        if (nextButton) {
            nextButton.addEventListener('click', () => this.navigateToNextSphere());
        }
    }

    navigateToNextSphere() {
        if (!this.sphereManager) return;

        const nextIndex = (this.sphereManager.currentIndex + 1) % this.sphereManager.spheres.length;
        this.sphereManager.navigateToSphere(nextIndex, 1000);
    }

    navigateToPrevSphere() {
        if (!this.sphereManager) return;

        const prevIndex = (this.sphereManager.currentIndex - 1 + this.sphereManager.spheres.length) % this.sphereManager.spheres.length;
        this.sphereManager.navigateToSphere(prevIndex, 1000);
    }

    update() {
        // Mise à jour des OrbitControls
        this.controls.update();
    }
}