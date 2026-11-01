#!/usr/bin/env bash
# Importe « Le Donjon sans sortie » dans un projet Xcode visionOS existant,
# par exemple un projet « TORIX360 » créé avec le modèle visionOS d'Xcode.
#
# Usage (depuis la racine du dépôt) :
#   visionOS/scripts/importer-dans-projet.sh /chemin/vers/TORIX360/TORIX360
#
# L'argument est le DOSSIER DE SOURCES de la cible : celui qui contient
# TORIX360App.swift, ContentView.swift, Assets.xcassets…
#
# Ce que fait le script :
#   1. met de côté les fichiers Swift du modèle (Hello world) dans un dossier de
#      sauvegarde placé À CÔTÉ du dossier de sources (sinon Xcode les compilerait) ;
#   2. copie les dossiers du donjon : App, Scenes, Narration, Elements,
#      ResourceAccess et les fichiers Swift d'Assets (pas l'Assets.xcassets) ;
#   3. ajoute DungeonDecor.usda au paquet RealityKitContent du projet s'il existe.
#
# Relançable : une deuxième exécution met simplement à jour les fichiers du donjon.

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage : $0 <dossier de sources du projet Xcode>" >&2
    echo "Exemple : $0 ~/Developer/TORIX360/TORIX360" >&2
    exit 1
fi

SOURCE="$(cd "$(dirname "$0")/../TorixDungeon" && pwd)"
DECOR="$(cd "$(dirname "$0")/../Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets" && pwd)/DungeonDecor.usda"

if [ ! -d "$1" ]; then
    echo "Dossier introuvable : $1" >&2
    exit 1
fi
DEST="$(cd "$1" && pwd)"
PROJECT_ROOT="$(dirname "$DEST")"

if [ "$DEST" = "$SOURCE" ]; then
    echo "La destination est le dossier source du donjon lui-même." >&2
    exit 1
fi

if ! ls "$PROJECT_ROOT"/*.xcodeproj >/dev/null 2>&1; then
    echo "Attention : aucun .xcodeproj trouvé dans $PROJECT_ROOT." >&2
    echo "L'argument doit être le dossier de sources, à côté du .xcodeproj." >&2
    exit 1
fi

echo "Projet  : $(ls -d "$PROJECT_ROOT"/*.xcodeproj | head -1)"
echo "Sources : $DEST"
echo

# 1. Mettre de côté les fichiers Swift du modèle (uniquement ceux à la racine des sources).
TEMPLATE_FILES=$(find "$DEST" -maxdepth 1 -name '*.swift')
if [ -n "$TEMPLATE_FILES" ]; then
    BACKUP="$PROJECT_ROOT/_modele_sauvegarde_$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP"
    find "$DEST" -maxdepth 1 -name '*.swift' -exec mv {} "$BACKUP/" \;
    echo "Fichiers du modèle mis de côté dans : $BACKUP"
    ls "$BACKUP" | sed 's/^/   - /'
    echo
fi

# 2. Copier le code du donjon.
for folder in App Scenes Narration Elements ResourceAccess; do
    mkdir -p "$DEST/$folder"
    cp -R "$SOURCE/$folder/." "$DEST/$folder/"
    echo "Copié : $folder/"
done
mkdir -p "$DEST/Assets"
find "$SOURCE/Assets" -maxdepth 1 -name '*.swift' -exec cp {} "$DEST/Assets/" \;
echo "Copié : Assets/*.swift (l'Assets.xcassets du projet est conservé)"

# 3. Décor Reality Composer Pro (optionnel).
RKASSETS=$(find "$PROJECT_ROOT/Packages" -type d -name '*.rkassets' 2>/dev/null | head -1 || true)
if [ -n "$RKASSETS" ] && [ -f "$DECOR" ]; then
    cp "$DECOR" "$RKASSETS/"
    echo "Copié : DungeonDecor.usda → ${RKASSETS#"$PROJECT_ROOT"/}"
fi

# Info.plist dans le dossier de sources = erreur « Multiple commands produce …/Info.plist ».
if [ -f "$DEST/Info.plist" ]; then
    echo
    echo "Attention : $DEST/Info.plist est dans le dossier de sources."
    echo "Dans Xcode, sélectionne-le et décoche la cible dans « Target Membership »."
fi

echo
echo "Terminé. Dans Xcode : Product › Clean Build Folder (⇧⌘K), puis ⌘R."
