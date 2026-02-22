import RealityKit
import UIKit

// MARK: - PortalEntity
// A small coloured sphere that the user looks at then pinches to travel to another world.
// Equivalent to the portal meshes created in addStylizedPortals() in PortalFunctions.js.
//
// Interaction model on Vision Pro:
//   • User looks at portal → HoverEffectComponent highlights it automatically
//   • User pinches (index + thumb) → SpatialTapGesture fires → handlePortalTap() in ImmersiveView
//
// Each portal needs three components to be tappable:
//   1. CollisionComponent — gives it a hit-test volume
//   2. InputTargetComponent — marks it as an interaction target
//   3. HoverEffectComponent — built-in visual feedback when the user gazes at it

@MainActor
final class PortalEntity: Entity {

    /// The world index this portal leads to (0-5)
    let destinationIndex: Int

    // Required by RealityKit — not used directly
    required init() {
        self.destinationIndex = 0
        super.init()
    }

    init(destinationIndex: Int) {
        self.destinationIndex = destinationIndex
        super.init()
        setupComponents()
    }

    // MARK: - Setup

    private func setupComponents() {
        let mesh = MeshResource.generateSphere(radius: AppConstants.portalRadius)

        // Portal colour matches its destination world (mirrors the texture array in PortalFunctions.js)
        let uiColor = PortalManager.color(for: destinationIndex)
        let material = UnlitMaterial(color: uiColor)

        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        // — Point light: mirrors `new THREE.PointLight(0x00ff00, 1, 100)` in PortalFunctions.js —
        var light = PointLightComponent()
        light.color = uiColor
        light.intensity = 800          // lumens — brighter than the JS version to stand out in XR
        light.attenuationRadius = 3    // metres
        modelEntity.components[PointLightComponent.self] = light

        // — Collision volume (slightly larger than the visual sphere for easier targeting) —
        let hitShape = ShapeResource.generateSphere(radius: AppConstants.portalRadius * 1.8)
        modelEntity.components[CollisionComponent.self] = CollisionComponent(shapes: [hitShape])

        // — Input target: marks this entity as tappable —
        modelEntity.components[InputTargetComponent.self] = InputTargetComponent()

        // — Hover highlight: Vision Pro shows a built-in glow when the user looks at it —
        //   This replaces the red colour-change on hover from PortalFunctions.js
        modelEntity.components[HoverEffectComponent.self] = HoverEffectComponent()

        addChild(modelEntity)

        // — Idle pulsing animation (replaces the scale tween from helpers.js) —
        addPulseAnimation()
    }

    // MARK: - Pulse animation
    // Gently scales the portal up and down so it's easier to spot in the panorama.

    private func addPulseAnimation() {
        let scaleUp = FromToByAnimation<Transform>(
            name: "pulseUp",
            from: Transform(scale: SIMD3(1.0, 1.0, 1.0)),
            to:   Transform(scale: SIMD3(1.25, 1.25, 1.25)),
            duration: 1.2,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )

        if let resource = try? AnimationResource.generate(with: scaleUp) {
            playAnimation(resource)
        }
    }
}
