import SwiftUI

/// Entry screen shown before the user enters the full immersive space.
struct ContentView: View {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow

    @State private var isEntering = false

    var body: some View {
        VStack(spacing: 36) {

            // — Logo / Title —
            VStack(spacing: 8) {
                Text("TORIX")
                    .font(.system(size: 72, weight: .black, design: .default))
                    .foregroundStyle(.white)

                Text("360°")
                    .font(.system(size: 38, weight: .thin))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(12)
            }

            // — Description —
            Text("Une expérience immersive en 6 mondes\nconstruite avec passion.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 8)

            // — Enter button —
            Button {
                isEntering = true
                Task {
                    await openImmersiveSpace(id: AppConstants.immersiveSpaceID)
                    // The window auto-dismisses once the immersive space opens
                    dismissWindow()
                    isEntering = false
                }
            } label: {
                Label(
                    isEntering ? "Chargement…" : "Entrer dans TORIX",
                    systemImage: isEntering ? "hourglass" : "visionpro"
                )
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .disabled(isEntering)

            // — Instructions —
            VStack(spacing: 6) {
                Label("Regardez un portail pour le mettre en surbrillance", systemImage: "eyes")
                Label("Pincez le pouce et l'index pour vous téléporter", systemImage: "hand.pinch")
            }
            .font(.footnote)
            .foregroundStyle(.tertiary)
        }
        .padding(52)
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .plain) {
    ContentView()
        .frame(width: 640, height: 480)
}
