import RealityKit
import UIKit

// MARK: - SphereWorldEntity
// Manages the 6 panoramic sphere worlds and crossfade transitions between them.
// Equivalent to SphereManager in sphereManager.js.
//
// Each world is a ModelEntity — a large sphere (radius = AppConstants.sphereRadius)
// whose normals are flipped inward (scale.x = -1) so the user sees the panoramic
// artwork from *inside* the sphere, exactly as in the Three.js version.

@MainActor
final class SphereWorldEntity: Entity {

    // One sphere per world (artwork1 … artwork-final-V1)
    private var sphereEntities: [ModelEntity] = []

    private(set) var currentIndex: Int = 0

    // Image names must match the files you drag into Assets.xcassets in Xcode
    private static let imageNames: [String] = [
        "artwork1",
        "artwork2",
        "artwork3",
        "artwork4",
        "artwork5",
        "artwork-final-V1"
    ]

    required init() {
        super.init()
    }

    // Call once, inside the RealityView `make` closure (async context).
    // Loads textures and creates all sphere entities.
    func setup() async {
        for (index, imageName) in SphereWorldEntity.imageNames.enumerated() {
            let entity = await makeSphere(
                imageName: imageName,
                initialOpacity: index == 0 ? 1.0 : 0.0
            )
            addChild(entity)
            sphereEntities.append(entity)
        }
    }

    // MARK: - Sphere factory

    private func makeSphere(imageName: String, initialOpacity: Float) async -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: AppConstants.sphereRadius)

        // Build an UnlitMaterial — no lighting so the panorama looks like the original.
        var material = UnlitMaterial()
        if let texture = try? await TextureResource(named: imageName) {
            material.color = .init(
                tint: .white.withAlphaComponent(CGFloat(initialOpacity)),
                texture: .init(texture)
            )
        }

        let entity = ModelEntity(mesh: mesh, materials: [material])

        // Flip normals inward — mirrors `sphereGeometry.scale(-1, 1, 1)` in sphereManager.js
        entity.scale = SIMD3(-1, 1, 1)

        // Opacity component for crossfade animation
        entity.components[OpacityComponent.self] = OpacityComponent(opacity: initialOpacity)

        return entity
    }

    // MARK: - Crossfade transition
    // Mirrors crossfadeTransition() + easeInOut() in sphereManager.js.
    // Runs as an async Task so the caller can await completion.

    func transitionToWorld(_ nextIndex: Int) async {
        guard nextIndex < sphereEntities.count, nextIndex != currentIndex else { return }

        let previousIndex = currentIndex
        let totalSteps = 60
        let stepDuration: Double = AppConstants.transitionDuration / Double(totalSteps)

        for step in 0...totalSteps {
            let rawProgress = Double(step) / Double(totalSteps)
            let eased = easeInOut(rawProgress)

            sphereEntities[previousIndex].components[OpacityComponent.self]?.opacity = Float(1.0 - eased)
            sphereEntities[nextIndex].components[OpacityComponent.self]?.opacity = Float(eased)

            try? await Task.sleep(for: .seconds(stepDuration))
        }

        currentIndex = nextIndex
    }

    // t ∈ [0,1] → smooth ease-in-out — mirrors SphereManager.easeInOut() in sphereManager.js
    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
}
