//
//  ContentView.swift
//  TORIX360
//
//  Fenêtre principale en volume (diorama 3D) : un plateau tactique au tour par tour,
//  vu de dessus comme dans un Dofus, posé devant soi. On peut en faire le tour,
//  se pencher dessus, et pincer cases et personnages.
//  Le panneau flottant permet d'entrer dans le donjon immersif.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    @State private var board = TacticalBoard()

    private static let panelID = "panel"

    var body: some View {
        RealityView { content, attachments in
            // Le plateau un peu sous le centre du volume (origine = centre du volume).
            board.root.position = [0, -0.06, 0.02]
            content.add(board.root)

            // Panneau de contrôle : à l'arrière du plateau, comme un tableau d'affichage.
            if let panel = attachments.entity(for: Self.panelID) {
                panel.position = [0, 0.16, -0.34]
                content.add(panel)
            }
        } update: { _, _ in
        } attachments: {
            Attachment(id: Self.panelID) {
                DungeonControlPanel(board: board)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    board.handleTap(on: value.entity)
                }
        )
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
