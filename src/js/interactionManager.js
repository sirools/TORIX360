import * as THREE from 'three';

class InteractionManager {
    constructor(camera, renderer, sphereManager, portals) {
        this.camera = camera;
        this.renderer = renderer;
        this.sphereManager = sphereManager;
        this.portals = portals; // Remplacer interactiveAssets par portals
        this.raycaster = new THREE.Raycaster();
        this.mouse = new THREE.Vector2();
        this.setupEventListeners();
        this.previousHoveredPortal = null; // Pour éviter plusieurs appels successifs pendant le survol
    }

    // Gestion des événements de souris
    setupEventListeners() {
        window.addEventListener('mousemove', this.onMouseMove.bind(this));
        window.addEventListener('click', this.handleMouseClick.bind(this));
    }

    // Met à jour la position de la souris
    onMouseMove(event) {
        this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
    }

    // Gestion des clics
    handleMouseClick() {
        this.raycaster.setFromCamera(this.mouse, this.camera);
        const intersects = this.raycaster.intersectObjects(this.portals.map(function(portal) {
            return portal.object;
        }), true);
        if (intersects.length > 0) {
            const clickedObject = intersects[0].object;
            console.log('Portail cliqué :', clickedObject);

            // Vérifier que le portail est bien interactif
            const clickedPortal = this.portals.find(function(portal) {
                return portal.object === clickedObject && portal.interactive;
            });
            if (clickedPortal) {
                console.log('Portail interactif cliqué :', clickedPortal);
                clickedPortal.onClick(); // Appel de la méthode onClick du portail
            } else {
                // console.warn('Clic détecté sur un objet non interactif :', clickedObject);
            }
        } else {
            // console.warn('Aucun objet détecté sous le clic.');
        }
    }

    // Gestion du survol
    update() {
        const _this = this;
        this.raycaster.setFromCamera(this.mouse, this.camera);
        const intersects = this.raycaster.intersectObjects(this.portals.map(function(portal) {
            return portal.object;
        }), true);
        this.portals.forEach(function(portal) {
            const isHovered = intersects.some(function(intersect) {
                return intersect.object === portal.object;
            });

            // Si l'état de survol change, on enregistre le survol et anime la sphère
            if (isHovered && _this.previousHoveredPortal !== portal) {
                console.log("Hovered on portal");
                portal.onHover(true); // Animations sur hover
                _this.previousHoveredPortal = portal;
            } else if (!isHovered && _this.previousHoveredPortal === portal) {
                portal.onHover(false); // Restaure la taille
                _this.previousHoveredPortal = null;
            }
        });
    }
}

export { InteractionManager };