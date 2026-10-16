import RealityKit
import UIKit

/// Chandelle : la première lumière du donjon.
enum CandleElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.025, spinSpeed: 0, riseDistance: 0.2)
    static let reactionNotes: [Double] = [523.3, 659.3]
    static let particleColor = Palette.flame

    static func makeModel() -> Entity {
        let root = Entity()

        // Bougeoir
        root.addChild(Primitives.cylinder(height: 0.015, radius: 0.07,
                                          Primitives.lit(Palette.iron, roughness: 0.5, metallic: 0.8)))
        // Cire
        let wax = Primitives.lit(Palette.wax, roughness: 0.6)
        root.addChild(Primitives.cylinder(height: 0.2, radius: 0.033, wax, at: [0, 0.107, 0]))
        // Coulures
        root.addChild(Primitives.sphere(0.012, wax, at: [0.03, 0.17, 0.01], scale: [0.7, 1.6, 0.7]))
        root.addChild(Primitives.sphere(0.01, wax, at: [-0.025, 0.14, 0.02], scale: [0.7, 1.8, 0.7]))
        // Mèche
        root.addChild(Primitives.cylinder(height: 0.015, radius: 0.002,
                                          Primitives.unlit(Palette.black), at: [0, 0.214, 0]))

        // Flamme : elle porte la lumière et vacille.
        let flame = Entity()
        flame.position = [0, 0.235, 0]
        flame.addChild(Primitives.sphere(0.016, Primitives.unlit(Palette.flame), scale: [0.65, 1.5, 0.65]))
        flame.addChild(Primitives.sphere(0.008, Primitives.unlit(Palette.flameCore),
                                         at: [0, -0.004, 0], scale: [0.7, 1.4, 0.7]))
        flame.components.set(PointLightComponent(color: Palette.torchLight, intensity: 900,
                                                 attenuationRadius: 2.5))
        flame.components.set(FlickerComponent(baseIntensity: 900))
        root.addChild(flame)

        return root
    }
}
