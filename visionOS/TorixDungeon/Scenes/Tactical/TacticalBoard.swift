import Foundation
import Observation
import RealityKit
import UIKit

/// Le plateau tactique de la fenêtre principale : un petit combat au tour par tour,
/// vu comme un diorama posé devant soi.
///
/// - pincer une case en surbrillance : le héros s'y rend, case par case (3 PM) ;
/// - pincer le hérisson à portée (5 cases) : un éclat de sort part, le hérisson fuit ;
/// - pincer le héros : petite gerbe d'étincelles.
@MainActor
@Observable
final class TacticalBoard {
    static let movementPoints = 3
    static let spellRange = 5

    /// Racine du diorama, à ajouter dans la `RealityView`.
    let root = Entity()

    /// Consigne affichée dans le panneau.
    private(set) var status = "Pince une case bleue pour te déplacer, ou le hérisson pour lancer un sort."
    private(set) var hits = 0

    private let hero: Entity
    private let enemy: Entity
    private let highlights = Entity()
    private let effects = ElementEffects()

    @ObservationIgnored private var heroPosition = GridPosition(x: 2, z: 7)
    @ObservationIgnored private var enemyPosition = GridPosition(x: 6, z: 2)
    @ObservationIgnored private var isBusy = false

    init() {
        root.name = "TacticalBoard"
        root.addChild(TacticalBoardBuilder.makeIsland())
        root.addChild(TacticalBoardBuilder.makeTiles())
        root.addChild(TacticalBoardBuilder.makeObstacles())
        root.addChild(highlights)

        hero = TacticalBoardBuilder.makeHero()
        enemy = TacticalBoardBuilder.makeEnemy()
        root.addChild(hero)
        root.addChild(enemy)

        place(hero, at: heroPosition)
        place(enemy, at: enemyPosition)
        face(hero, toward: TacticalBoardBuilder.center(of: enemyPosition))
        face(enemy, toward: TacticalBoardBuilder.center(of: heroPosition))
        refreshHighlights()
    }

    // MARK: - Interaction

    func handleTap(on tapped: Entity) {
        guard !isBusy else { return }

        if let tile = tapped.firstAncestor(with: TileComponent.self),
           let cell = tile.components[TileComponent.self]?.position {
            Task { await moveHero(to: cell) }
            return
        }

        if let creature = tapped.firstAncestor(with: CreatureComponent.self),
           let role = creature.components[CreatureComponent.self]?.role {
            switch role {
            case .enemy:
                Task { await castSpell() }
            case .hero:
                effects.burst(on: hero, color: Palette.mauve)
                status = "C'est toi ! Bleu = tes déplacements possibles."
            }
        }
    }

    // MARK: - Déplacement

    private func moveHero(to target: GridPosition) async {
        let search = breadthFirstSearch(from: heroPosition)
        guard let distance = search.distance[target], distance > 0 else { return }
        guard distance <= Self.movementPoints else {
            status = "Trop loin : \(Self.movementPoints) PM maximum par déplacement."
            return
        }

        // Reconstruit le chemin depuis la cible.
        var path = [target]
        var cursor = target
        while let previous = search.parent[cursor], previous != heroPosition {
            path.insert(previous, at: 0)
            cursor = previous
        }

        isBusy = true
        clearHighlights()
        for step in path {
            await hop(hero, to: step, height: 0.025, duration: 0.24)
            heroPosition = step
        }
        face(hero, toward: TacticalBoardBuilder.center(of: enemyPosition))
        isBusy = false

        let gap = heroPosition.distance(to: enemyPosition)
        status = gap <= Self.spellRange
            ? "Le hérisson est à portée (\(gap) cases) : pince-le pour lancer un sort !"
            : "Hérisson à \(gap) cases. Rapproche-toi (portée \(Self.spellRange))."
        refreshHighlights()
    }

    // MARK: - Sort

