import RealityKit

/// Enregistre une seule fois les composants et systèmes RealityKit du projet.
/// Ajoute ici tout nouveau `Component` ou `System`.
enum DungeonRegistration {
    static func registerAll() {
        ElementComponent.registerComponent()
        LevitationComponent.registerComponent()
        FlickerComponent.registerComponent()

        LevitationSystem.registerSystem()
        FlickerSystem.registerSystem()
    }
}
