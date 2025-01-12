

import * as THREE from 'three';

import TWEEN from '@tweenjs/tween.js'; // Assurez-vous que cette ligne est correcte

import { getRandomPositionOnSphere, changePortalColor, animatePortalScale } from './helpers.js';

//import { getRandomPositionOnSphere } from './helpers.js';




// Fonction pour relancer la position aléatoire des portails après chaque clic
function repositionPortals(interactiveAssets) {
    // Pour chaque portail, on lui attribue une nouvelle position aléatoire
    interactiveAssets.forEach(asset => {
        const newPosition = getRandomPositionOnSphere(500);
        asset.object.position.set(newPosition.x, newPosition.y, newPosition.z);
        console.log(`Portail déplacé vers la nouvelle position : ${newPosition}`);
    });
}



export function addStylizedPortals(scene, interactiveAssets, handlePortalClick) {
    const whiteTexture = new THREE.TextureLoader().load('./assets/images/white-texture.png');
    const redTexture = new THREE.TextureLoader().load('./assets/images/red-texture.png');
    const blueTexture = new THREE.TextureLoader().load('./assets/images/blue-texture.png'); // Texture pour portail 1
    const greenTexture = new THREE.TextureLoader().load('./assets/images/green-texture.png'); // Texture pour portail 2
    const yellowTexture = new THREE.TextureLoader().load('./assets/images/yellow-texture.png'); // Texture pour portail 3

    const textures = [blueTexture, greenTexture, yellowTexture]; // Tableau des textures

    for (let i = 0; i < 3; i++) {
        const radius = 20;
        const portalGeometry = new THREE.SphereGeometry(radius, 32, 32);

        const portalMaterial = new THREE.MeshBasicMaterial({
            map: textures[i], // Applique une texture différente pour chaque portail
            transparent: true,
            opacity: 1,
        });

        const portal = new THREE.Mesh(portalGeometry, portalMaterial);
        const position = getRandomPositionOnSphere(500);
        portal.position.set(position.x, position.y, position.z);
        scene.add(portal);

        const portalLight = new THREE.PointLight(0x00ff00, 1, 100);
        portalLight.position.set(position.x, position.y, position.z);
        scene.add(portalLight);

        portal.onHover = (isHovered) => {
            if (isHovered) {
                document.body.style.cursor = 'pointer';
                portal.material.color.set(0xff0000);
            } else {
                document.body.style.cursor = 'auto';
                portal.material.color.set(0xffffff);
            }
        };

        portal.onClick = () => {
            console.log(`Portail ${i} cliqué. Téléportation...`);
            handlePortalClick(i);
            // Relance la position aléatoire des portails après chaque clic
            repositionPortals(interactiveAssets);  // Passer interactiveAssets ici
        };

        interactiveAssets.push({
            object: portal,
            onHover: portal.onHover,
            onClick: portal.onClick,
        });

        console.log(`Portail ${i} ajouté avec texture et comportement unique.`);
    }
}
