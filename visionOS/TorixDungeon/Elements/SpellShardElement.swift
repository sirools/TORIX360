import RealityKit
import UIKit

/// Éclat de sort : cristal lumineux qui tourne, entouré de particules.
enum SpellShardElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.05, spinSpeed: 1.1, riseDistance: 0.3)
    static let reactionNotes: [Double] = [1046.5, 1318.5, 1568.0, 2093.0]
    static let particleColor = Palette.spellCyan

    static func makeModel() -> Entity {
        let root = Entity()
        let crystal = Primitives.unlit(Palette.spellCyan)

        // Double pointe (octaèdre étiré)
        root.addChild(Primitives.cone(height: 0.16, radius: 0.055, crystal, at: [0, 0.08, 0]))
        let bottom = Primitives.cone(height: 0.12, radius: 0.055, crystal, at: [0, -0.06, 0])
        bottom.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        root.addChild(bottom)

        // Petits éclats satellites
        for i in 0..<3 {
            let angle = Float(i) * 2 * .pi / 3
            let shard = Primitives.cone(height: 0.05, radius: 0.015, crystal,
                                        at: [cos(angle) * 0.11, 0.02 * Float(i), sin(angle) * 0.11])
            shard.orientation = simd_quatf(angle: 0.4, axis: [cos(angle), 0, sin(angle)])
            root.addChild(shard)
        }

        // Halo de lumière
        let glow = Entity()
        glow.components.set(PointLightComponent(color: Palette.spellCyan, intensity: 600,
                                                attenuationRadius: 1.8))
        glow.components.set(FlickerComponent(baseIntensity: 600))
        root.addChild(glow)

        // Poussière magique continue
        var magic = ParticleEmitterComponent.Presets.magic
        magic.emitterShape = .sphere
        magic.emitterShapeSize = [0.18, 0.18, 0.18]
        magic.mainEmitter.birthRate = 40
        magic.mainEmitter.size = 0.008
        magic.mainEmitter.color = .constant(.single(Palette.spellCyan))
        let dust = Entity()
        dust.components.set(magic)
        root.addChild(dust)

        return root
    }
}
