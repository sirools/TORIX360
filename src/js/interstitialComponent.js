// interstitialComponent.js

export const interstitialData = [
    { title: "Interstitiel 1", subtitle: "Bienvenue dans le labyrinthe !" },
    { title: "Interstitiel 2", subtitle: "Prêt pour le voyage ?" },
    { title: "Interstitiel 3", subtitle: "Explorez chaque sphère !" },
    { title: "Interstitiel 4", subtitle: "Attention, un défi vous attend." },
    { title: "Interstitiel 5", subtitle: "Vous êtes presque au bout !" },
    { title: "Interstitiel 6", subtitle: "La fin approche. Bonne chance !" },
    { title: "Interstitiel 7", subtitle: "Bravo, vous avez terminé !" }
];

export function showInterstitial(index) {
    const interstitial = document.getElementById("interstitial");
    const title = document.getElementById("interstitial-title");
    const subtitle = document.getElementById("interstitial-subtitle");

    // Affichage de l'interstitiel avec le bon titre et sous-titre
    const currentInterstitial = interstitialData[index];
    title.textContent = currentInterstitial.title;
    subtitle.textContent = currentInterstitial.subtitle;

    // Affichage du container de l'interstitiel
    interstitial.style.display = "block";
    
    // Ajouter le message "Cliquez pour continuer"
    const clickMessage = document.getElementById("interstitial-click");
    clickMessage.textContent = "Cliquez pour continuer";

    // Animation ou transition si nécessaire (par exemple, fade-in)
    interstitial.classList.add("fade-in");

    // Ajouter un gestionnaire d'événements pour fermer l'interstitiel lorsque l'on clique à l'extérieur
    interstitial.addEventListener("click", function(event) {
        const closeButton = document.getElementById("interstitial-close");
        const textArea = document.getElementById("interstitial-title") || document.getElementById("interstitial-subtitle");

        // Si l'utilisateur clique en dehors du bouton ou du texte, on ferme l'interstitiel
        if (!closeButton.contains(event.target) && !textArea.contains(event.target)) {
            hideInterstitial();
        }
    });
}

export function hideInterstitial() {
    const interstitial = document.getElementById("interstitial");

    // Masquer le container de l'interstitiel
    interstitial.style.display = "none";

    // Enlever l'animation fade-in pour le prochain affichage
    interstitial.classList.remove("fade-in");
}

// Gestionnaire de clic sur le bouton "Fermer"
document.getElementById("interstitial-close").addEventListener("click", () => {
    hideInterstitial();  // Masquer l'interstitiel quand le bouton est cliqué
});