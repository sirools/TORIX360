

import * as THREE from 'three';

import TWEEN from '@tweenjs/tween.js'; // Assurez-vous que cette ligne est correcte

import { getRandomPositionOnSphere, changePortalColor, animatePortalScale } from './helpers.js';

//import { getRandomPositionOnSphere } from './helpers.js';



export function addStylizedPortals(scene, interactiveAssets, handlePortalClick) {
    const whiteTexture = new THREE.TextureLoader().load('./assets/images/white-texture.png');
    const redTexture = new THREE.TextureLoader().load('./assets/images/red-texture.png');
    

    for (let i = 0; i < 3; i++) {
        const radius = 20;
        const portalGeometry = new THREE.SphereGeometry(radius, 32, 32);
        const portalMaterial = new THREE.MeshBasicMaterial({
            map: whiteTexture, // Définir la texture initiale
            transparent: true,
            opacity: 1 // Définir l'opacité initiale
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
                // Changer le curseur en main lors du hover
                document.body.style.cursor = 'pointer';

                // Commencer l'animation pour changer la texture de blanc à rouge
                new TWEEN.Tween(portal.material)
                    .to({ opacity: 0 }, 300) // Réduire l'opacité à 0 (fondu)
                    .onComplete(() => {
                        portal.material.map = redTexture; // Changer la texture en rouge
                        portal.material.needsUpdate = true; // Signaler que la texture a changé
                        new TWEEN.Tween(portal.material)
                            .to({ opacity: 1 }, 300) // Remettre l'opacité à 1 (fondu)
                            .start();
                    })
                    .start();
            } else {
                // Revenir au curseur par défaut
                document.body.style.cursor = 'auto';

                // Commencer l'animation pour revenir à la texture blanche
                new TWEEN.Tween(portal.material)
                    .to({ opacity: 0 }, 300) // Réduire l'opacité à 0 (fondu)
                    .onComplete(() => {
                        portal.material.map = whiteTexture; // Revenir à la texture blanche
                        portal.material.needsUpdate = true; // Signaler que la texture a changé
                        new TWEEN.Tween(portal.material)
                            .to({ opacity: 1 }, 300) // Remettre l'opacité à 1 (fondu)
                            .start();
                    })
                    .start();
            }
        };

        portal.onClick = () => {
            console.log(`Portail ${i} cliqué. Téléportation...`);
            handlePortalClick(i);
        };

        interactiveAssets.push({
            object: portal,
            onHover: portal.onHover,
            onClick: portal.onClick,
        });

        console.log(`Portail ${i} ajouté avec lumière et comportement unique.`);
    }
}