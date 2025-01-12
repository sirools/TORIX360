import * as THREE from 'three';

/**
 * Obtenir une position aléatoire sur la sphère.
 * @param {number} radius - Le rayon de la sphère.
 * @returns {THREE.Vector3} - La position aléatoire.
 */
export function getRandomPositionOnSphere(radius) {
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);

    const x = radius * Math.sin(phi) * Math.cos(theta);
    const y = radius * Math.sin(phi) * Math.sin(theta);
    const z = radius * Math.cos(phi);

    return new THREE.Vector3(x, y, z);
}

/**
 * Change la couleur d'un portail.
 * @param {THREE.PointLight} portalLight - La lumière associée au portail.
 * @param {number} color - La nouvelle couleur en hex.
 */
export function changePortalColor(portalLight, color) {
    if (portalLight) {
        portalLight.color.set(color);
    }
}

/**
 * Animation du scale du portail avec un effet de transition.
 * @param {THREE.Mesh} portal - Le portail à animer.
 * @param {number} scaleTarget - La taille cible (1 = normal, 2 = double).
 * @param {number} duration - La durée de l'animation en ms.
 */
export function animatePortalScale(portal, scaleTarget, duration) {
    if (portal) {
        new TWEEN.Tween(portal.scale)
            .to({ x: scaleTarget, y: scaleTarget, z: scaleTarget }, duration)
            .easing(TWEEN.Easing.Quadratic.Out)
            .start();
    }
}