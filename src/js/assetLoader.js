import * as THREE from 'three';

export class AssetLoader {
    constructor(basePath) {
        this.textureLoader = new THREE.TextureLoader();
        this.basePath = basePath;
    }

    loadTextures(texturePaths) {
        return Promise.all(
            texturePaths.map((path) =>
                new Promise((resolve, reject) => {
                    this.textureLoader.load(
                        this.basePath + path,
                        resolve,
                        undefined,
                        reject
                    );
                })
            )
        );
    }
}