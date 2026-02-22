import SwiftUI

// MARK: - InterstitialView
// Narrative overlay displayed between world transitions.
// Equivalent to showInterstitial() / hideInterstitial() + the HTML #interstitial element in JS.
//
// On Vision Pro, this floats as a translucent glass panel in the user's field of view.
// The user dismisses it by pressing "Explorer" or tapping outside — same UX as the web version.

struct InterstitialView: View {

    let data: InterstitialData
    let onClose: () -> Void

    var body: some View {
        ZStack {

            // Dimmed backdrop — tap outside panel to dismiss (mirrors click-outside logic in JS)
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // Glass panel
            VStack(spacing: 28) {

                // World indicator
                Text(data.title)
                    .font(.extraLargeTitle2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Narrative subtitle
                Text(data.subtitle)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer().frame(height: 12)

                // Interaction hint — mirrors the "Cliquez pour continuer" message
                HStack(spacing: 10) {
                    Image(systemName: "eyes")
                    Text("Regardez un portail")
                    Image(systemName: "hand.pinch")
                    Text("puis pincez pour voyager")
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))

                Spacer().frame(height: 4)

                // Primary CTA — mirrors the "Explore" button in HTML
                Button("Explorer") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))
                .font(.title3.weight(.semibold))
                .controlSize(.large)
            }
            .padding(48)
            .frame(maxWidth: 560)
            .glassBackgroundEffect()
        }
    }
}

#Preview {
    InterstitialView(
        data: InterstitialData.all[0],
        onClose: {}
    )
}
