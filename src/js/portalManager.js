// portalManager.js

export const portalMatrix = {
  0: [1, 2, 3],  // Sphère 1 peut aller vers Sphère 2, 3, et 4
  1: [0, 2, 4],  // Sphère 2 peut aller vers Sphère 1, 3, et 5
  2: [0, 1, 5],  // Sphère 3 peut aller vers Sphère 1, 2, et 6
  3: [0, 4, 5],  // Sphère 4 peut aller vers Sphère 1, 5, et 6
  4: [1, 3, 5],  // Sphère 5 peut aller vers Sphère 2, 4, et 6
  5: [2, 3, 4],  // Sphère 6 peut aller vers Sphère 3, 4, et 5
};

export function getAvailablePortals(currentIndex) {
  // Récupère les portails disponibles pour la sphère donnée
  return portalMatrix[currentIndex] || [];
}

export function getRandomPortal(currentIndex) {
  // Sélectionne un portail aléatoire parmi ceux disponibles pour la sphère donnée
  const availablePortals = getAvailablePortals(currentIndex);
  const randomIndex = Math.floor(Math.random() * availablePortals.length);
  return availablePortals[randomIndex];
}