import SwiftUI
import RealityKit

// MARK: - ImmersiveView
// The heart of the TORIX experience on Vision Pro.
// Renders the full-immersion RealityKit scene and handles portal navigation.
//
// Architecture mapping (JS → Swift):
//   main.js initialize()         → setup() called in RealityView `make`
//   handlePortalClick()          → handlePortalTap(_:)
//   addStylizedPortals()         → spawnPortals(for:)
//   removePortals()              → portalsRoot.children cleared
//   sphereManager.navigateToSphere() → sphereWorld.transitionToWorld()
//   showInterstitial()           → viewModel.showInterstitial = true

struct ImmersiveView: View {

    @State private var viewModel = WorldViewModel()

    // Root entity for the 6 panoramic spheres
    @State private var sphereWorld = SphereWorldEntity()

    // Container entity for active portals — add/remove children on navigation
    @State private var portalsRoot = Entity()

    var body: some View {
        ZStack {

            // — RealityKit scene —
            RealityView { content in
                // Initial setup (async texture loading)
                await sphereWorld.setup()
                content.add(sphereWorld)

                // The portalsRoot lives here; we mutate its children directly
                content.add(portalsRoot)

                // Spawn portals for World 0 on first load
                spawnPortals(for: 0)

            } update: { _ in
                // SwiftUI-triggered updates (e.g. window resize) — scene manages itself
            }
            // — Tap gesture: look at portal + pinch to travel —
            // SpatialTapGesture requires CollisionComponent + InputTargetComponent on the entity.
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handlePortalTap(value.entity)
                    }
            )

            // — Interstitial narrative overlay —
            if viewModel.showInterstitial {
                InterstitialView(
                    data: viewModel.currentInterstitialData,
                    onClose: { viewModel.dismissInterstitial() }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Show the intro screen for World 0 immediately
            viewModel.showInterstitial = true
        }
    }

    // MARK: - Portal tap handling

    /// Walks the entity hierarchy upward to find a PortalEntity, then navigates.
    /// Mirrors the interactiveAsset.onClick() path in main.js.
    private func handlePortalTap(_ tappedEntity: Entity) {
        var candidate: Entity? = tappedEntity
        while let current = candidate {
            if let portal = current as? PortalEntity {
                navigateTo(worldIndex: portal.destinationIndex)
                return
            }
            candidate = current.parent
        }
    }

    // MARK: - World navigation

    /// Triggers a crossfade to `worldIndex` and refreshes the portal set.
    /// Mirrors handlePortalClick() in main.js.
    private func navigateTo(worldIndex: Int) {
        viewModel.navigateTo(worldIndex: worldIndex) {
            // Called after the interstitial re-appears; portals were already swapped
        }

        Task { @MainActor in
            // 1. Crossfade the panoramic sphere (async, runs for ~1 s)
            await sphereWorld.transitionToWorld(worldIndex)

            // 2. Replace portals with those valid for the new world
            spawnPortals(for: worldIndex)
        }
    }

    // MARK: - Portal management

    /// Creates PortalEntity instances for all worlds reachable from `worldIndex`
    /// and scatters them randomly inside the panoramic sphere.
    /// Mirrors addStylizedPortals() + removePortals() in PortalFunctions.js.
    private func spawnPortals(for worldIndex: Int) {
        // Clear current portals — mirrors removePortals() in JS
        let existing = Array(portalsRoot.children)
        existing.forEach { $0.removeFromParent() }

        // Create one portal per reachable destination — mirrors selectedPortals loop in JS
        let destinations = PortalManager.availablePortals(from: worldIndex)
        for destinationIndex in destinations {
            let portal = PortalEntity(destinationIndex: destinationIndex)

            // Place portal on the inner surface of the sphere, slightly inset so it's visible
            portal.position = randomPositionOnSphere(radius: AppConstants.sphereRadius * 0.88)

            portalsRoot.addChild(portal)
        }
    }

    // MARK: - Sphere surface positioning

    /// Uniform random point on a sphere, biased toward eye level.
    /// Mirrors getRandomPositionOnSphere() in helpers.js — same math, different axis convention.
    private func randomPositionOnSphere(radius: Float) -> SIMD3<Float> {
        // Uniform sampling (Archimedes method — same as the JS version)
        let theta = Float.random(in: 0 ..< (2 * .pi))
        let phi   = acos(Float.random(in: -1 ... 1))

        // Bias portals toward the equator (eye level) so the user doesn't need to
        // look straight up or down to find them. Blend phi toward π/2.
        let biasedPhi = phi * 0.55 + (.pi / 2) * 0.45

        return SIMD3(
            radius * sin(biasedPhi) * cos(theta),   // x
            radius * cos(biasedPhi) * 0.4,           // y — compressed for comfort
            radius * sin(biasedPhi) * sin(theta)    // z
        )
    }
}
