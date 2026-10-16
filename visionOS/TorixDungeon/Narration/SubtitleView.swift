import SwiftUI

/// Sous-titre flottant de la phrase en cours (attachment SwiftUI dans la scène RealityKit).
struct SubtitleView: View {
    static let attachmentID = "subtitle"

    let sequencer: NarrationSequencer

    var body: some View {
        Text(sequencer.currentText)
            .font(.system(size: 30, weight: .regular, design: .serif))
            .italic()
            .multilineTextAlignment(.center)
            .frame(maxWidth: 680)
            .padding(.horizontal, 36)
            .padding(.vertical, 20)
            .glassBackgroundEffect()
            .opacity(sequencer.currentText.isEmpty ? 0 : 1)
            .animation(.easeInOut(duration: 0.6), value: sequencer.currentText)
    }
}
