#!/usr/bin/env bash
# Installe (ou met à jour) tout le projet TORIX360 + le POC visionOS dans un dossier local.
#
# Depuis le dossier voulu, dans le Terminal :
#   cd ~/TORIX/POC_Ankama_Dofus_VR
#   curl -fsSL https://raw.githubusercontent.com/sirools/TORIX360/claude/visionos-donjon-v0/visionOS/scripts/installer-poc.sh | bash
#
# Ce que fait le script :
#   1. clone le dépôt (branche du POC) dans le dossier courant s'il est vide,
#      sinon dans un sous-dossier « TORIX360-repo » ; s'il est déjà cloné, le met à jour ;
#   2. si un projet Xcode à toi est trouvé dans le dossier (ex. « TORIX360 » créé avec
#      le modèle visionOS), y importe le code du donjon (fichiers du modèle mis de côté) ;
#   3. ouvre le projet dans Xcode.

set -euo pipefail

REPO_URL="https://github.com/sirools/TORIX360.git"
BRANCH="claude/visionos-donjon-v0"
TARGET="$(pwd)"

command -v git >/dev/null || { echo "git est requis (xcode-select --install)." >&2; exit 1; }

# 1. Récupérer le dépôt.
if [ -d "$TARGET/.git" ] && [ -d "$TARGET/visionOS" ]; then
    REPO="$TARGET"
elif [ -d "$TARGET/TORIX360-repo/.git" ]; then
    REPO="$TARGET/TORIX360-repo"
elif [ -z "$(ls -A "$TARGET" | grep -v "^.DS_Store$" || true)" ]; then
    # Dossier vide (à part un éventuel .DS_Store) : on clone sur place.
    REPO="$TARGET"
    git -C "$REPO" init -q
    git -C "$REPO" remote add origin "$REPO_URL"
    git -C "$REPO" fetch -q origin "$BRANCH"
    git -C "$REPO" checkout -q -b "$BRANCH" --track "origin/$BRANCH"
else
    REPO="$TARGET/TORIX360-repo"
    git clone --branch "$BRANCH" "$REPO_URL" "$REPO"
fi

if [ -d "$REPO/.git" ] && [ "$(git -C "$REPO" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] \
   && [ -z "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]; then
    git -C "$REPO" pull --ff-only origin "$BRANCH" || true
fi

echo
echo "Dépôt : $REPO"

# 2. Un projet Xcode personnel à côté du dépôt ? (hors projet du dépôt lui-même)
OWN_PROJECT=$(find "$TARGET" -maxdepth 3 -name '*.xcodeproj' -not -path "$REPO/*" 2>/dev/null | head -1 || true)

if [ -n "$OWN_PROJECT" ]; then
    echo "Projet Xcode trouvé : $OWN_PROJECT"
    "$REPO/visionOS/scripts/importer-dans-projet.sh" "$(dirname "$OWN_PROJECT")"
    PROJECT_TO_OPEN="$OWN_PROJECT"
else
    PROJECT_TO_OPEN="$REPO/visionOS/TorixDungeon.xcodeproj"
    echo "Aucun projet Xcode personnel trouvé : on utilise celui du dépôt."
fi

# 3. Ouvrir dans Xcode.
echo
echo "Ouverture de $PROJECT_TO_OPEN"
echo "Dans Xcode : Signing & Capabilities › Team = ta Personal Team, puis ⇧⌘K et ⌘R."
open "$PROJECT_TO_OPEN" 2>/dev/null || true
