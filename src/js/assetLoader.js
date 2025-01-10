import * as THREE from 'three';

console.log('THREE version:', THREE.REVISION);

// Fonction pour charger une texture avec gestion d'encodage
export function loadTexture(url) {
    return new Promise((resolve, reject) => {
        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(
            url,
            (texture) => {
                // Appliquer l'encodage
                texture.encoding = 3001; // Identifiant pour sRGBEncoding
                console.log(`Texture encoding pour ${url}:`, texture.encoding);

                // Log de débogage pour vérifier l'encodage et la texture
                console.log(`Texture chargée depuis ${url}`, {
                    encoding: texture.encoding,
                    texture,
                });

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