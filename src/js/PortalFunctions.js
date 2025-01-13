// PortalFunctions.js

import * as THREE from 'three';
import { getRandomPositionOnSphere, changePortalColor, animatePortalScale } from './helpers.js';
import { portalMatrix, getRandomPortal } from './portalManager';  // Importation correcte de la matrice et des fonctions
import { getAvailablePortals } from './portalManager';  // Assurez-vous que le chemin d'importation est correct

// Fonction pour supprimer les anciens portails
export function removePortals(scene) {
    if (!(scene instanceof THREE.Scene)) {
        console.error("L'objet passé n'est pas une instance de THREE.Scene !");
        return;  // Sortir de la fonction si ce n'est pas une scène valide
    }

    console.log("La scène est prête, suppression des portails...");

    // On traverse tous les enfants de la scène pour trouver les portails
    scene.traverse((child) => {
        if (child.isMesh && child.name.startsWith('portal')) {
            scene.remove(child);
            console.log(`Portail supprimé: ${child.name}`);
        }
    });
}

// Fonction pour relancer la position aléatoire des portails après chaque clic
function repositionPortals(interactiveAssets) {
    // Pour chaque portail, on lui attribue une nouvelle position aléatoire
    interactiveAssets.forEach(asset => {
        const newPosition = getRandomPositionOnSphere(500);
        asset.object.position.set(newPosition.x, newPosition.y, newPosition.z);
        console.log(`Portail déplacé vers la nouvelle position : ${newPosition}`);
    });
}

// Fonction pour ajouter des portails stylisés dans la scène
export function addStylizedPortals(scene, interactiveAssets, handlePortalClick, currentIndex) {
    if (!interactiveAssets) {
        console.error("interactiveAssets n'est pas défini.");
        return;
    }

    // Supprimer les anciens portails avant d'ajouter de nouveaux
    removePortals(scene);

    // Récupère les portails disponibles pour le monde actuel
    const availablePortals = getAvailablePortals(currentIndex);
    console.log("Portails disponibles pour le monde ", currentIndex, availablePortals);

    const selectedPortals = [];

    // Sélectionne 3 portails aléatoires sans doublon
    while (selectedPortals.length < 3) {
        const randomPortal = availablePortals[Math.floor(Math.random() * availablePortals.length)];
        if (!selectedPortals.includes(randomPortal)) {
            selectedPortals.push(randomPortal);
        }
    }

    // Définition des textures pour les portails
    const textures = [
        new THREE.TextureLoader().load('./assets/images/blue-texture.png'),
        new THREE.TextureLoader().load('./assets/images/green-texture.png'),
        new THREE.TextureLoader().load('./assets/images/yellow-texture.png'),
        new THREE.TextureLoader().load('./assets/images/pink-texture.png'),
        new THREE.TextureLoader().load('./assets/images/orange-texture.png'),
        new THREE.TextureLoader().load('./assets/images/purple-texture.png'),
    ];

    // Création des portails sélectionnés
    selectedPortals.forEach((portalIndex, i) => {
        const radius = 20;
        const portalGeometry = new THREE.SphereGeometry(radius, 32, 32);

        const portalMaterial = new THREE.MeshBasicMaterial({
            map: textures[portalIndex], // Applique la texture du portail sélectionné
            transparent: true,
            opacity: 1,
        });

        const portal = new THREE.Mesh(portalGeometry, portalMaterial);
        const position = getRandomPositionOnSphere(500);  // Utilise une fonction pour positionner le portail
        portal.position.set(position.x, position.y, position.z);
        portal.name = `portal_${i}`; // Pour pouvoir le retrouver plus tard et le supprimer
        scene.add(portal);

        // Ajout de la lumière pour chaque portail
        const portalLight = new THREE.PointLight(0x00ff00, 1, 100);
        portalLight.position.set(position.x, position.y, position.z);
        scene.add(portalLight);

        // Comportement de survol du portail
        portal.onHover = (isHovered) => {
            if (isHovered) {
                document.body.style.cursor = 'pointer';
                portal.material.color.set(0xff0000);
            } else {
                document.body.style.cursor = 'auto';
                portal.material.color.set(0xffffff);
            }
        };

        // Comportement de clic sur le portail
        portal.onClick = () => {
            console.log(`Portail ${portalIndex} cliqué. Téléportation...`);
            handlePortalClick(portalIndex);  // Cette fonction gère la logique de transition
            repositionPortals(interactiveAssets);
        };

        interactiveAssets.push({
            object: portal,
            onHover: portal.onHover,
            onClick: portal.onClick,
        });

        console.log(`Portail ${portalIndex} ajouté à la scène avec texture`, textures[i]);
    });
}