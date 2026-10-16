import RealityKit
import UIKit

/// Soulier ocre et mauve, à bout recourbé. Construit de profil (pointe vers +X)
/// et tourne lentement sur lui-même pour être vu sous tous les angles.
enum ShoeElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.04, spinSpeed: 0.4, riseDistance: 0.25)
    static let reactionNotes: [Double] = [392.0, 493.9, 587.3]
    static let particleColor = Palette.mauve

    static func makeModel() -> Entity {
        let root = Entity()
        let ochre = Primitives.lit(Palette.ochre, roughness: 0.7)
        let ochreDark = Primitives.lit(Palette.ochreDark, roughness: 0.8)
        let mauve = Primitives.lit(Palette.mauve, roughness: 0.65)
        let mauveDark = Primitives.lit(Palette.mauveDark, roughness: 0.8)

        // Semelle et talon
        root.addChild(Primitives.box([0.3, 0.025, 0.1], ochreDark, cornerRadius: 0.01, at: [0, 0, 0]))
        root.addChild(Primitives.box([0.055, 0.05, 0.09], ochreDark, cornerRadius: 0.01, at: [-0.12, -0.03, 0]))

        // Tige mauve et col
        root.addChild(Primitives.box([0.17, 0.09, 0.095], mauve, cornerRadius: 0.035, at: [-0.05, 0.055, 0]))
        root.addChild(Primitives.cylinder(height: 0.012, radius: 0.04, mauveDark, at: [-0.07, 0.1, 0]))

        // Empeigne ocre
        root.addChild(Primitives.sphere(0.055, ochre, at: [0.07, 0.035, 0], scale: [1.7, 0.75, 0.9]))

        // Pointe recourbée vers le haut
        let tip = Primitives.cone(height: 0.09, radius: 0.028, ochre, at: [0.17, 0.06, 0])
        tip.orientation = simd_quatf(angle: -1.05, axis: [0, 0, 1])
        root.addChild(tip)

        // Pompon mauve au bout
        root.addChild(Primitives.sphere(0.022, mauve, at: [0.21, 0.09, 0]))

        // Petite bande décorative
        root.addChild(Primitives.box([0.012, 0.07, 0.1], ochre, at: [0.02, 0.05, 0]))

        return root
    }
}
