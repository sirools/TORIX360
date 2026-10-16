import AVFoundation

/// Une « voix » qui sait dire une phrase et rendre la main quand elle a fini.
///
/// Deux implémentations :
/// - `SpeechSynthesisVoice` : voix de synthèse française (placeholder) ;
/// - `RecordedVoice` : les enregistrements de Clément, avec repli sur la synthèse
///   quand un fichier manque.
@MainActor
protocol NarrationVoice: AnyObject {
    /// Dit la phrase et ne revient qu'à la fin (ou à l'annulation de la tâche).
    func speak(_ sentence: NarrationSentence, language: String) async
    /// Coupe immédiatement.
    func stop()
}

// MARK: - Synthèse vocale

@MainActor
final class SpeechSynthesisVoice: NSObject, NarrationVoice {
    /// Débit (0…1, ~0.5 = normal). Un peu lent pour l'ambiance conte.
    var rate: Float = 0.44
    /// Hauteur (0.5…2). Légèrement grave.
    var pitch: Float = 0.9

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    private var currentUtterance: ObjectIdentifier?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ sentence: NarrationSentence, language: String) async {
        stop()

        let utterance = AVSpeechUtterance(string: sentence.text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.postUtteranceDelay = 0.1

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                self.currentUtterance = ObjectIdentifier(utterance)
                synthesizer.speak(utterance)
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    func stop() {
        currentUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        resume()
    }

    /// Appelé par le délégué : ne réveille que si c'est bien la phrase en cours.
    fileprivate func utteranceEnded(_ id: ObjectIdentifier) {
        guard id == currentUtterance else { return }
        currentUtterance = nil
        resume()
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }
}

extension SpeechSynthesisVoice: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }
}

// MARK: - Voix enregistrée

/// Joue `sentence.audio` via le `ResourceProvider` (bundle ou NAS).
/// Si le fichier est absent ou illisible, la phrase est dite par la voix de repli.
@MainActor
final class RecordedVoice: NSObject, NarrationVoice {
    private let provider: any ResourceProvider
    private let fallback: any NarrationVoice
    private var player: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?

    init(provider: any ResourceProvider, fallback: any NarrationVoice) {
        self.provider = provider
        self.fallback = fallback
        super.init()
    }

    func speak(_ sentence: NarrationSentence, language: String) async {
        stop()

        guard let path = sentence.audio,
              let data = try? await provider.data(for: path),
              let player = try? AVAudioPlayer(data: data) else {
            await fallback.speak(sentence, language: language)
            return
        }

        self.player = player
        player.delegate = self
        player.prepareToPlay()

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                if !player.play() { self.resume() }
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        resume()
        fallback.stop()
    }

    fileprivate func playerFinished(_ id: ObjectIdentifier) {
        guard let player, ObjectIdentifier(player) == id else { return }
        self.player = nil
        resume()
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }
}

extension RecordedVoice: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in self.playerFinished(id) }
    }
}
