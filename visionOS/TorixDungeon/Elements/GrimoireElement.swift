import RealityKit
import UIKit

/// Grimoire debout, couverture tournée vers l'utilisateur, avec un sceau qui luit.
enum GrimoireElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.05, spinSpeed: 0, riseDistance: 0.3)
    static let reactionNotes: [Double] = [196.0, 246.9, 293.7, 392.0]
    static let particleColor = Palette.mauve

    static func makeModel() -> Entity {
        let book = Entity()
        let leather = Primitives.lit(Palette.leather, roughness: 0.75)
        let pages = Primitives.lit(Palette.parchment, roughness: 0.9)
        let gold = Primitives.lit(Palette.gold, roughness: 0.35, metallic: 1)

        book.addChild(Primitives.box([0.22, 0.3, 0.012], leather, cornerRadius: 0.004, at: [0, 0, 0.026]))
        book.addChild(Primitives.box([0.22, 0.3, 0.012], leather, cornerRadius: 0.004, at: [0, 0, -0.026]))
        book.addChild(Primitives.box([0.016, 0.3, 0.064], leather, cornerRadius: 0.006, at: [-0.108, 0, 0]))
        book.addChild(Primitives.box([0.208, 0.288, 0.04], pages, at: [0.004, 0, 0]))

        // Coins dorés
        for x: Float in [-0.1, 0.1] {
            for y: Float in [-0.14, 0.14] {
                book.addChild(Primitives.box([0.025, 0.025, 0.014], gold, at: [x, y, 0.027]))
            }
        }

        // Sceau lumineux
        book.addChild(Primitives.sphere(0.035, Primitives.glowing(Palette.mauve, intensity: 2.5),
                                        at: [0.005, 0.01, 0.032], scale: [1, 1, 0.25]))
        book.addChild(Primitives.box([0.12, 0.006, 0.004], gold, at: [0.005, -0.07, 0.033]))

        // Légère inclinaison, comme posé sur un pupitre invisible.
        book.orientation = simd_quatf(angle: -0.2, axis: [1, 0, 0])

        let root = Entity()
        root.addChild(book)
        return root
    }
}
