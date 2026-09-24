// Mini moteur d'animation à base de promesses : permet d'enchaîner
// les actions de jeu (`await tween(...)`) sans dépendance externe.
const active = [];

export const easeInOut = (k) => (k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2);
export const easeOutBack = (k) => 1 + 2.70158 * Math.pow(k - 1, 3) + 1.70158 * Math.pow(k - 1, 2);

export function tween(duration, onUpdate, ease = easeInOut) {
  return new Promise((resolve) => {
    active.push({ t: 0, duration, onUpdate, ease, resolve });
  });
}

export function wait(duration) {
  return tween(duration, () => {});
}

export function updateTweens(dt) {
  for (let i = active.length - 1; i >= 0; i--) {
    const tw = active[i];
    tw.t += dt;
    const k = Math.min(1, tw.t / tw.duration);
    tw.onUpdate(tw.ease(k));
    if (k >= 1) {
      active.splice(i, 1);
      tw.resolve();
    }
  }
}
