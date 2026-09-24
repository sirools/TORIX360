import * as THREE from 'three';
import { Board, N, T, key, tileToLocal, bfs, pathTo, manhattan, neighbours } from './board.js';
import { createHero, createGlitch, createPortal, createRock, createHpBar } from './pieces.js';
import { createButton, createHud, floatText } from './ui.js';
import { tween, wait, easeOutBack } from './tween.js';

// Règles du POC : un combat tactique au tour par tour (PA / PM),
// l'objectif est de sceller les 3 portails avant d'être submergé.
const SPELLS = {
  strike: { id: 'strike', name: 'Frappe', cost: 3, min: 1, max: 1, dmg: [6, 8] },
  shard: { id: 'shard', name: 'Éclat torique', cost: 3, min: 2, max: 4, dmg: [3, 5] },
};
const HERO = { hp: 40, pa: 6, pm: 3 };
const GLITCH = { hp: 9, pm: 2, dmg: [3, 4] };
const PORTAL_HP = 14;
const MAX_GLITCHES = 6;
const SPAWN_EVERY = 2;

const LAYOUT = {
  hero: [3, 7],
  rocks: [[2, 4], [5, 4], [0, 3], [7, 5], [3, 2]],
  portals: [[1, 1], [6, 0], [4, 2]],
  glitches: [[1, 2], [6, 1]],
};

const MESSAGES = {
  idle: 'Case verte : bouger · Cible : attaquer',
  spell: 'Vise une cible dans la zone bleue',
  enemy: 'Les Glitchs avancent…',
  spawn: 'Les portails libèrent des Glitchs !',
  sealed: 'Portail scellé !',
  noPa: 'Pas assez de PA pour ce sort',
  outOfRange: 'Cible hors de portée',
  win: 'Victoire ! Les portails sont scellés.',
  lose: 'Défaite… Les Glitchs ont gagné.',
};

const roll = ([a, b]) => a + Math.floor(Math.random() * (b - a + 1));

let uidSeq = 0;

export class Game {
  constructor() {
    this.group = new THREE.Group();
    this.board = new Board();
    this.group.add(this.board.group);
    this.pieces = new THREE.Group();
    this.group.add(this.pieces);

    this.rocks = new Set();
    LAYOUT.rocks.forEach(([x, z], i) => {
      const rock = createRock(i + 1);
      rock.position.add(tileToLocal(x, z, 0.012));
      rock.userData.pick = { type: 'tile', x, z };
      this.group.add(rock);
      this.rocks.add(key(x, z));
    });

    this.hud = createHud();
    this.hud.mesh.position.set(0, 0.2, -N * T / 2 - 0.03);
    this.hud.mesh.rotation.x = -0.2;
    this.group.add(this.hud.mesh);

    this.buttons = {};
    ['strike', 'shard', 'end'].forEach((id, i) => {
      const b = createButton(id);
      b.mesh.position.set((i - 1) * 0.17, 0.035, N * T / 2 + 0.06);
      b.mesh.rotation.x = -1.0;
      this.group.add(b.mesh);
      this.buttons[id] = b;
    });

    this.hovered = null;
    this.reset();
  }

  // ---------- État ----------

  reset() {
    for (const u of this.units ?? []) this.pieces.remove(u.mesh);
    this.units = [];
    this.hero = this.addUnit('hero', ...LAYOUT.hero);
    LAYOUT.portals.forEach(([x, z]) => this.addUnit('portal', x, z));
    LAYOUT.glitches.forEach(([x, z]) => this.addUnit('glitch', x, z));
    Object.assign(this, {
      turn: 1, playerTurn: true, busy: false, over: null,
      pa: HERO.pa, pm: HERO.pm, spell: null, message: MESSAGES.idle,
    });
    this.refresh();
  }

