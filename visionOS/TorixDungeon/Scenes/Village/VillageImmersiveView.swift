import RealityKit
import SwiftUI

/// Espace immersif « Clairière de Bruyère » : exploration à la première personne.
struct VillageImmersiveView: View {
    @State private var world = VillageWorld()
    @State private var updateSubscription: EventSubscription?

    private enum HUD: String {
        case header, spells, toast, inventory, map
    }

    var body: some View {
        RealityView { content, attachments in
            content.add(world.worldRoot)

            // Boucle de jeu : déplacement, sorts, créatures… à chaque image.
            updateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                world.update(deltaTime: Float(event.deltaTime))
            }

            // HUD accroché à la tête : il reste dans le champ de vision.
            let head = AnchorEntity(.head)
            content.add(head)
            let layout: [(HUD, SIMD3<Float>, Float, Float)] = [
                (.header, [-0.36, 0.24, -0.95], 0.25, 0),
                (.spells, [0, -0.3, -0.85], 0, 0.35),
                (.toast, [0, 0.12, -0.95], 0, 0),
                (.inventory, [0.42, -0.02, -0.9], -0.4, 0),
                (.map, [-0.42, -0.02, -0.9], 0.4, 0)
            ]
            for (id, position, yaw, pitch) in layout {
                guard let panel = attachments.entity(for: id.rawValue) else { continue }
                panel.position = position
                panel.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: pitch, axis: [1, 0, 0])
                head.addChild(panel)
            }
        } update: { _, _ in
        } attachments: {
            Attachment(id: HUD.header.rawValue) { HUDHeaderView(world: world) }
            Attachment(id: HUD.spells.rawValue) { SpellBarView(world: world) }
            Attachment(id: HUD.toast.rawValue) { ToastView(world: world) }
            Attachment(id: HUD.inventory.rawValue) {
                if world.showsInventory { InventoryView(world: world) }
            }
            Attachment(id: HUD.map.rawValue) {
                if world.showsMap { VillageMapView(world: world) }
            }
        }
        // Regard + pincement : sol (portail), objet (ramasser), portail de pierre, hérisson.
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let point = value.convert(value.location3D, from: .local, to: .scene)
                    world.handleTap(on: value.entity, scenePoint: point)
                }
        )
        .task {
            await world.start()
        }
        .onDisappear {
            updateSubscription?.cancel()
            world.stop()
        }
    }
}
