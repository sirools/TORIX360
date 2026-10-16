# Le Donjon sans sortie — POC visionOS (V0)

Expérience immersive personnelle pour Apple Vision Pro : on est enfermé dans un donjon
circulaire, une voix lit le texte fondateur et **chaque phrase fait apparaître un élément**
autour de soi (chandelle, soulier ocre et mauve, hérisson, éclat de sort, clé, grimoire…).
À la fin, une porte surgit du sol… et s'ouvre sur un mur. Le donjon recommence.

> Usage strictement personnel, installé en local via Xcode. Aucun asset, logo ni musique
> d'Ankama : formes géométriques stylisées et palette simplement « inspirée ».

## Lancer dans le simulateur

1. Mac avec **Xcode 16 ou plus récent** et le composant **visionOS** installé
   (Xcode › Settings › Components).
2. Ouvrir `visionOS/TorixDungeon.xcodeproj`.
3. Destination : *Apple Vision Pro* (simulateur), puis **⌘R**.
4. Dans la fenêtre : choisir *Mixte* ou *Totale*, puis **Entrer dans le donjon**.

Dans le simulateur : clic = pincement, glisser avec Option = tourner la tête
(le menu *Device › Reset Camera* recentre la vue). La porte apparaît **derrière** toi.

Installation sur le casque : voir [`docs/INSTALL_VISION_PRO.md`](docs/INSTALL_VISION_PRO.md).

## Ce qui se passe

| Étape | Où dans le code |
|---|---|
| Fenêtre d'accueil, choix immersion/voix/NAS | `App/LaunchView.swift`, `App/AppModel.swift` |
| Ouverture de l'espace immersif `mixed` / `full` | `App/TorixDungeonApp.swift` |
| Salle : dallage, murs de briques, plafond, 4 torches vacillantes, brume, bourdon | `Scenes/Dungeon/DungeonRoomBuilder.swift` |
| Lecture phrase par phrase + attente de la porte + boucle | `Narration/NarrationSequencer.swift` |
| Texte et placement de chaque élément | `Narration/Resources/narration.json` |
| Voix (synthèse FR ou enregistrements avec repli) | `Narration/NarrationVoice.swift` |
| Sous-titres flottants | `Narration/SubtitleView.swift` |
| Apparition (fondu + montée), lévitation, rebond, disparition | `Elements/ElementAnimation.swift` |
| Un fichier par élément | `Elements/*Element.swift` |
| Pincement → rebond, étincelles, carillon spatialisé | `Elements/ElementEffects.swift`, `Scenes/Dungeon/DungeonDirector.swift` |
| Accès aux ressources (bundle → NAS) | `ResourceAccess/ResourceProvider.swift` |
| Couleurs, primitives, sons synthétisés | `Assets/` |
| Décor éditable dans Reality Composer Pro | `Packages/RealityKitContent/` |

### Arborescence

```
visionOS/
├── TorixDungeon.xcodeproj        (dossiers synchronisés : tout fichier ajouté dans TorixDungeon/ est compilé)
├── TorixDungeon-Info.plist       (accès réseau local pour le futur NAS)
├── TorixDungeon/
│   ├── App/                      point d'entrée, fenêtre de lancement, état global
│   ├── Scenes/Dungeon/           salle, metteur en scène, vue immersive
│   ├── Narration/                script JSON, voix, séquenceur, sous-titres
│   ├── Elements/                 un composant par élément invoqué + animations
│   ├── ResourceAccess/           providers bundle / NAS / repli
│   └── Assets/                   palette, primitives, sons placeholder, xcassets
├── Packages/RealityKitContent/   paquet Reality Composer Pro (DungeonDecor.usda)
└── docs/INSTALL_VISION_PRO.md
```

## Itérer rapidement

**Changer le texte** : éditer `narration.json`. Chaque phrase :

```json
{
  "id": "s02",
  "text": "Un jour, un aventurier y oublia un soulier, ocre et mauve…",
  "audio": "Audio/phrase_02.m4a",
  "element": "soulier",
  "placement": { "angle": 30, "distance": 1.5, "height": 1.0 }
}
```

