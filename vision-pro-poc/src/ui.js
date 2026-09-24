import * as THREE from 'three';
import { tween } from './tween.js';

// Les panneaux sont dessinés dans des canvas puis plaqués sur des plans 3D :
// le DOM n'est pas visible en session immersive, tout doit vivre dans la scène.
export function createPanel(width, height, pxPerMeter = 1600) {
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(width * pxPerMeter);
  canvas.height = Math.round(height * pxPerMeter);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(width, height),
    new THREE.MeshBasicMaterial({ map: texture, transparent: true }),
  );
  return { mesh, canvas, ctx: canvas.getContext('2d'), texture };
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
}

export function createButton(id, width = 0.15, height = 0.055) {
  const panel = createPanel(width, height);
  panel.mesh.userData.pick = { type: 'button', id };
  panel.draw = ({ title, subtitle = '', active = false, disabled = false, hover = false }) => {
    const { ctx, canvas } = panel;
    const w = canvas.width;
    const h = canvas.height;
    ctx.clearRect(0, 0, w, h);
    roundRect(ctx, 4, 4, w - 8, h - 8, h * 0.3);
    ctx.fillStyle = disabled ? 'rgba(70,64,90,0.75)' : hover ? '#4b3fb8' : '#2e2670';
    ctx.fill();
    ctx.lineWidth = active ? 10 : 4;
    ctx.strokeStyle = active ? '#ffd23f' : 'rgba(255,255,255,0.35)';
    ctx.stroke();
    ctx.fillStyle = disabled ? '#a9a3bf' : '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = `700 ${Math.round(h * 0.34)}px system-ui, -apple-system, sans-serif`;
    ctx.fillText(title, w / 2, subtitle ? h * 0.4 : h / 2);
    if (subtitle) {
      ctx.font = `500 ${Math.round(h * 0.2)}px system-ui, -apple-system, sans-serif`;
      ctx.fillStyle = disabled ? '#a9a3bf' : '#bfe9ff';
      ctx.fillText(subtitle, w / 2, h * 0.72);
    }
    panel.texture.needsUpdate = true;
  };
  return panel;
}

export function createHud() {
  const panel = createPanel(0.56, 0.15);
  panel.draw = ({ turn, phase, hp, maxHp, pa, pm, message, portals }) => {
    const { ctx, canvas } = panel;
    const w = canvas.width;
    const h = canvas.height;
    ctx.clearRect(0, 0, w, h);
    roundRect(ctx, 6, 6, w - 12, h - 12, 40);
    ctx.fillStyle = 'rgba(24,18,56,0.82)';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = 'rgba(126,246,255,0.6)';
    ctx.stroke();

    ctx.textBaseline = 'middle';
    ctx.textAlign = 'left';
    ctx.fillStyle = '#7ff6ff';
    ctx.font = '800 44px system-ui, -apple-system, sans-serif';
    ctx.fillText(`TOUR ${turn}`, 40, 55);
    ctx.fillStyle = '#ffffff';
    ctx.font = '600 40px system-ui, -apple-system, sans-serif';
    ctx.fillText(phase, 240, 55);

    ctx.textAlign = 'right';
    ctx.fillStyle = '#ffd23f';
    ctx.font = '700 38px system-ui, -apple-system, sans-serif';
    ctx.fillText(`Portails : ${portals}`, w - 40, 55);

    const chips = [
      { label: `PV ${hp}/${maxHp}`, color: '#ff5d73' },
      { label: `PA ${pa}`, color: '#3fa7ff' },
      { label: `PM ${pm}`, color: '#44c767' },
    ];
    let x = 40;
    ctx.textAlign = 'center';
    ctx.font = '700 36px system-ui, -apple-system, sans-serif';
    for (const chip of chips) {
      const cw = ctx.measureText(chip.label).width + 44;
      roundRect(ctx, x, 95, cw, 56, 28);
      ctx.fillStyle = chip.color;
      ctx.fill();
      ctx.fillStyle = '#ffffff';
      ctx.fillText(chip.label, x + cw / 2, 124);
      x += cw + 18;
    }

    ctx.textAlign = 'left';
    ctx.fillStyle = '#e6e0ff';
    ctx.font = '500 32px system-ui, -apple-system, sans-serif';
    ctx.fillText(message, 40, 196);
    panel.texture.needsUpdate = true;
  };
  return panel;
}

// Chiffres de dégâts qui montent et s'estompent.
export function floatText(parent, position, text, color = '#ffffff') {
  const canvas = document.createElement('canvas');
  canvas.width = 160;
  canvas.height = 64;
  const ctx = canvas.getContext('2d');
  ctx.font = '900 52px system-ui, -apple-system, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineWidth = 8;
  ctx.strokeStyle = 'rgba(20,10,40,0.9)';
  ctx.strokeText(text, 80, 34);
  ctx.fillStyle = color;
  ctx.fillText(text, 80, 34);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false }));
  sprite.scale.set(0.06, 0.024, 1);
  sprite.renderOrder = 20;
  sprite.raycast = () => {};
  sprite.position.copy(position);
  parent.add(sprite);
  const y0 = position.y;
  tween(0.9, (k) => {
    sprite.position.y = y0 + k * 0.05;
    sprite.material.opacity = 1 - Math.max(0, k - 0.5) * 2;
  }, (k) => 1 - Math.pow(1 - k, 3)).then(() => {
    parent.remove(sprite);
    texture.dispose();
    sprite.material.dispose();
  });
}
