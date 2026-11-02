import SwiftUI

/// Panneau flottant au-dessus du plateau : consigne du combat, réglages,
/// et le bouton pour entrer dans le donjon immersif.
struct DungeonControlPanel: View {
    let board: TacticalBoard

    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var showsSettings = false

    var body: some View {
        @Bindable var appModel = appModel

        VStack(spacing: 14) {
            Text("TORIX · Monde à explorer")
                .font(.title)
                .bold()

            Text(board.status)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
                .animation(.easeInOut, value: board.status)

            HStack(spacing: 12) {
                spaceButton(id: AppModel.villageSpaceID,
                            title: "Explorer le village",
                            symbol: "figure.walk")
                spaceButton(id: AppModel.immersiveSpaceID,
                            title: "Entrer dans le donjon",
                            symbol: "door.left.hand.closed")

                Button {
                    showsSettings.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .help("Réglages")
            }

            if showsSettings {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Immersion", selection: $appModel.immersionChoice) {
                        ForEach(AppModel.ImmersionChoice.allCases) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Voix", selection: $appModel.voiceChoice) {
                        ForEach(AppModel.VoiceChoice.allCases) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("NAS (optionnel) : http://nas.local:8080/torix", text: $appModel.nasBaseURLString)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .disabled(appModel.immersiveSpaceState != .closed)
            }
        }
        .padding(28)
        .frame(width: 560)
        .glassBackgroundEffect()
    }

    /// Bouton d'ouverture / fermeture d'un espace immersif.
    @ViewBuilder
    private func spaceButton(id: String, title: String, symbol: String) -> some View {
        let isOpen = appModel.openSpaceID == id
        Button {
            Task { await toggle(spaceID: id) }
        } label: {
            Label(isOpen ? "Quitter" : title, systemImage: isOpen ? "xmark.circle" : symbol)
                .font(.title3)
                .padding(.horizontal, 6)
        }
        .buttonStyle(.borderedProminent)
        .disabled(appModel.immersiveSpaceState == .inTransition
                  || (appModel.openSpaceID != nil && !isOpen))
    }

    private func toggle(spaceID: String) async {
        switch appModel.immersiveSpaceState {
        case .open:
            appModel.immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
            // L'état repasse à `.closed` dans le `onDisappear` de l'espace immersif.

        case .closed:
            appModel.immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: spaceID) {
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
