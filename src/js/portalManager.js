// La matrice des portails qui détermine les connexions entre les mondes
const portalMatrix = {
    0: [1, 2], // Monde 0 peut aller vers les mondes 1 et 2
    1: [0, 2, 3], // Monde 1 peut aller vers les mondes 0, 2 et 3
    2: [0, 1, 3, 4], // Monde 2 peut aller vers les mondes 0, 1, 3 et 4
    3: [1, 2, 4, 5], // Monde 3 peut aller vers les mondes 1, 2, 4 et 5
    4: [2, 3, 5], // Monde 4 peut aller vers les mondes 2, 3 et 5
    5: [3, 4] // Monde 5 peut aller vers les mondes 3 et 4
};

// Fonction pour récupérer les portails disponibles en fonction de l'index du monde
function getAvailablePortals(currentIndex) {
    console.log("Index actuel dans getAvailablePortals:", currentIndex);

    // Vérifie si la matrice est définie et que l'index est valide
    if (!portalMatrix) {
        console.error("La matrice des portails (portalMatrix) est undefined.");
        return []; // Retourne un tableau vide si portalMatrix n'est pas défini
    }
    if (portalMatrix[currentIndex] && Array.isArray(portalMatrix[currentIndex])) {
        console.log("Portails disponibles pour l'index :", portalMatrix[currentIndex]);
        return portalMatrix[currentIndex];
    } else {
        console.warn("Aucun portail disponible pour l'index:", currentIndex);
        return [];
    }
}

// Fonction pour sélectionner un portail aléatoire parmi les portails disponibles
function getRandomPortal(currentIndex) {
    const availablePortals = getAvailablePortals(currentIndex); // Récupère les portails valides
    if (availablePortals.length === 0) {
        console.warn("Aucun portail disponible à partir du monde", currentIndex);
        return null; // Aucun portail valide trouvé
    }
    const randomIndex = Math.floor(Math.random() * availablePortals.length);
    return availablePortals[randomIndex]; // Retourne un portail aléatoire
}

// Exports pour l'utiliser dans d'autres fichiers
export { getAvailablePortals, getRandomPortal, portalMatrix };