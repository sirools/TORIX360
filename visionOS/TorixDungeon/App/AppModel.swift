import SwiftUI

/// État global de l'app : réglages choisis dans la fenêtre de lancement
/// et session de donjon en cours.
@MainActor
@Observable
final class AppModel {
    static let launchWindowID = "launch"
    static let immersiveSpaceID = "dungeon"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    enum ImmersionChoice: String, CaseIterable, Identifiable {
        case mixed
        case full

        var id: String { rawValue }

        var label: String {
            switch self {
            case .mixed: "Mixte"
            case .full: "Totale"
            }
        }

        var style: any ImmersionStyle {
            switch self {
            case .mixed: return .mixed
            case .full: return .full
            }
        }
    }

    enum VoiceChoice: String, CaseIterable, Identifiable {
        /// Fichiers audio enregistrés (avec repli automatique sur la synthèse s'ils manquent).
        case recorded
        /// Synthèse vocale française uniquement.
        case synthesis

        var id: String { rawValue }

        var label: String {
            switch self {
            case .recorded: "Enregistrée"
            case .synthesis: "Synthèse"
            }
        }
    }

    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var immersionChoice: ImmersionChoice = .mixed
    var voiceChoice: VoiceChoice = .recorded

    /// Adresse du futur NAS, ex. `http://nas.local:8080/torix`. Vide = tout vient du bundle.
    var nasBaseURLString: String = UserDefaults.standard.string(forKey: "nasBaseURL") ?? "" {
        didSet { UserDefaults.standard.set(nasBaseURLString, forKey: "nasBaseURL") }
    }

    /// Session de donjon active (créée à l'ouverture de l'espace immersif).
    private(set) var director: DungeonDirector?

    // MARK: - Session

    func startSession() {
        guard director == nil else { return }
        let provider = makeResourceProvider()
        let synthesis = SpeechSynthesisVoice()
        let voice: any NarrationVoice = switch voiceChoice {
        case .recorded: RecordedVoice(provider: provider, fallback: synthesis)
        case .synthesis: synthesis
        }
        director = DungeonDirector(provider: provider, voice: voice)
    }

    func endSession() {
        director?.stop()
        director = nil
    }

    // MARK: - Ressources

    /// Bundle local d'abord ; si une adresse NAS est saisie, le NAS est essayé en premier
    /// et le bundle sert de filet de sécurité.
    private func makeResourceProvider() -> any ResourceProvider {
        let bundle = BundleResourceProvider()
        let trimmed = nasBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            return bundle
        }
        return FallbackResourceProvider([LocalNetworkResourceProvider(baseURL: url), bundle])
    }
}