  addUnit(kind, x, z) {
    const make = { hero: createHero, glitch: createGlitch, portal: createPortal }[kind];
    const max = { hero: HERO.hp, glitch: GLITCH.hp, portal: PORTAL_HP }[kind];
    const color = { hero: '#44d17a', glitch: '#ff4d6d', portal: '#5ef2ff' }[kind];
    const uid = ++uidSeq;
    const mesh = make();
    mesh.position.copy(tileToLocal(x, z, 0.012));
    if (kind === 'hero') mesh.rotation.y = Math.PI;
    // Le héros n'est pas ciblable : le rayon le traverse pour atteindre la case derrière lui.
    if (kind !== 'hero') mesh.userData.pick = { type: 'unit', id: uid };
    const bar = createHpBar(color);
    bar.position.y = { hero: 0.11, glitch: 0.075, portal: 0.095 }[kind];
    bar.update(max, max);
    mesh.add(bar);
    this.pieces.add(mesh);
    const unit = { uid, kind, x, z, hp: max, max, mesh, bar };
    this.units.push(unit);
    return unit;
  }

  get glitches() { return this.units.filter((u) => u.kind === 'glitch'); }
  get portals() { return this.units.filter((u) => u.kind === 'portal'); }
  unitAt(x, z) { return this.units.find((u) => u.x === x && u.z === z); }
  unitById(id) { return this.units.find((u) => u.uid === id); }

  isBlocked(x, z, self = null) {
    if (this.rocks.has(key(x, z))) return true;
    const u = this.unitAt(x, z);
    return !!u && u !== self;
  }

  canAct() { return this.playerTurn && !this.busy && !this.over; }

  reachable() {
    return bfs(this.hero, (x, z) => this.isBlocked(x, z, this.hero), this.pm);
  }

  // Sort utilisé quand on vise une cible : celui sélectionné, sinon le meilleur disponible.
  spellFor(target) {
    const d = manhattan(this.hero, target);
    const fits = (s) => d >= s.min && d <= s.max;
    if (this.spell) return { spell: SPELLS[this.spell], ok: fits(SPELLS[this.spell]) };
    const s = Object.values(SPELLS).find(fits);
    return { spell: s, ok: !!s };
  }

  // ---------- Affichage ----------

  refresh() {
    const b = this.board;
    b.clearTints();
    const hoverUnit = this.hovered?.type === 'unit' ? this.unitById(this.hovered.id)
      : this.hovered?.type === 'tile' ? this.unitAt(this.hovered.x, this.hovered.z) : null;

    if (this.canAct()) {
      if (this.spell) {
        const s = SPELLS[this.spell];
        for (let x = 0; x < N; x++) {
          for (let z = 0; z < N; z++) {
            const d = manhattan(this.hero, { x, z });
            if (d >= s.min && d <= s.max) b.tint(x, z, 'range');
          }
        }
      } else {
        const reach = this.reachable();
        for (const n of reach.values()) if (n.d > 0) b.tint(n.x, n.z, 'move');
        if (this.hovered?.type === 'tile') {
          const node = reach.get(key(this.hovered.x, this.hovered.z));
          if (node) for (const p of pathTo(node)) b.tint(p.x, p.z, 'path');
        }
      }
      if (hoverUnit && hoverUnit.kind !== 'hero' && this.spellFor(hoverUnit).ok) {
        b.tint(hoverUnit.x, hoverUnit.z, 'target');
      }
    }

    const phase = this.over === 'win' ? 'Victoire' : this.over === 'lose' ? 'Défaite'
      : this.playerTurn ? 'À toi de jouer' : 'Tour des Glitchs';
    this.hud.draw({
      turn: this.turn, phase, hp: Math.max(0, this.hero.hp), maxHp: HERO.hp,
      pa: this.pa, pm: this.pm, message: this.message, portals: this.portals.length,
    });

    const hoverBtn = this.hovered?.type === 'button' ? this.hovered.id : null;
    for (const id of ['strike', 'shard']) {
      const s = SPELLS[id];
      this.buttons[id].draw({
        title: s.name,
        subtitle: `${s.cost} PA · portée ${s.min === s.max ? s.min : `${s.min}-${s.max}`}`,
        active: this.spell === id,
        disabled: !this.canAct() || this.pa < s.cost,
        hover: hoverBtn === id,
      });
    }
    this.buttons.end.draw({
      title: this.over ? 'Rejouer' : 'Fin du tour',
      subtitle: this.over ? '' : 'Passer la main',
      disabled: !this.over && !this.canAct(),
      hover: hoverBtn === 'end',
    });
  }

