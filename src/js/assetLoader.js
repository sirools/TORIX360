import * as THREE from 'three';

console.log('THREE version:', THREE.REVISION);

// Fonction pour charger une texture avec gestion d'encodage
export function loadTexture(url) {
    return new Promise((resolve, reject) => {
        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(
            url,
            (texture) => {
                texture.encoding = 3001; // sRGBEncoding
                console.log(`Texture encoding pour ${url}:`, texture.encoding);
                console.log(`Texture chargée depuis ${url}`, texture);
                resolve(texture);
            },
            undefined,
            (err) => {
                console.error(`Erreur lors du chargement de la texture depuis ${url}`, err);
                reject(new Error(`Erreur critique lors du chargement de ${url}: ${err.message}`));
            }
        );
    });
}