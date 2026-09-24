# TORIX360 · Gardiens des Portails — POC Vision Pro

Prototype jouable d'un jeu **tactique au tour par tour en réalité virtuelle**, pensé pour l'Apple Vision Pro
et construit en **WebXR + Three.js** : il tourne dans Safari sur visionOS, sans App Store ni compte développeur,
et reste jouable à la souris dans n'importe quel navigateur.

Le plateau est une **maquette posée à hauteur de table** devant le joueur, sur une île flottante. On joue
au **regard + pincement**, l'interaction native du Vision Pro.

## Règles du prototype

- Objectif : **sceller les 3 portails** (les détruire) avant que les Glitchs ne vous submergent.
- Chaque tour : **6 PA** (points d'action) pour les sorts, **3 PM** (points de mouvement) pour se déplacer.
- Sorts : **Frappe** (3 PA, corps à corps) et **Éclat torique** (3 PA, portée 2 à 4).
- Viser un ennemi choisit automatiquement le sort adapté. Les boutons de sort affichent leur zone de portée.
- Tous les 2 tours, chaque portail encore ouvert libère un Glitch.

## Lancer en local

```bash
cd vision-pro-poc
npm install
npm run dev          # http://localhost:5173 : souris / tactile
npm run build        # build statique dans dist/
```

## Tester sur Vision Pro

WebXR exige une page servie en **HTTPS**.

1. Sur le même réseau Wi-Fi que le casque : `npm run dev:https`, puis ouvrir `https://<IP-du-Mac>:5173`
   dans Safari sur le Vision Pro et accepter le certificat auto-signé.
   Autre option : publier `dist/` sur un hébergement HTTPS (GitHub Pages, Netlify, etc.).
2. Si le bouton affiche « VR NOT SUPPORTED », activer WebXR dans
   *Réglages → Apps → Safari → Avancé → Fonctionnalités* (option « WebXR Device API »).
3. Appuyer sur **ENTER VR**, regarder une case et **pincer** pour jouer.

Le POC gère aussi les manettes des autres casques (Quest…), avec un rayon visible.

## Structure

| Fichier | Rôle |
| --- | --- |
| `src/main.js` | Rendu, session XR, boucle principale |
| `src/game.js` | Règles, tours, IA des Glitchs, apparition des ennemis |
| `src/board.js` | Grille 8×8, pathfinding (BFS), surbrillance des cases |
| `src/pieces.js` | Figurines low-poly (héros, Glitch, portail, rochers) |
| `src/ui.js` | HUD et boutons dans la scène (le DOM n'existe pas en immersif) |
| `src/input.js` | Entrées unifiées : souris, pincement Vision Pro, manettes |
| `src/world.js` | Ciel, îles flottantes, anneau TORIX |
| `src/tween.js` | Mini moteur d'animation à base de promesses |

Toutes les valeurs d'équilibrage (PV, PA, PM, dégâts, fréquence d'apparition) sont en tête de `src/game.js`.
