import RealityKit
import UIKit

/// Fabrique les éléments invoqués, prêts à être posés dans la scène.
@MainActor
enum ElementFactory {
    static func type(for kind: ElementKind) -> any DungeonElement.Type {
        switch kind {
        case .chandelle: CandleElement.self
        case .soulier: ShoeElement.self
        case .herisson: HedgehogElement.self
        case .eclatDeSort: SpellShardElement.self
        case .cle: KeyElement.self
        case .grimoire: GrimoireElement.self
        case .porte: DoorElement.self
        }
    }

    /// Construit l'élément, le place face à l'utilisateur et le rend interactif
    /// (regard + pincement). Il commence invisible : `LevitationSystem` gère le fondu.
    static func make(_ kind: ElementKind, at placement: Placement) -> Entity {
        let element = type(for: kind)
        let root = Entity()
        root.name = "Element.\(kind.rawValue)"
        root.addChild(element.makeModel())

        // Face avant (+Z) tournée vers l'utilisateur, au centre de la salle.
        let position = placement.position
        let orientation = Primitives.yaw(atan2(-position.x, -position.z))
        root.position = position
        root.orientation = orientation

        // Interaction : une boîte de collision englobante, un peu généreuse pour viser facilement.
        let bounds = root.visualBounds(relativeTo: root)
        let size = simd_max(bounds.extents * 1.15, SIMD3(repeating: 0.18))
        root.components.set(CollisionComponent(shapes: [
            ShapeResource.generateBox(size: size).offsetBy(translation: bounds.center)
        ]))
        root.components.set(InputTargetComponent())
        root.components.set(HoverEffectComponent())

        root.components.set(ElementComponent(kind: kind))
        root.components.set(OpacityComponent(opacity: 0))
        root.components.set(LevitationComponent(basePosition: position,
                                                baseOrientation: orientation,
                                                tuning: element.levitation))
        return root
    }
}
