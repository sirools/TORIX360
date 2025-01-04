export class TransitionManager {
    constructor(sphereManager, duration) {
        this.sphereManager = sphereManager;
        this.duration = duration;
    }

    startAutoTransition(interval) {
        setInterval(() => {
            this.sphereManager.crossfadeTransition(this.duration);
        }, interval);
    }
}