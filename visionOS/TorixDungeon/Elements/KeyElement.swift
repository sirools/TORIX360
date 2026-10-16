import RealityKit
import UIKit

/// Clé dorée : anneau, tige et panneton. Construite de profil (tige selon X).
enum KeyElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.035, spinSpeed: 0.7, riseDistance: 0.25)
    static let reactionNotes: [Double] = [659.3, 784.0, 1318.5]
    static let particleColor = Palette.gold

    static func makeModel() -> Entity {
        let root = Entity()
        let gold = Primitives.lit(Palette.gold, roughness: 0.3, metallic: 1)

        // Anneau : une couronne de petites sphères
        let ringCenter: SIMD3<Float> = [-0.1, 0, 0]
        for i in 0..<14 {
            let angle = Float(i) * 2 * .pi / 14
            root.addChild(Primitives.sphere(0.012, gold,
                                            at: ringCenter + [cos(angle) * 0.04, sin(angle) * 0.04, 0]))
        }
        root.addChild(Primitives.sphere(0.012, Primitives.glowing(Palette.mauve), at: ringCenter))

        // Tige horizontale
        let shaft = Primitives.cylinder(height: 0.2, radius: 0.009, gold, at: [0.04, 0, 0])
        shaft.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        root.addChild(shaft)

        // Dents
        root.addChild(Primitives.box([0.018, 0.04, 0.012], gold, at: [0.105, -0.022, 0]))
        root.addChild(Primitives.box([0.018, 0.028, 0.012], gold, at: [0.13, -0.016, 0]))

        return root
    }
}