    private func castSpell() async {
        let gap = heroPosition.distance(to: enemyPosition)
        guard gap <= Self.spellRange else {
            status = "Hors de portée (\(gap) cases, max \(Self.spellRange)). Rapproche-toi !"
            return
        }

        isBusy = true
        clearHighlights()
        let start = TacticalBoardBuilder.center(of: heroPosition)
        let end = TacticalBoardBuilder.center(of: enemyPosition)
        face(hero, toward: end)

        // Éclat de sort qui file vers la cible.
        let orb = Primitives.sphere(0.011, Primitives.unlit(Palette.spellCyan))
        orb.position = start + [0, 0.11, 0]
        root.addChild(orb)
        orb.move(to: Transform(translation: end + [0, 0.05, 0]), relativeTo: root,
                 duration: 0.35, timingFunction: .easeIn)
        try? await Task.sleep(for: .seconds(0.35))
        orb.removeFromParent()

        effects.react(enemy, kind: .herisson)
        hits += 1
        status = "Touché ! (\(hits)) Le hérisson s'enfuit…"
        try? await Task.sleep(for: .seconds(0.4))

        // Il fuit vers une case libre, loin du héros.
        if let refuge = fleeCell() {
            await hop(enemy, to: refuge, height: 0.08, duration: 0.6)
            enemyPosition = refuge
        }
        face(enemy, toward: TacticalBoardBuilder.center(of: heroPosition))
        face(hero, toward: TacticalBoardBuilder.center(of: enemyPosition))
        isBusy = false
        refreshHighlights()
    }

    private func fleeCell() -> GridPosition? {
        var candidates: [GridPosition] = []
        for x in 0..<TacticalBoardBuilder.gridSize {
            for z in 0..<TacticalBoardBuilder.gridSize {
                let cell = GridPosition(x: x, z: z)
                if isWalkable(cell), cell != heroPosition, cell.distance(to: heroPosition) >= 4 {
                    candidates.append(cell)
                }
            }
        }
        return candidates.randomElement()
    }

    // MARK: - Grille

    private func isWalkable(_ cell: GridPosition) -> Bool {
        TacticalBoardBuilder.isInside(cell)
            && TacticalBoardBuilder.obstacles[cell] == nil
            && cell != enemyPosition
    }

    /// Parcours en largeur : distance (en PM) et case précédente pour chaque case atteignable.
    private func breadthFirstSearch(from start: GridPosition)
        -> (distance: [GridPosition: Int], parent: [GridPosition: GridPosition]) {
        var distance = [start: 0]
        var parent: [GridPosition: GridPosition] = [:]
        var queue = [start]
        var index = 0
        while index < queue.count {
            let current = queue[index]
            index += 1
            guard let steps = distance[current], steps < Self.movementPoints else { continue }
            for next in current.neighbors where isWalkable(next) && distance[next] == nil {
                distance[next] = steps + 1
                parent[next] = current
                queue.append(next)
            }
        }
        return (distance, parent)
    }

    /// Surligne les cases accessibles avec les PM du héros.
    private func refreshHighlights() {
        clearHighlights()
        var material = UnlitMaterial(color: Palette.reachable)
        material.blending = .transparent(opacity: 0.55)
        let size = TacticalBoardBuilder.tileSize * 0.86
        let mesh = MeshResource.generateBox(size: [size, 0.002, size], cornerRadius: 0.003)

        for (cell, steps) in breadthFirstSearch(from: heroPosition).distance where steps > 0 {
            let marker = ModelEntity(mesh: mesh, materials: [material])
            marker.position = TacticalBoardBuilder.center(of: cell) + [0, 0.0015, 0]
            highlights.addChild(marker)
        }
    }

    private func clearHighlights() {
        for child in Array(highlights.children) {
            child.removeFromParent()
        }
    }

    // MARK: - Animation

    private func place(_ entity: Entity, at cell: GridPosition) {
        entity.position = TacticalBoardBuilder.center(of: cell)
    }

    /// Tourne la face avant (+Z) du personnage vers un point du plateau.
    private func face(_ entity: Entity, toward point: SIMD3<Float>) {
        let direction = point - entity.position
        guard abs(direction.x) + abs(direction.z) > 0.0001 else { return }
        entity.orientation = Primitives.yaw(atan2(direction.x, direction.z))
    }

    /// Petit saut d'une case à une autre (montée puis descente).
    private func hop(_ entity: Entity, to cell: GridPosition, height: Float, duration: TimeInterval) async {
        let target = TacticalBoardBuilder.center(of: cell)
        let start = entity.position
        face(entity, toward: target)

        let half = duration / 2
        let peak = Transform(rotation: entity.orientation, translation: (start + target) / 2 + [0, height, 0])
        entity.move(to: peak, relativeTo: entity.parent, duration: half, timingFunction: .easeOut)
        try? await Task.sleep(for: .seconds(half))

        let landing = Transform(rotation: entity.orientation, translation: target)
        entity.move(to: landing, relativeTo: entity.parent, duration: half, timingFunction: .easeIn)
        try? await Task.sleep(for: .seconds(half + 0.02))
        entity.position = target
    }
}