- `angle` en degrés : 0 = devant, 90 = à droite, 180 = derrière, -90 = à gauche.
- `distance` horizontale et `height` au-dessus du sol, en mètres.
- `element` : `chandelle`, `soulier`, `herisson`, `eclatDeSort`, `cle`, `grimoire`, `porte`
  (ou absent : la phrase n'invoque rien).
- Le texte actuel est un **brouillon de remplacement** : y coller le vrai texte fondateur.

**Ajouter un élément** : un cas dans `ElementKind`, un fichier `MonElement.swift` conforme à
`DungeonElement` (modèle tourné vers +Z, notes du carillon, couleur des particules, réglages de
lévitation), une ligne dans `ElementFactory.type(for:)`.

**Régler l'ambiance** : rayon/hauteur de la salle et intensité des torches dans
`DungeonRoomBuilder`, vitesse de la voix dans `SpeechSynthesisVoice` (`rate`, `pitch`),
pauses et délai de boucle dans le JSON.

**Décor visuel** : ouvrir `Packages/RealityKitContent` dans Reality Composer Pro et peupler
`DungeonDecor.usda` (origine = pieds de l'utilisateur, -Z = devant). Il est ajouté
automatiquement à la salle.

## Ressources : bundle d'abord, NAS ensuite

Tout passe par `ResourceProvider` avec des chemins relatifs (`Narration/narration.json`,
`Audio/phrase_01.m4a`…). Aujourd'hui tout vient du bundle. Pour le NAS :

1. Servir un dossier en HTTP sur le réseau local, avec la même arborescence :
   `http://nas.local:8080/torix/Narration/narration.json`, `…/torix/Audio/phrase_01.m4a`.
2. Saisir l'URL de base dans le champ **NAS** de la fenêtre d'accueil.
3. Le NAS est essayé en premier (timeout 3 s) puis le bundle sert de repli : l'app marche
   toujours, même NAS éteint. visionOS demandera l'autorisation « réseau local » au premier accès.

`localFileURL(for:)` met une ressource en cache disque, pour les API qui veulent un fichier
(ex. charger un USDZ venu du NAS avec `Entity(contentsOf:)`).

## Enregistrer la voix

1. Enregistrer une prise par phrase (m4a ou wav), nommées comme dans le JSON :
   `phrase_01.m4a` … `phrase_07.m4a`, `fin.m4a`.
2. Les glisser dans un dossier `TorixDungeon/Narration/Audio/` (ajouté automatiquement au
   bundle) **ou** les déposer sur le NAS dans `Audio/`.
3. Laisser le choix de voix sur **Enregistrée** : toute phrase sans fichier est dite par la
   synthèse, ce qui permet d'enregistrer progressivement.

## Limites connues de la V0

- Le projet est écrit sans assets : tout est en primitives, les sons sont synthétisés à la volée.
- La voix narrative n'est pas spatialisée (les carillons de réaction, eux, le sont).
- En mode *Mixte*, les murs masquent la pièce réelle ; l'éclairage ambiant du système peut
  rendre la salle un peu moins sombre qu'en *Totale*.
- La synthèse vocale utilise la voix française installée sur l'appareil ; une voix « Premium »
  (Réglages › Accessibilité › Contenu énoncé) sonne bien mieux.

## Prochaines étapes

1. **Voix de Clément** : enregistrer les phrases (cf. ci-dessus), puis caler les apparitions
   sur des repères temporels dans la prise (`cueTime` par phrase) plutôt qu'en début de phrase.
2. **Spatialiser l'audio** : jouer la narration depuis une entité « conteur » avec
   `SpatialAudioComponent` (voix qui tourne autour de l'utilisateur, ou qui vient de chaque
   élément), ajouter des sons d'ambiance ponctuels (gouttes, chaînes) placés dans la salle.
3. **Démo de 2 à 3 minutes** : réécrire le JSON en ~10 phrases chronométrées, figer un
   parcours du regard (devant → côtés → derrière pour la porte), ajouter un générique de fin
   discret, tester en *Totale* dans une pièce calme et préparer une capture vidéo
   (Reality Composer Pro / Centre de contrôle › Recopier/Enregistrer).
4. Remplacer les primitives par des modèles USDZ maison (Reality Composer Pro, Blender) servis
   depuis le NAS ; textures de pierre, vraie brume volumétrique, éclairage IBL sombre.
5. Brancher une vraie ouverture vers un second lieu (ou une fausse sortie de plus en plus
   étrange à chaque boucle).
