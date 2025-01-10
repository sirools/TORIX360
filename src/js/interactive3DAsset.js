import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';  // Assure-toi d'importer GLTFLoader correctement


export class Interactive3DAsset {
  constructor(path, position, scale, texture, callback) {
    this.path = path;
    this.position = position;
    this.scale = scale;
    this.texture = texture;
    this.callback = callback;

    this.object = null; // Objet 3D
    this.isHovered = false; // Vérifie si l'objet est survolé
  }

  // Charger le modèle 3D et l'ajouter à la scène
  loadModel() {
    const loader = new THREE.GLTFLoader();
    loader.load(this.path, (gltf) => {
      this.object = gltf.scene;
      this.object.position.set(this.position.x, this.position.y, this.position.z);
      this.object.scale.set(this.scale, this.scale, this.scale);
      this.object.traverse((child) => {
        if (child.isMesh) {
          child.material.map = this.texture; // Applique la texture
        }
      });
      this.object.userData = { id: this.callback }; // Lier la callback

      scene.add(this.object);
    });
  }

  // Ajouter l'animation au survol de l'objet
  animateHover() {
    this.object.on('mouseenter', () => {
      this.isHovered = true;
      this.object.scale.set(this.scale * 1.1, this.scale * 1.1, this.scale * 1.1); // Agrandir l'objet
      this.object.material.emissive.set(0x00ffff); // Ajout de lumière
    });
    this.object.on('mouseleave', () => {
      this.isHovered = false;
      this.object.scale.set(this.scale, this.scale, this.scale); // Réduire l'objet
      this.object.material.emissive.set(0x000000); // Retirer la lumière
    });
  }

  // Déclencher la disparition lente de l'objet
  disappear() {
    if (!this.object) return;

    const fadeOut = new THREE.AnimationMixer(this.object);
    const fadeOutAction = fadeOut.clipAction(new THREE.AnimationClip('fade', -1, [
      new THREE.KeyframeTrack(
        '.material.opacity',
        [0, 1],
        [1, 0]
      ),
    ]));

    fadeOutAction.play();
    fadeOutAction.setLoop(THREE.LoopOnce);
  }

  // Déclencher la fonction au clic
  onClick() {
    this.object.callback = this.callback;
  }
}