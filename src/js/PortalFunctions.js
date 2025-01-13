//PortalFunctions.js

import * as THREE from 'three';
import { getAvailablePortals } from './portalManager';
import { getRandomPositionOnSphere } from './helpers';

// Fonction pour supprimer les anciens portails
function removePortals(scene) {
    if (scene && scene.children) {
        scene.children.forEach(function (child) {
            if (child.name && child.name.startsWith('portal_')) {
                scene.remove(child); // Enlever les objets qui sont des portails
                console.log(`Portail ${child.name} retiré de la scène.`);
            }
        });
    } else {
        console.warn("La scène est mal définie, impossible de supprimer les portails.");
    }
}

// Fonction pour repositionner les portails sur la sphère
function repositionPortals(interactiveAssets) {
    interactiveAssets.forEach(function (asset) {
        const newPosition = getRandomPositionOnSphere(500); // Obtenez une nouvelle position aléatoire sur la sphère
        asset.object.position.copy(newPosition); // Déplace le portail
        console.log(`Portail déplacé vers la nouvelle position : ${newPosition}`);
    });
}

function addStylizedPortals(scene, interactiveAssets, handlePortalClick, currentIndex) {
    if (!interactiveAssets) {
        console.error("interactiveAssets n'est pas défini.");
        return;
    }

    // Supprimer les anciens portails avant d'ajouter les nouveaux
    console.log("Avant de supprimer les portails, scène :", scene);
    removePortals(scene);

    // Récupérer les portails disponibles pour le monde actuel
    const availablePortals = getAvailablePortals(currentIndex);
    console.log(`Portails disponibles pour le monde ${currentIndex}:`, availablePortals);
    const selectedPortals = [];

    // Sélectionner les portails de la matrice (en respectant l'ordre)
    // Si le monde a 3 portails associés, on les ajoute dans l'ordre
    availablePortals.forEach(function (portalIndex) {
        selectedPortals.push(portalIndex);
    });
    console.log(`Portails sélectionnés pour le monde ${currentIndex}:`, selectedPortals);

    // Définir les textures pour les portails
    const textures = [
        new THREE.TextureLoader().load('./assets/images/blue-texture.png'),
        new THREE.TextureLoader().load('./assets/images/green-texture.png'),
        new THREE.TextureLoader().load('./assets/images/yellow-texture.png'),
        new THREE.TextureLoader().load('./assets/images/pink-texture.png'),
        new THREE.TextureLoader().load('./assets/images/orange-texture.png'),
        new THREE.TextureLoader().load('./assets/images/purple-texture.png')
    ];

    // Création des portails sélectionnés
    selectedPortals.forEach(function (portalIndex, i) {
        console.log(`Portail ${portalIndex} sélectionné avec l'indice ${portalIndex}`);
        let selectedTexture = textures[portalIndex];
        if (!selectedTexture) {
            console.warn(`Texture pour le portail ${portalIndex} non trouvée, utilisation de la texture de secours.`);
            selectedTexture = textures[0]; // Fallback à la première texture
        }

        // Log de la texture utilisée
        console.log(`Création du portail ${portalIndex} avec la texture: ${selectedTexture.image ? selectedTexture.image.src : 'aucune'}`);
        const radius = 20;
        const portalGeometry = new THREE.SphereGeometry(radius, 32, 32);
        const portalMaterial = new THREE.MeshBasicMaterial({
            map: selectedTexture,
            transparent: true,
            opacity: 1
        });
        const portal = new THREE.Mesh(portalGeometry, portalMaterial);
        const position = getRandomPositionOnSphere(500);
        portal.position.set(position.x, position.y, position.z);
        portal.name = `portal_${portalIndex}`;
        scene.add(portal);
        const portalLight = new THREE.PointLight(0x00ff00, 1, 100);
        portalLight.position.set(position.x, position.y, position.z);
        scene.add(portalLight);

        portal.onHover = function (isHovered) {
            if (isHovered) {
                document.body.style.cursor = 'pointer';
                portal.material.color.set(0xff0000);
            } else {
                document.body.style.cursor = 'auto';
                portal.material.color.set(0xffffff);
            }
        };

        portal.onClick = function () {
            handlePortalClick(portalIndex);
            repositionPortals(interactiveAssets);
        };

        interactiveAssets.push({
            object: portal,
            onHover: portal.onHover,
            onClick: portal.onClick
        });
        console.log(`Portail ${portalIndex} ajouté à la scène`);
    });
}

export { addStylizedPortals, removePortals };