import RealityKit
import SwiftUI

/// Contenu de l'espace immersif. La session (`DungeonDirector`) est créée par `AppModel`
/// à l'ouverture de l'espace et détruite à sa fermeture.
struct DungeonImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        if let director = appModel.director {
            DungeonSceneView(director: director)
        }
    }
}

private struct DungeonSceneView: View {
    let director: DungeonDirector

    var body: some View {
        RealityView { content, attachments in
            await director.buildScene()
            content.add(director.root)

            // Sous-titres : un panneau flottant devant l'utilisateur, légèrement incliné.
            if let subtitle = attachments.entity(for: SubtitleView.attachmentID) {
                subtitle.position = [0, 0.95, -1.3]
                subtitle.orientation = simd_quatf(angle: -0.3, axis: [1, 0, 0])
                director.root.addChild(subtitle)
            }
        } update: { _, _ in
        } attachments: {
            Attachment(id: SubtitleView.attachmentID) {
                SubtitleView(sequencer: director.sequencer)
            }
        }
        // Regard + pincement sur un élément.
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    director.handleTap(on: value.entity)
                }
        )
        // La narration vit tant que la vue est affichée ; annulée à la fermeture de l'espace.
        .task {
            await director.sequencer.run()
        }
    }
}
