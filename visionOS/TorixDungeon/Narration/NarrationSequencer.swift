import AVFoundation
import Observation

/// Lit le script phrase par phrase et prévient la scène à chaque étape.
///
/// Un cycle :
/// 1. pour chaque phrase → `onSentenceStart` (l'élément apparaît), puis la voix la dit ;
/// 2. après la dernière (la porte) → attente que la porte soit ouverte, ou du délai `loopDelay` ;
/// 3. `onDoorOpening`, phrase finale, puis `onCycleEnd` (tout se dissout) → on recommence.
@MainActor
@Observable
final class NarrationSequencer {
    static let scriptPath = "Narration/narration.json"

    enum Phase: Equatable {
        case idle
        case loading
        case narrating(index: Int)
        case waitingAtDoor
        case closing
        case failed(String)
    }

    /// Phase courante (affichable pour le debug).
    private(set) var phase: Phase = .idle
    /// Texte affiché en sous-titre.
    private(set) var currentText: String = ""

    @ObservationIgnored var onSentenceStart: (@MainActor (NarrationSentence) -> Void)?
    @ObservationIgnored var onDoorOpening: (@MainActor () -> Void)?
    @ObservationIgnored var onCycleEnd: (@MainActor () -> Void)?

    @ObservationIgnored private let provider: any ResourceProvider
    @ObservationIgnored private let voice: any NarrationVoice
    @ObservationIgnored private var doorOpenRequested = false

    init(provider: any ResourceProvider, voice: any NarrationVoice) {
        self.provider = provider
        self.voice = voice
    }

    /// Boucle principale. À lancer dans un `.task` : elle s'arrête quand la tâche est annulée.
    func run() async {
        phase = .loading
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)

        let script: NarrationScript
        do {
            script = try await provider.decode(NarrationScript.self, from: Self.scriptPath)
        } catch {
            phase = .failed(error.localizedDescription)
            currentText = "Impossible de lire le texte : \(error.localizedDescription)"
            print("[Narration] \(error)")
            return
        }

        // Laisse le temps aux yeux de s'habituer à l'obscurité.
        try? await Task.sleep(for: .seconds(2.5))

        while !Task.isCancelled {
            await playCycle(script)
        }
        stop()
    }

    /// Demande l'ouverture de la porte (pincement de l'utilisateur).
    func requestDoorOpening() {
        doorOpenRequested = true
    }

    func stop() {
        voice.stop()
        currentText = ""
        phase = .idle
    }

    // MARK: - Cycle

    private func playCycle(_ script: NarrationScript) async {
        doorOpenRequested = false

        for (index, sentence) in script.sentences.enumerated() {
            guard !Task.isCancelled else { return }
            phase = .narrating(index: index)
            currentText = sentence.text
            onSentenceStart?(sentence)
            await voice.speak(sentence, language: script.language)
            try? await Task.sleep(for: .seconds(script.pauseBetweenSentences))
        }

        // La porte est là. On attend que l'utilisateur la touche… ou on s'impatiente.
        phase = .waitingAtDoor
        let deadline = ContinuousClock.now + .seconds(script.loopDelay)
        while !Task.isCancelled, !doorOpenRequested, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(200))
        }
        guard !Task.isCancelled else { return }

        phase = .closing
        onDoorOpening?()
        currentText = script.doorOpenedSentence.text
        await voice.speak(script.doorOpenedSentence, language: script.language)
        guard !Task.isCancelled else { return }

        onCycleEnd?()
        currentText = ""
        try? await Task.sleep(for: .seconds(3))
    }
}