  say(message) {
    this.message = message;
    this.refresh();
  }

  // ---------- Entrées ----------

  onHover(pick) {
    this.hovered = pick;
    this.refresh();
  }

  onPick(pick) {
    if (pick.type === 'button') return this.onButton(pick.id);
    if (!this.canAct()) return;

    const target = pick.type === 'unit' ? this.unitById(pick.id) : this.unitAt(pick.x, pick.z);
    if (target && target.kind !== 'hero') return this.tryCast(target);
    if (target?.kind === 'hero' || this.spell) {
      this.spell = null;
      return this.say(MESSAGES.idle);
    }

    const node = this.reachable().get(key(pick.x, pick.z));
    if (node && node.d > 0) this.moveHero(pathTo(node));
  }

  onButton(id) {
    if (id === 'end') {
      if (this.over) return this.reset();
      if (this.canAct()) this.endTurn();
      return;
    }
    if (!this.canAct()) return;
    if (this.pa < SPELLS[id].cost) return this.say(MESSAGES.noPa);
    this.spell = this.spell === id ? null : id;
    this.say(this.spell ? MESSAGES.spell : MESSAGES.idle);
  }

  // ---------- Actions ----------

  async animateMove(unit, path) {
    for (const step of path) {
      const from = unit.mesh.position.clone();
      const to = tileToLocal(step.x, step.z, 0.012);
      this.face(unit, step);
      await tween(0.16, (k) => {
        unit.mesh.position.lerpVectors(from, to, k);
        unit.mesh.position.y = to.y + Math.sin(k * Math.PI) * 0.02;
      });
      unit.x = step.x;
      unit.z = step.z;
    }
  }

  face(unit, target) {
    const dx = target.x - unit.x;
    const dz = target.z - unit.z;
    if (dx || dz) unit.mesh.rotation.y = Math.atan2(dx, dz);
  }

  async moveHero(path) {
    this.busy = true;
    this.pm -= path.length;
    this.refresh();
    await this.animateMove(this.hero, path);
    this.busy = false;
    this.say(MESSAGES.idle);
  }

  async tryCast(target) {
    const { spell, ok } = this.spellFor(target);
    if (!ok) return this.say(MESSAGES.outOfRange);
    if (this.pa < spell.cost) return this.say(MESSAGES.noPa);

    this.busy = true;
    this.pa -= spell.cost;
    this.spell = null;
    this.face(this.hero, target);
    this.refresh();
    if (spell.id === 'strike') await this.lunge(this.hero, target);
    else await this.projectile(this.hero, target);
    await this.damage(target, roll(spell.dmg));
    this.busy = false;

    if (!this.portals.length) return this.victory();
    this.say(MESSAGES.idle);
  }

  async lunge(unit, target) {
    const from = unit.mesh.position.clone();
    const to = from.clone().lerp(tileToLocal(target.x, target.z, 0.012), 0.45);
    await tween(0.1, (k) => unit.mesh.position.lerpVectors(from, to, k));
    await tween(0.14, (k) => unit.mesh.position.lerpVectors(to, from, k));
  }

  async projectile(unit, target) {
    const orb = new THREE.Mesh(
      new THREE.TorusGeometry(0.01, 0.003, 8, 20),
      new THREE.MeshBasicMaterial({ color: '#7ff6ff' }),
    );
    const from = tileToLocal(unit.x, unit.z, 0.07);
    const to = tileToLocal(target.x, target.z, 0.04);
    this.group.add(orb);
    await tween(0.28, (k) => {
      orb.position.lerpVectors(from, to, k);
      orb.position.y += Math.sin(k * Math.PI) * 0.05;
      orb.rotation.x = k * 12;
    });
    this.group.remove(orb);
  }

  async damage(unit, amount) {
    unit.hp -= amount;
    unit.bar.update(Math.max(0, unit.hp), unit.max);
    const color = unit.kind === 'hero' ? '#ff5d73' : '#ffd23f';
    floatText(this.group, unit.mesh.position.clone().setY(0.1), `-${amount}`, color);
    const s = unit.mesh.scale.x;
    await tween(0.18, (k) => unit.mesh.scale.setScalar(s * (1 + Math.sin(k * Math.PI) * 0.25)));
    if (unit.hp <= 0 && unit.kind !== 'hero') await this.kill(unit);
  }

