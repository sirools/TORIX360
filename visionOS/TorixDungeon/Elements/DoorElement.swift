import RealityKit
import UIKit

/// La porte finale. Elle sort du sol, laisse filtrer une lueur par-dessous…
/// et s'ouvre sur un mur de pierre : le donjon n'a pas de sortie.
enum DoorElement: DungeonElement {
    static let pivotName = "DoorPivot"

    // Pas de flottement : la porte « pousse » depuis le sol.
    static let levitation = LevitationTuning(amplitude: 0, spinSpeed: 0, riseDistance: 2.4, fadeInDuration: 3.5)
    static let reactionNotes: [Double] = [130.8, 98.0]
    static let particleColor = Palette.stoneLight

    static let width: Float = 1.1
    static let height: Float = 2.1

    static func makeModel() -> Entity {
        let root = Entity()
        let stone = Primitives.lit(Palette.stoneLight, roughness: 0.95)
        let stoneDark = Primitives.lit(Palette.stoneDark, roughness: 0.95)
        let wood = Primitives.lit(Palette.wood, roughness: 0.8)
        let woodDark = Primitives.lit(Palette.woodDark, roughness: 0.9)
        let iron = Primitives.lit(Palette.iron, roughness: 0.45, metallic: 0.9)

        // Encadrement de pierre
        root.addChild(Primitives.box([0.2, height + 0.2, 0.32], stone, at: [-(width / 2 + 0.1), (height + 0.2) / 2, 0]))
        root.addChild(Primitives.box([0.2, height + 0.2, 0.32], stone, at: [width / 2 + 0.1, (height + 0.2) / 2, 0]))
        root.addChild(Primitives.box([width + 0.4, 0.22, 0.34], stone, at: [0, height + 0.11, 0]))
        root.addChild(Primitives.box([width + 0.4, 0.04, 0.4], stone, at: [0, 0.02, 0]))

        // Derrière la porte : un mur. Rien d'autre.
        for row in 0..<6 {
            let y = Float(row) * 0.35 + 0.2
            let offset: Float = row.isMultiple(of: 2) ? 0 : 0.18
            for column in -1...1 {
                let x = Float(column) * 0.37 + offset
                guard abs(x) < width / 2 else { continue }
                root.addChild(Primitives.box([0.35, 0.33, 0.06], row.isMultiple(of: 2) ? stoneDark : stone,
                                             cornerRadius: 0.01, at: [x, y, -0.13]))
            }
        }
        root.addChild(Primitives.box([width, height, 0.02], Primitives.lit(Palette.black), at: [0, height / 2, -0.17]))

        // Lueur sous la porte, qui fait croire à une issue.
        root.addChild(Primitives.box([width - 0.1, 0.012, 0.05], Primitives.unlit(Palette.flameCore), at: [0, 0.046, 0.05]))
        let tease = Entity()
        tease.position = [0, 0.1, 0.3]
        tease.components.set(PointLightComponent(color: Palette.torchLight, intensity: 400, attenuationRadius: 1.5))
        tease.components.set(FlickerComponent(baseIntensity: 400))
        root.addChild(tease)

        // Battant sur charnière (pivot au bord gauche)
        let pivot = Entity()
        pivot.name = pivotName
        pivot.position = [-width / 2, 0.06, 0.02]
        root.addChild(pivot)

        let panel = Entity()
        panel.position = [width / 2, height / 2, 0]
        pivot.addChild(panel)
        panel.addChild(Primitives.box([width - 0.02, height - 0.04, 0.06], wood, cornerRadius: 0.01))
        for i in 1..<4 {   // rainures des planches
            let x = -width / 2 + Float(i) * width / 4
            panel.addChild(Primitives.box([0.012, height - 0.06, 0.004], woodDark, at: [x, 0, 0.031]))
        }
        for y: Float in [-0.6, 0.6] {   // pentures en fer
            panel.addChild(Primitives.box([width - 0.04, 0.07, 0.012], iron, at: [0, y, 0.036]))
        }
        panel.addChild(Primitives.sphere(0.035, iron, at: [width / 2 - 0.14, 0, 0.06]))
        panel.addChild(Primitives.cylinder(height: 0.012, radius: 0.06, iron, at: [width / 2 - 0.14, -0.07, 0.05]))

        return root
    }

    /// Ouvre le battant (animation de transform).
    static func open(_ door: Entity) {
        guard let pivot = door.findEntity(named: pivotName) else { return }
        var transform = pivot.transform
        transform.rotation = simd_quatf(angle: -.pi * 0.62, axis: [0, 1, 0])
        pivot.move(to: transform, relativeTo: pivot.parent, duration: 2.2, timingFunction: .easeInOut)
    }
}
