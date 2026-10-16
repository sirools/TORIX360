import SwiftUI

/// Fenêtre d'accueil : quelques réglages et le bouton pour entrer (ou sortir) du donjon.
struct LaunchView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var appModel = appModel

        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Le Donjon sans sortie")
                    .font(.extraLargeTitle2)
                Text("Écoute. Chaque phrase fait apparaître quelque chose.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                LabeledContent("Immersion") {
                    Picker("Immersion", selection: $appModel.immersionChoice) {
                        ForEach(AppModel.ImmersionChoice.allCases) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                LabeledContent("Voix") {
                    Picker("Voix", selection: $appModel.voiceChoice) {
                        ForEach(AppModel.VoiceChoice.allCases) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                LabeledContent("NAS (optionnel)") {
                    TextField("http://nas.local:8080/torix", text: $appModel.nasBaseURLString)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(width: 260)
                }
            }
            .disabled(appModel.immersiveSpaceState != .closed)

            Button {
                Task { await toggleDungeon() }
            } label: {
                Text(appModel.immersiveSpaceState == .open ? "Quitter le donjon" : "Entrer dans le donjon")
                    .font(.title2)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.immersiveSpaceState == .inTransition)
        }
        .padding(48)
        .frame(width: 620)
    }

    private func toggleDungeon() async {
        switch appModel.immersiveSpaceState {
        case .open:
            appModel.immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
            // L'état repasse à `.closed` dans le `onDisappear` de l'espace immersif.

        case .closed:
            appModel.immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: AppModel.immersiveSpaceID) {
            case .opened:
                // L'état passe à `.open` dans le `onAppear` de l'espace immersif.
                break
            case .userCancelled, .error:
                appModel.immersiveSpaceState = .closed
            @unknown default:
                appModel.immersiveSpaceState = .closed
            }

        case .inTransition:
            break
        }
    }
}

#Preview(windowStyle: .automatic) {
    LaunchView()
        .environment(AppModel())
}
