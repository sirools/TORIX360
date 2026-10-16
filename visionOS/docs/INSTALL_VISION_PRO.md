# Installer le donjon sur l'Apple Vision Pro (sans App Store)

Méthode « développement personnel » : Xcode signe l'app avec ton identifiant Apple et
l'installe directement sur le casque. Aucune publication, aucun TestFlight.

## Ce qu'il faut

- Un Mac (Apple Silicon conseillé) avec **Xcode 16 ou plus récent** et le composant visionOS.
- L'Apple Vision Pro à jour, sur **le même réseau Wi-Fi** que le Mac.
- Un **identifiant Apple** (le gratuit suffit). Avec un compte gratuit :
  - l'app **expire au bout de 7 jours** : il suffit de relancer depuis Xcode pour la renouveler ;
  - 3 apps de développement max par appareil, quelques identifiants d'app par semaine.
  - Le programme payant (99 €/an) porte la durée à 1 an et ouvre TestFlight si besoin plus tard.

## 1. Ajouter ton compte dans Xcode

Xcode › Settings… › **Accounts** › **+** › Apple ID → se connecter.
Une équipe « *Ton Nom (Personal Team)* » apparaît.

## 2. Configurer la signature du projet

1. Ouvrir `visionOS/TorixDungeon.xcodeproj`.
2. Sélectionner le projet › cible **TorixDungeon** › onglet **Signing & Capabilities**.
3. Cocher **Automatically manage signing**, choisir ta **Personal Team** dans *Team*.
4. **Bundle Identifier** : il doit être unique au monde. Remplacer `com.torix360.donjon` par
   quelque chose de personnel, ex. `com.tonpseudo.torix360.donjon`.
   (Message « Failed to register bundle identifier » = identifiant déjà pris → en changer.)

## 3. Activer le mode développeur et appairer le casque

1. Sur le Vision Pro : **Réglages › Général › Gestion des appareils distants**
   (*Remote Devices*) — laisser cet écran ouvert, le casque devient visible pour le Mac.
2. Sur le Mac : Xcode › **Window › Devices and Simulators** › onglet *Devices*.
   Le Vision Pro apparaît dans la liste « Discovered » → **Pair**.
3. Un code à 6 chiffres s'affiche dans le casque : le saisir dans Xcode.
4. Activer le **Mode développeur** sur le casque : **Réglages › Confidentialité et sécurité ›
   Mode développeur** → activer, redémarrer, confirmer après redémarrage.
   (L'option n'apparaît souvent qu'après le premier appairage avec Xcode.)
5. Attendre la fin de la préparation de l'appareil dans Xcode (« Preparing… », copie des
   symboles : plusieurs minutes la première fois).

## 4. Lancer

1. Dans la barre d'outils d'Xcode, destination = **ton Apple Vision Pro**.
2. **⌘R**. Le premier build est plus long.
3. Au premier lancement, le casque peut refuser une app d'un « développeur non approuvé » :
   **Réglages › Général › VPN et gestion de l'appareil** › ton identifiant › **Faire confiance**,
   puis relancer.

L'app s'appelle **Donjon** sur la grille d'accueil ; elle reste lançable sans le Mac jusqu'à
l'expiration du profil (7 jours en compte gratuit).

## Dépannage

| Symptôme | Piste |
|---|---|
| Le casque n'apparaît pas dans Xcode | Même Wi-Fi, écran *Gestion des appareils distants* ouvert, Mac et casque à jour, redémarrer les deux. |
| « Developer Mode disabled » | Étape 3.4, puis redémarrage du casque. |
| « Untrusted developer » | Étape 4.3. |
| « Failed to register bundle identifier » | Changer le Bundle Identifier (étape 2.4). |
| L'app ne se lance plus après une semaine | Profil gratuit expiré : rebrancher et relancer depuis Xcode. |
| Pas de son de voix | Volume du casque ; essayer *Voix : Synthèse* ; installer une voix française dans Réglages › Accessibilité › Contenu énoncé › Voix. |
| NAS non joignable | Accepter l'alerte « réseau local » (Réglages › Confidentialité › Réseau local › Donjon), vérifier l'URL depuis Safari du casque. |
