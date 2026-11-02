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
            Text("Le Donjon sans sortie")
                .font(.title)
                .bold()

            Text(board.status)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
                .animation(.easeInOut, value: board.status)

            HStack(spacing: 12) {
                Button {
                    Task { await toggleDungeon() }
                } label: {
                    Label(appModel.immersiveSpaceState == .open ? "Quitter le donjon" : "Entrer dans le donjon",
                          systemImage: appModel.immersiveSpaceState == .open ? "door.left.hand.open" : "door.left.hand.closed")
                        .font(.title3)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.immersiveSpaceState == .inTransition)

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
