import SwiftUI
import Observation

// MARK: - InterstitialData
// Direct translation of interstitialData[] in interstitialComponent.js

struct InterstitialData {
    let title: String
    let subtitle: String

    static let all: [InterstitialData] = [
        InterstitialData(
            title: "Monde 1",
            subtitle: "Bienvenue dans le labyrinthe !"
        ),
        InterstitialData(
            title: "Monde 2",
            subtitle: "Prêt pour le voyage ?"
        ),
        InterstitialData(
            title: "Monde 3",
            subtitle: "Explorez chaque sphère !"
        ),
        InterstitialData(
            title: "Monde 4",
            subtitle: "Attention, un défi vous attend."
        ),
        InterstitialData(
            title: "Monde 5",
            subtitle: "Vous êtes presque au bout !"
        ),
        InterstitialData(
            title: "Monde 6",
            subtitle: "La fin approche. Bonne chance !"
        )
    ]
}

// MARK: - WorldViewModel
// Holds all reactive state for the TORIX experience.
// Equivalent to the global state scattered in main.js (currentIndex, isAnimating, etc.)

@Observable
@MainActor
final class WorldViewModel {

    // Current active world (0-5)
    var currentWorldIndex: Int = 0

    // Controls whether the narrative overlay is shown
    var showInterstitial: Bool = true

    // Blocks portal taps during sphere crossfade
    var isTransitioning: Bool = false

    // Interstitial data for the current world
    var currentInterstitialData: InterstitialData {
        InterstitialData.all[min(currentWorldIndex, InterstitialData.all.count - 1)]
    }

    // Called by InterstitialView's "Explorer" button — mirrors hideInterstitial() in JS
    func dismissInterstitial() {
        withAnimation(.easeOut(duration: 0.4)) {
            showInterstitial = false
        }
    }

    // Called by ImmersiveView when the user taps a portal
    // mirrors handlePortalClick() in main.js
    func navigateTo(worldIndex: Int, onComplete: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true
        currentWorldIndex = worldIndex

        Task {
            // Wait for the sphere crossfade to finish before showing the interstitial
            try? await Task.sleep(for: .seconds(AppConstants.transitionDuration + 0.1))
            withAnimation(.easeIn(duration: 0.4)) {
                showInterstitial = true
            }
            isTransitioning = false
            onComplete()
        }
    }
}
