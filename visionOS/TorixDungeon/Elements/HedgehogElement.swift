import RealityKit
import UIKit

/// Hérisson stylisé : corps ovale, museau, et une cinquantaine de piquants.
enum HedgehogElement: DungeonElement {
    static let levitation = LevitationTuning(amplitude: 0.02, spinSpeed: 0, riseDistance: 0.15)
    static let reactionNotes: [Double] = [880.0, 987.8, 880.0]
    static let particleColor = Palette.ochre

    static func makeModel() -> Entity {
        let root = Entity()
        let radii: SIMD3<Float> = [0.12, 0.095, 0.145]

        // Corps
        root.addChild(Primitives.sphere(1, Primitives.lit(Palette.hedgehogBody), scale: radii))

        // Museau (pointe vers +Z)
        let snoutMaterial = Primitives.lit(Palette.hedgehogSnout, roughness: 0.7)
        let snout = Primitives.cone(height: 0.09, radius: 0.045, snoutMaterial, at: [0, -0.015, 0.16])
        snout.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        root.addChild(snout)

        // Truffe, yeux, oreilles
        let black = Primitives.lit(Palette.black, roughness: 0.3)
        root.addChild(Primitives.sphere(0.014, black, at: [0, -0.012, 0.205]))
        root.addChild(Primitives.sphere(0.011, black, at: [0.042, 0.022, 0.125]))
        root.addChild(Primitives.sphere(0.011, black, at: [-0.042, 0.022, 0.125]))
        root.addChild(Primitives.sphere(0.018, snoutMaterial, at: [0.06, 0.06, 0.08], scale: [1, 1, 0.5]))
        root.addChild(Primitives.sphere(0.018, snoutMaterial, at: [-0.06, 0.06, 0.08], scale: [1, 1, 0.5]))

        // Pattes
        for x: Float in [-0.06, 0.06] {
            for z: Float in [-0.06, 0.07] {
                root.addChild(Primitives.sphere(0.022, snoutMaterial, at: [x, -0.085, z]))
            }
        }

        // Piquants : répartis sur le dos (spirale de Fibonacci), orientés vers l'extérieur.
        let spikeMesh = MeshResource.generateCone(height: 0.075, radius: 0.012)
        let spikeMaterial = Primitives.lit(Palette.hedgehogSpikes, roughness: 0.6)
        let count = 120
        let golden = Float.pi * (3 - sqrt(5))
        for i in 0..<count {
            let y = 1 - 2 * (Float(i) + 0.5) / Float(count)
            let ring = sqrt(1 - y * y)
            let theta = golden * Float(i)
            let normal = SIMD3<Float>(cos(theta) * ring, y, sin(theta) * ring)
            // Pas de piquants sous le ventre ni sur le visage.
            guard normal.y > -0.15, normal.z < 0.45 else { continue }

            let spike = ModelEntity(mesh: spikeMesh, materials: [spikeMaterial])
            let direction = simd_normalize(normal / radii)   // normale de l'ellipsoïde
            spike.position = normal * radii + direction * 0.02
            spike.orientation = simd_quatf(from: [0, 1, 0], to: simd_normalize(direction + [0, 0, -0.5]))
            root.addChild(spike)
        }

        return root
    }
}
