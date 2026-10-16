import RealityKit
import RealityKitContent

/// Le « metteur en scène » : relie la narration à la scène 3D.
///
/// - construit la salle ;
/// - à chaque phrase, fait apparaître l'élément demandé ;
/// - gère le pincement sur un élément (réaction) ou sur la porte (fin du cycle) ;
/// - dissout tout en fin de cycle pour que le donjon recommence.
@MainActor
final class DungeonDirector {
    /// Racine de tout le contenu de l'espace immersif.
    let root = Entity()
    let sequencer: NarrationSequencer

    private let elementsAnchor = Entity()
    private let effects = ElementEffects()
    private var door: Entity?
    private var doorIsOpen = false
    private var sceneBuilt = false

    init(provider: any ResourceProvider, voice: any NarrationVoice) {
        sequencer = NarrationSequencer(provider: provider, voice: voice)
        root.name = "DungeonRoot"
        elementsAnchor.name = "Elements"

        sequencer.onSentenceStart = { [weak self] sentence in
            self?.spawnElement(for: sentence)
        }
        sequencer.onDoorOpening = { [weak self] in
            self?.openDoor()
        }
        sequencer.onCycleEnd = { [weak self] in
            self?.dissolveAll()
        }
    }

    // MARK: - Scène

    func buildScene() async {
        guard !sceneBuilt else { return }
        sceneBuilt = true

        root.addChild(DungeonRoomBuilder.makeRoom())
        root.addChild(elementsAnchor)

        // Décor optionnel édité dans Reality Composer Pro (Packages/RealityKitContent).
        if let decor = try? await Entity(named: "DungeonDecor", in: realityKitContentBundle) {
            root.addChild(decor)
        }
    }

    func stop() {
        sequencer.stop()
    }

    // MARK: - Narration → apparitions

    private func spawnElement(for sentence: NarrationSentence) {
        guard let kind = sentence.element else { return }
        let element = ElementFactory.make(kind, at: sentence.placement ?? .default)
        elementsAnchor.addChild(element)

        if kind == .porte {
            door = element
            doorIsOpen = false
        }
    }

    // MARK: - Interaction

    /// Appelé par le geste « regard + pincement » sur n'importe quelle entité.
    func handleTap(on tapped: Entity) {
        guard let element = tapped.firstAncestor(with: ElementComponent.self),
              let kind = element.components[ElementComponent.self]?.kind else { return }

        effects.react(element, kind: kind)

        if kind == .porte {
            openDoor()
            sequencer.requestDoorOpening()
        }
    }

    private func openDoor() {
        guard let door, !doorIsOpen else { return }
        doorIsOpen = true
        DoorElement.open(door)
    }

    /// Fin de cycle : tout s'évapore, la salle reste vide… et l'histoire recommence.
    private func dissolveAll() {
        for element in elementsAnchor.children {
            guard var state = element.components[LevitationComponent.self] else { continue }
            state.fadeOutElapsed = 0
            element.components.set(state)
            // Plus d'interaction pendant la disparition.
            element.components.remove(InputTargetComponent.self)
        }
        door = nil
        doorIsOpen = false
    }
}
