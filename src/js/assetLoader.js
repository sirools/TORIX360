import * as THREE from 'three';

console.log('THREE version:', THREE.REVISION);

// Fonction pour charger une texture avec gestion d'encodage
export function loadTexture(url) {
    return new Promise((resolve, reject) => {
        const textureLoader = new THREE.TextureLoader();
        textureLoader.load(
            url,
            (texture) => {
                // Appliquer l'encodage directement avec les identifiants numériques
                texture.encoding = 3001; // 3001 pour sRGBEncoding
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

                // Rejeter la promesse avec une erreur informative
                reject(new Error(`Erreur critique lors du chargement de ${url}: ${err.message}`));
            }
        );
    }).catch((error) => {
        // Gérer les erreurs critiques
        console.error(`Erreur générale lors du chargement de ${url}:`, error);
    });
}