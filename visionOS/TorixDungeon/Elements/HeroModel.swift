import RealityKit
import UIKit

/// Petit aventurier stylisé pour le plateau tactique : cape ocre, tunique mauve,
/// souliers ocre et mauve, bâton surmonté d'un éclat de sort.
/// Environ 12 cm de haut, face avant vers +Z, pieds à y = 0.
@MainActor
enum HeroModel {
    static func make() -> Entity {
        let root = Entity()
        let ochre = Primitives.lit(Palette.ochre, roughness: 0.7)
        let mauve = Primitives.lit(Palette.mauve, roughness: 0.65)
        let mauveDark = Primitives.lit(Palette.mauveDark, roughness: 0.8)
        let skin = Primitives.lit(Palette.skin, roughness: 0.6)
        let wood = Primitives.lit(Palette.wood)

        // Souliers (clin d'œil au soulier ocre et mauve du donjon)
        root.addChild(Primitives.box([0.016, 0.01, 0.026], ochre, cornerRadius: 0.004, at: [-0.011, 0.005, 0.004]))
        root.addChild(Primitives.box([0.016, 0.01, 0.026], mauve, cornerRadius: 0.004, at: [0.011, 0.005, 0.004]))

        // Jambes, tunique, ceinture
        root.addChild(Primitives.cylinder(height: 0.025, radius: 0.007, mauveDark, at: [-0.01, 0.022, 0]))
        root.addChild(Primitives.cylinder(height: 0.025, radius: 0.007, mauveDark, at: [0.01, 0.022, 0]))
        root.addChild(Primitives.cylinder(height: 0.04, radius: 0.022, mauve, at: [0, 0.052, 0]))
        root.addChild(Primitives.cylinder(height: 0.006, radius: 0.0235, ochre, at: [0, 0.045, 0]))

        // Cape
        let cape = Primitives.box([0.04, 0.05, 0.004], ochre, cornerRadius: 0.002, at: [0, 0.055, -0.024])
        cape.orientation = simd_quatf(angle: 0.18, axis: [1, 0, 0])
        root.addChild(cape)

        // Tête, capuche, yeux
        root.addChild(Primitives.sphere(0.022, skin, at: [0, 0.092, 0]))
        root.addChild(Primitives.sphere(0.024, ochre, at: [0, 0.098, -0.006], scale: [1, 0.9, 1]))
        let eye = Primitives.lit(Palette.black, roughness: 0.3)
        root.addChild(Primitives.sphere(0.0035, eye, at: [-0.008, 0.094, 0.02]))
        root.addChild(Primitives.sphere(0.0035, eye, at: [0.008, 0.094, 0.02]))

        // Bâton et son éclat lumineux
        root.addChild(Primitives.cylinder(height: 0.11, radius: 0.003, wood, at: [0.032, 0.055, 0.008]))
        let crystal = Primitives.unlit(Palette.spellCyan)
        root.addChild(Primitives.cone(height: 0.016, radius: 0.007, crystal, at: [0.032, 0.118, 0.008]))

        return root
    }
}
