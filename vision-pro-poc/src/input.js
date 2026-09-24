import * as THREE from 'three';

// Entrée unifiée : souris / tactile sur écran, et en XR
// - Vision Pro : "transient-pointer" (regard + pincement),
// - Quest & co : manettes "tracked-pointer" avec rayon visible.
export class Input {
  constructor(renderer, camera, root, { onPick, onHover }) {
    this.renderer = renderer;
    this.camera = camera;
    this.root = root;
    this.onPick = onPick;
    this.onHover = onHover;
    this.raycaster = new THREE.Raycaster();
    this.ndc = new THREE.Vector2();
    this.controllers = [];
    this.hovered = null;

    const canvas = renderer.domElement;
    let down = null;
    canvas.addEventListener('pointerdown', (e) => { down = { x: e.clientX, y: e.clientY }; });
    canvas.addEventListener('pointermove', (e) => {
      this.setNdc(e);
      this.raycaster.setFromCamera(this.ndc, camera);
      this.hover(this.cast());
    });
    canvas.addEventListener('pointerup', (e) => {
      // Un glisser sert à orbiter la caméra, pas à jouer.
      if (!down || Math.hypot(e.clientX - down.x, e.clientY - down.y) > 6) return;
      this.setNdc(e);
      this.raycaster.setFromCamera(this.ndc, camera);
      const hit = this.cast();
      if (hit) this.onPick(hit);
    });

    const rayGeo = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 0, -1)]);
    for (let i = 0; i < 2; i++) {
      const controller = renderer.xr.getController(i);
      const ray = new THREE.Line(rayGeo, new THREE.LineBasicMaterial({ color: '#7ff6ff', transparent: true, opacity: 0.7 }));
      ray.scale.z = 3;
      ray.visible = false;
      controller.add(ray);
      controller.addEventListener('connected', (e) => {
        controller.userData.mode = e.data.targetRayMode;
        ray.visible = e.data.targetRayMode === 'tracked-pointer';
      });
      controller.addEventListener('disconnected', () => { ray.visible = false; });
      // La pose n'est pas toujours prête au moment du selectstart :
      // on marque l'intention et on lance le rayon à la frame suivante.
      controller.addEventListener('selectstart', () => { controller.userData.pending = true; });
      this.controllers.push(controller);
    }
  }

  setNdc(e) {
    const rect = this.renderer.domElement.getBoundingClientRect();
    this.ndc.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
    this.ndc.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
  }

  cast() {
    const hits = this.raycaster.intersectObject(this.root, true);
    for (const h of hits) {
      let o = h.object;
      while (o && !o.userData.pick) o = o.parent;
      if (o && o.visible) return o.userData.pick;
    }
    return null;
  }

  hover(pick) {
    const same = pick && this.hovered && pick.type === this.hovered.type && pick.id === this.hovered.id
      && pick.x === this.hovered.x && pick.z === this.hovered.z;
    if (same || (!pick && !this.hovered)) return;
    this.hovered = pick;
    this.onHover(pick);
  }

  update() {
    if (!this.renderer.xr.isPresenting) return;
    for (const c of this.controllers) {
      if (c.userData.mode === 'tracked-pointer' && c.visible) {
        this.raycaster.setFromXRController(c);
        this.hover(this.cast());
      }
      if (c.userData.pending && c.visible) {
        c.userData.pending = false;
        this.raycaster.setFromXRController(c);
        const hit = this.cast();
        if (hit) this.onPick(hit);
      }
    }
  }
}
