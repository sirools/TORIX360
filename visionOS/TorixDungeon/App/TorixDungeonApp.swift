import SwiftUI

/// Point d'entrée de l'app.
///
/// - Une fenêtre en volume (`ContentView`) : diorama tactique façon Dofus + bouton « Entrer dans le donjon ».
/// - Un espace immersif (`DungeonImmersiveView`) qui contient la salle et la narration.
/// - Un espace immersif (`VillageImmersiveView`) : le village à explorer à la première personne.
@main
struct TorixDungeonApp: App {
    @State private var appModel = AppModel()
    @State private var villageStyle: any ImmersionStyle = .full

    init() {
        // Les composants et systèmes RealityKit maison doivent être enregistrés une fois au lancement.
        DungeonRegistration.registerAll()
    }

    var body: some Scene {
        WindowGroup(id: AppModel.launchWindowID) {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.8, height: 0.6, depth: 0.8, in: .meters)

        ImmersiveSpace(id: AppModel.immersiveSpaceID) {
            DungeonImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    appModel.openSpaceID = AppModel.immersiveSpaceID
                    appModel.startSession()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    appModel.openSpaceID = nil
                    appModel.endSession()
                }
        }
        // `.mixed` : on voit encore un peu la vraie pièce. `.full` : le donjon remplace tout.
        .immersionStyle(selection: immersionStyleBinding, in: .mixed, .full)

        // Le village se vit toujours en immersion totale : on y est, à hauteur d'yeux.
        ImmersiveSpace(id: AppModel.villageSpaceID) {
            VillageImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    appModel.openSpaceID = AppModel.villageSpaceID
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    appModel.openSpaceID = nil
                }
        }
        .immersionStyle(selection: $villageStyle, in: .full)
    }

    /// Fait le pont entre le choix fait dans la fenêtre de lancement et le style d'immersion SwiftUI.
    private var immersionStyleBinding: Binding<any ImmersionStyle> {
        Binding(
            get: { appModel.immersionChoice.style },
            set: { newStyle in
                appModel.immersionChoice = newStyle is FullImmersionStyle ? .full : .mixed
            }
        )
    }
}
