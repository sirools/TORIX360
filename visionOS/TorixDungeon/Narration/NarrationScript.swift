import Foundation

/// Le texte fondateur, découpé en phrases. Chargé depuis `Narration/narration.json`.
struct NarrationScript: Codable {
    let title: String
    /// Code langue de la synthèse vocale, ex. `fr-FR`.
    let language: String
    /// Silence (secondes) entre deux phrases.
    let pauseBetweenSentences: Double
    /// Si personne n'ouvre la porte, le donjon recommence après ce délai (secondes).
    let loopDelay: Double
    let sentences: [NarrationSentence]
    /// Phrase dite quand la porte s'ouvre… sur rien.
    let doorOpenedSentence: NarrationSentence
}

struct NarrationSentence: Codable, Identifiable {
    let id: String
    let text: String
    /// Chemin relatif de l'enregistrement (ex. `Audio/phrase_01.m4a`). Absent = synthèse vocale.
    let audio: String?
    /// Élément qui apparaît au début de la phrase. Absent = rien n'apparaît.
    let element: ElementKind?
    let placement: Placement?
}

/// Position d'un élément autour de l'utilisateur, exprimée de façon lisible dans le JSON.
struct Placement: Codable {
    /// Angle en degrés : 0 = devant, 90 = à droite, 180 = derrière, -90 = à gauche.
    let angle: Float
    /// Distance horizontale à l'utilisateur, en mètres.
    let distance: Float
    /// Hauteur au-dessus du sol, en mètres.
    let height: Float

    static let `default` = Placement(angle: 0, distance: 1.6, height: 1.1)

    /// Position RealityKit (origine = pieds de l'utilisateur, -Z = devant).
    var position: SIMD3<Float> {
        let radians = angle * .pi / 180
        return [sin(radians) * distance, height, -cos(radians) * distance]
    }
}
