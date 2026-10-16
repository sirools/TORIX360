import RealityKit
import UIKit

/// Les éléments qu'une phrase peut faire apparaître. Les valeurs brutes sont celles du JSON.
enum ElementKind: String, Codable, CaseIterable {
    case chandelle
    case soulier
    case herisson
    case eclatDeSort
    case cle
    case grimoire
    case porte
}

/// Réglages de lévitation propres à chaque élément.
struct LevitationTuning {
    /// Amplitude du flottement vertical (m).
    var amplitude: Float = 0.035
    /// Vitesse de rotation sur lui-même (rad/s).
    var spinSpeed: Float = 0
    /// L'élément apparaît plus bas de cette distance puis remonte (m).
    var riseDistance: Float = 0.25
    /// Durée du fondu d'apparition (s).
    var fadeInDuration: Float = 1.8
}

/// Contrat d'un élément invoqué : un fichier par élément dans `Elements/`.
///
/// Pour ajouter un élément :
/// 1. ajouter un cas à `ElementKind` ;
/// 2. créer `MonElement.swift` conforme à ce protocole ;
/// 3. le référencer dans `ElementFactory.type(for:)` ;
/// 4. l'utiliser dans `narration.json`.
@MainActor
protocol DungeonElement {
    /// Construit le modèle. Convention : la face « avant » regarde vers +Z
    /// (l'élément sera tourné pour faire face à l'utilisateur).
    static func makeModel() -> Entity

    static var levitation: LevitationTuning { get }

    /// Notes (Hz) du carillon joué au pincement.
    static var reactionNotes: [Double] { get }

    /// Couleur des particules au pincement.
    static var particleColor: UIColor { get }
}

/// Marque l'entité racine d'un élément invoqué.
struct ElementComponent: Component {
    let kind: ElementKind
}

extension Entity {
    /// Remonte la hiérarchie jusqu'à trouver une entité portant le composant demandé.
    func firstAncestor<T: Component>(with componentType: T.Type) -> Entity? {
        var current: Entity? = self
        while let entity = current {
            if entity.components.has(componentType) { return entity }
            current = entity.parent
        }
        return nil
    }
}
