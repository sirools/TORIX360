import RealityKit

/// Enregistre une seule fois les composants et systèmes RealityKit du projet.
/// Ajoute ici tout nouveau `Component` ou `System`.
enum DungeonRegistration {
    static func registerAll() {
        ElementComponent.registerComponent()
        LevitationComponent.registerComponent()
        FlickerComponent.registerComponent()
        TileComponent.registerComponent()
        CreatureComponent.registerComponent()
        GroundComponent.registerComponent()
        PortalLinkComponent.registerComponent()

        LevitationSystem.registerSystem()
        FlickerSystem.registerSystem()
    }
}
