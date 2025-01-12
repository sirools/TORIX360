export class TransitionManager {
    constructor(sphereManager, duration) {
        this.sphereManager = sphereManager; // Référence à SphereManager pour gérer les sphères
        this.duration = duration; // Durée de la transition
    }

    // Méthode pour démarrer une transition automatique entre les sphères
    startAutoTransition(interval) {
        // Cette fonction va appeler la transition entre les sphères à intervalles réguliers
        setInterval(() => {
            this.sphereManager.crossfadeTransition(this.duration); // Appel à la méthode de transition fluide dans SphereManager
        }, interval); // L'intervalle définit à quelle fréquence la transition doit avoir lieu
    }

    // Méthode pour déclencher une transition manuelle à partir d'un portail
    startManualTransition(nextIndex) {
        // Transition manuelle lorsque l'utilisateur interagit avec un portail
        console.log(`Transition manuelle vers la sphère ${nextIndex}`);
        this.sphereManager.navigateToSphere(nextIndex, this.duration); // On navigue vers la sphère suivante
    }
}