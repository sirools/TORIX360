import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

export class InteractionManager {
    constructor(camera, renderer) {
        this.controls = new OrbitControls(camera, renderer.domElement);
        this.initControls();
    }

    initControls() {
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.minDistance = 10;
        this.controls.maxDistance = 480;
        this.controls.zoomSpeed = 2;
    }

    update() {
        this.controls.update();
    }
}