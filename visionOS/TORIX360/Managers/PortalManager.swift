import UIKit

// MARK: - PortalManager
// Direct Swift translation of portalManager.js + portal color logic from PortalFunctions.js.
// Defines the directed graph of world connections and portal appearance.

enum PortalManager {

    // Adjacency map — mirrors portalMatrix in portalManager.js:
    //   0: [1, 2]        World 0 → Worlds 1 & 2
    //   1: [0, 2, 3]     World 1 → Worlds 0, 2 & 3
    //   2: [0, 1, 3, 4]  World 2 → Worlds 0, 1, 3 & 4
    //   3: [1, 2, 4, 5]  World 3 → Worlds 1, 2, 4 & 5
    //   4: [2, 3, 5]     World 4 → Worlds 2, 3 & 5
    //   5: [3, 4]        World 5 → Worlds 3 & 4
    private static let graph: [Int: [Int]] = [
        0: [1, 2],
        1: [0, 2, 3],
        2: [0, 1, 3, 4],
        3: [1, 2, 4, 5],
        4: [2, 3, 5],
        5: [3, 4]
    ]

    // Maps world index → portal color, mirroring the texture array in PortalFunctions.js:
    //   blue-texture.png   → index 0
    //   green-texture.png  → index 1
    //   yellow-texture.png → index 2
    //   pink-texture.png   → index 3
    //   orange-texture.png → index 4
    //   purple-texture.png → index 5
    private static let colors: [Int: UIColor] = [
        0: .systemBlue,
        1: .systemGreen,
        2: .systemYellow,
        3: .systemPink,
        4: .systemOrange,
        5: .systemPurple
    ]

    // Returns all worlds reachable from `worldIndex` — mirrors getAvailablePortals()
    static func availablePortals(from worldIndex: Int) -> [Int] {
        return graph[worldIndex] ?? []
    }

    // Returns one random reachable world — mirrors getRandomPortal()
    static func randomPortal(from worldIndex: Int) -> Int? {
        return availablePortals(from: worldIndex).randomElement()
    }

    // Returns the UIColor associated with a world's portal
    static func color(for worldIndex: Int) -> UIColor {
        return colors[worldIndex] ?? .white
    }
}
