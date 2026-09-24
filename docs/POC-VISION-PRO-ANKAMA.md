# TORIX360 : Gardiens des Portails
### Note d'intention pour un POC Vision Pro (à destination d'Ankama Games)

## Le pitch en une phrase

Un **jeu tactique au tour par tour en réalité mixte**, dont le plateau est un diorama vivant posé sur votre
table. On y défend des mondes reliés par des **portails toriques** contre des créatures qui en surgissent.

## Pourquoi c'est pertinent pour Ankama

- **Dans l'ADN du studio** : le combat tactique au tour par tour (PA / PM, portées, placement) est le cœur de
  *Dofus* et de *Waven*. Le POC en reprend les codes pour qu'ils soient lisibles au premier coup d'œil.
- **Un format adapté au Vision Pro** : un plateau tactique vu d'au-dessus ressemble à une maquette.
  C'est l'un des formats les plus confortables en XR : pas de déplacement du joueur, pas de cinétose,
  des sessions courtes et une lecture parfaite de la profondeur.
- **Une interaction naturelle** : regard + pincement remplace le clic, un geste par action.
  Le jeu tactique au tour par tour tolère très bien cette précision et ce rythme.
- **Direction artistique** : le Vision Pro met en valeur les univers stylisés et colorés, et les figurines
  « jouet » s'y lisent bien. C'est le terrain d'Ankama.

## Ce que montre le POC (version 0.1)

- Une scène immersive : île flottante, ciel, anneau TORIX monumental.
- Un plateau 8×8 à hauteur de table avec obstacles, déplacements par chemin le plus court et zones de portée.
- Un héros (6 PA / 3 PM) avec deux sorts, trois portails à sceller, des Glitchs avec une IA simple.
- Un HUD et des boutons intégrés à la scène, utilisables au pincement.
- Des parties de 5 à 10 minutes, avec victoire, défaite et bouton « Rejouer ».
- Aucune installation : une URL à ouvrir dans Safari sur le casque.

## Univers

TORIX360 est à l'origine une expérience 360° de mondes artistiques reliés par des portails. Le jeu prolonge
cette idée. Les **Gardiens** voyagent d'un monde à l'autre par les anneaux TORIX, et des **Glitchs** issus de
la corruption des portails menacent chaque monde. Chaque monde = un biome, un plateau et des règles spéciales.

> L'univers et les assets du POC sont **originaux**. Une déclinaison dans le Krosmoz serait une discussion à
> part avec Ankama : le POC ne l'utilise pas.

## Pistes pour la suite

| Étape | Contenu | Techno |
| --- | --- | --- |
| **POC (actuel)** | 1 plateau, 1 héros, 2 sorts, 1 type d'ennemi | WebXR / Three.js |
| **Vertical slice** | 3 mondes, 3 Gardiens, 8 sorts, boss de portail, vraie DA 3D, sons | Unity + PolySpatial, ou natif visionOS (RealityKit / SwiftUI) |
| **Démo éditeur** | Plateau en *passthrough* sur la vraie table, multijoueur coopératif via SharePlay, mode spectateur | Natif visionOS |

Idées propres au Vision Pro à creuser :
- **Réalité mixte** : le plateau se pose sur votre vraie table. Tourner autour ou s'en approcher suffit pour
  regarder un combat sous un autre angle.
- **Portails dans la pièce** : entre deux combats, un portail s'ouvre sur un mur et devient une fenêtre
  sur le monde suivant (repris des panoramas 360° de TORIX360).
- **Coop à la même table** : deux joueurs en SharePlay partagent le même diorama.
- **Figurines à collectionner** : chaque Gardien est un objet 3D qu'on peut prendre en main et observer.

## Démo

Voir `vision-pro-poc/README.md` pour lancer le jeu en local et le tester sur le casque.