  async kill(unit) {
    this.units.splice(this.units.indexOf(unit), 1);
    const r0 = unit.mesh.rotation.y;
    await tween(0.3, (k) => {
      unit.mesh.scale.setScalar(1 - k);
      unit.mesh.rotation.y = r0 + k * 6;
    });
    this.pieces.remove(unit.mesh);
    if (unit.kind === 'portal') this.say(MESSAGES.sealed);
  }

  async victory() {
    this.over = 'win';
    this.say(MESSAGES.win);
    await Promise.all(this.glitches.map((g) => this.kill(g)));
    await tween(0.8, (k) => { this.hero.mesh.position.y = 0.012 + Math.sin(k * Math.PI * 2) * 0.03; });
    this.say(MESSAGES.win);
  }

  // ---------- Tour des Glitchs ----------

  async endTurn() {
    this.playerTurn = false;
    this.spell = null;
    this.say(MESSAGES.enemy);

    for (const g of [...this.glitches]) {
      if (this.over) break;
      await this.glitchAct(g);
      await wait(0.12);
    }
    if (this.over) return;

    if (this.turn % SPAWN_EVERY === 0) await this.spawnFromPortals();

    this.turn += 1;
    Object.assign(this, { playerTurn: true, pa: HERO.pa, pm: HERO.pm });
    this.say(MESSAGES.idle);
  }

  async glitchAct(g) {
    if (manhattan(g, this.hero) > 1) {
      const reach = bfs(g, (x, z) => this.isBlocked(x, z, g));
      const goals = neighbours(this.hero.x, this.hero.z)
        .map((p) => reach.get(key(p.x, p.z)))
        .filter(Boolean);
      // Pas de chemin jusqu'au héros : on s'en rapproche au mieux.
      const best = goals.length
        ? goals.reduce((a, b) => (b.d < a.d ? b : a))
        : [...reach.values()].reduce((a, b) => (manhattan(b, this.hero) < manhattan(a, this.hero) ? b : a));
      const path = pathTo(best).slice(0, GLITCH.pm);
      if (path.length) await this.animateMove(g, path);
    }
    if (manhattan(g, this.hero) === 1) {
      this.face(g, this.hero);
      await this.lunge(g, this.hero);
      await this.damage(this.hero, roll(GLITCH.dmg));
      if (this.hero.hp <= 0) {
        this.over = 'lose';
        await tween(0.4, (k) => { this.hero.mesh.rotation.z = k * Math.PI / 2; });
        this.say(MESSAGES.lose);
      } else {
        this.refresh();
      }
    }
  }

  async spawnFromPortals() {
    let spawned = false;
    for (const p of this.portals) {
      if (this.glitches.length >= MAX_GLITCHES) break;
      const free = neighbours(p.x, p.z).filter((n) => !this.isBlocked(n.x, n.z));
      if (!free.length) continue;
      const spot = free[Math.floor(Math.random() * free.length)];
      const g = this.addUnit('glitch', spot.x, spot.z);
      g.mesh.scale.setScalar(0.001);
      spawned = true;
      tween(0.4, (k) => g.mesh.scale.setScalar(Math.max(0.001, k)), easeOutBack);
    }
    if (spawned) {
      this.say(MESSAGES.spawn);
      await wait(0.6);
    }
  }

  // ---------- Boucle ----------

  update(t) {
    for (const u of this.units) {
      if (u.kind === 'portal') u.mesh.getObjectByName('spinner').rotation.y = t * 1.2 + u.uid;
      if (u.kind === 'glitch') u.mesh.getObjectByName('bob').position.y = 0.035 + Math.sin(t * 3 + u.uid) * 0.006;
    }
    const halo = this.hero.mesh.getObjectByName('halo');
    halo.position.set(Math.cos(t * 2) * 0.026, 0.06 + Math.sin(t * 4) * 0.004, Math.sin(t * 2) * 0.026);
    halo.rotation.y = t * 3;
  }
}
