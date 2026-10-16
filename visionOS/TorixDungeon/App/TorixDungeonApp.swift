import SwiftUI

/// Point d'entrée de l'app.
///
/// - Une petite fenêtre de lancement (`LaunchView`) avec le bouton « Entrer dans le donjon ».
/// - Un espace immersif (`DungeonImmersiveView`) qui contient la salle et la narration.
@main
struct TorixDungeonApp: App {
    @State private var appModel = AppModel()

    init() {
        // Les composants et systèmes RealityKit maison doivent être enregistrés une fois au lancement.
        DungeonRegistration.registerAll()
    }

    var body: some Scene {
        WindowGroup(id: AppModel.launchWindowID) {
            LaunchView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: AppModel.immersiveSpaceID) {
            DungeonImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    appModel.startSession()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    appModel.endSession()
                }
        }
        // `.mixed` : on voit encore un peu la vraie pièce. `.full` : le donjon remplace tout.
        .immersionStyle(selection: immersionStyleBinding, in: .mixed, .full)
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
