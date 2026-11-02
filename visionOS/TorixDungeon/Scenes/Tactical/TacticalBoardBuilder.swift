import RealityKit
import UIKit

/// Case du plateau (coordonnées de grille).
struct GridPosition: Hashable {
    var x: Int
    var z: Int

    var neighbors: [GridPosition] {
        [GridPosition(x: x + 1, z: z), GridPosition(x: x - 1, z: z),
         GridPosition(x: x, z: z + 1), GridPosition(x: x, z: z - 1)]
    }

    /// Distance « en cases » (déplacements orthogonaux), comme pour les PM et la portée.
    func distance(to other: GridPosition) -> Int {
        abs(x - other.x) + abs(z - other.z)
    }
}

/// Marque une dalle cliquable.
struct TileComponent: Component {
    let position: GridPosition
}

/// Marque un personnage du plateau.
struct CreatureComponent: Component {
    enum Role { case hero, enemy }
    let role: Role
}

/// Construit le diorama : une île flottante couverte d'un damier d'herbe,
/// avec rochers et arbres qui bloquent certaines cases.
@MainActor
enum TacticalBoardBuilder {
    static let gridSize = 9
    static let tileSize: Float = 0.07

    /// Cases occupées par un décor (infranchissables).
    static let obstacles: [GridPosition: Obstacle] = [
        GridPosition(x: 2, z: 2): .tree, GridPosition(x: 3, z: 2): .rock,
        GridPosition(x: 6, z: 5): .tree, GridPosition(x: 4, z: 4): .rock,
        GridPosition(x: 1, z: 4): .tree, GridPosition(x: 7, z: 7): .rock,
        GridPosition(x: 5, z: 6): .tree, GridPosition(x: 7, z: 1): .tree
    ]

    enum Obstacle { case tree, rock }

    /// Centre d'une case, sur le dessus des dalles (y = 0), dans le repère du plateau.
    static func center(of cell: GridPosition) -> SIMD3<Float> {
        let offset = Float(gridSize - 1) / 2
        return [(Float(cell.x) - offset) * tileSize, 0, (Float(cell.z) - offset) * tileSize]
    }

    static func isInside(_ cell: GridPosition) -> Bool {
        (0..<gridSize).contains(cell.x) && (0..<gridSize).contains(cell.z)
    }

    // MARK: - Île et dalles

    static func makeIsland() -> Entity {
        let island = Entity()
        island.name = "Island"
        let width = Float(gridSize) * tileSize

        // Socle de terre et sa bordure d'herbe
        island.addChild(Primitives.box([width + 0.03, 0.05, width + 0.03],
                                       Primitives.lit(Palette.dirt), cornerRadius: 0.01, at: [0, -0.031, 0]))
        island.addChild(Primitives.box([width + 0.034, 0.012, width + 0.034],
                                       Primitives.lit(Palette.grassDark), cornerRadius: 0.004, at: [0, -0.008, 0]))

        // Dessous rocheux en pointe : l'île flotte.
        let underside = Primitives.cone(height: 0.16, radius: width * 0.48,
                                        Primitives.lit(Palette.dirtDark), at: [0, -0.136, 0])
        underside.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        island.addChild(underside)
        for (x, z, r) in [(-0.16, 0.1, 0.05), (0.14, -0.12, 0.045), (0.05, 0.17, 0.035)] as [(Float, Float, Float)] {
            island.addChild(Primitives.sphere(r, Primitives.lit(Palette.rock), at: [x, -0.07, z], scale: [1, 0.7, 1]))
        }
        return island
    }

    static func makeTiles() -> Entity {
        let tiles = Entity()
        tiles.name = "Tiles"
        let mesh = MeshResource.generateBox(size: [tileSize - 0.003, 0.012, tileSize - 0.003], cornerRadius: 0.002)
        let light = Primitives.lit(Palette.grassLight, roughness: 0.9)
        let dark = Primitives.lit(Palette.grassDark, roughness: 0.9)

        for x in 0..<gridSize {
            for z in 0..<gridSize {
                let cell = GridPosition(x: x, z: z)
                let tile = ModelEntity(mesh: mesh, materials: [(x + z).isMultiple(of: 2) ? light : dark])
                tile.position = center(of: cell) + [0, -0.006, 0]
                tile.components.set(TileComponent(position: cell))
                tile.components.set(CollisionComponent(shapes: [.generateBox(size: [tileSize, 0.014, tileSize])]))
                tile.components.set(InputTargetComponent())
                tile.components.set(HoverEffectComponent())
                tiles.addChild(tile)
            }
        }
        return tiles
    }

    // MARK: - Décor

    static func makeObstacles() -> Entity {
        let decor = Entity()
        decor.name = "Obstacles"
        for (cell, kind) in obstacles {
            let entity = kind == .tree ? makeTree() : makeRock()
            entity.position = center(of: cell)
            entity.orientation = Primitives.yaw(Float(cell.x * 7 + cell.z * 3))
            decor.addChild(entity)
        }
        return decor
    }

    private static func makeTree() -> Entity {
        let tree = Entity()
        tree.addChild(Primitives.cylinder(height: 0.06, radius: 0.008, Primitives.lit(Palette.wood), at: [0, 0.03, 0]))
        tree.addChild(Primitives.cone(height: 0.08, radius: 0.032, Primitives.lit(Palette.leaf), at: [0, 0.085, 0]))
        tree.addChild(Primitives.cone(height: 0.06, radius: 0.024, Primitives.lit(Palette.leafLight), at: [0, 0.12, 0]))
        tree.components.set(GroundingShadowComponent(castsShadow: true))
        return tree
    }

    private static func makeRock() -> Entity {
        let rock = Entity()
        let material = Primitives.lit(Palette.rock, roughness: 0.95)
        rock.addChild(Primitives.sphere(0.026, material, at: [0, 0.016, 0], scale: [1.2, 0.8, 1]))
        rock.addChild(Primitives.sphere(0.016, material, at: [0.02, 0.01, 0.012], scale: [1, 0.8, 1]))
        rock.components.set(GroundingShadowComponent(castsShadow: true))
        return rock
    }

    // MARK: - Personnages

    static func makeHero() -> Entity {
        let hero = Entity()
        hero.name = "Hero"
        hero.addChild(HeroModel.make())
        hero.addChild(makeRing(Palette.heroRing))
        finishCreature(hero, role: .hero)
        return hero
    }

    static func makeEnemy() -> Entity {
        let enemy = Entity()
        enemy.name = "Enemy"
        let model = HedgehogElement.makeModel()
        model.scale = SIMD3(repeating: 0.32)
        model.position = [0, 0.034, 0]
        enemy.addChild(model)
        enemy.addChild(makeRing(Palette.enemyRing))
        finishCreature(enemy, role: .enemy)
        return enemy
    }

    /// Cercle de couleur sous un personnage (bleu = toi, rouge = adversaire).
    private static func makeRing(_ color: UIColor) -> Entity {
        let ring = Primitives.cylinder(height: 0.002, radius: tileSize * 0.42, Primitives.unlit(color), at: [0, 0.001, 0])
        let inner = Primitives.cylinder(height: 0.0025, radius: tileSize * 0.34,
                                        Primitives.lit(Palette.grassDark), at: [0, 0.0012, 0])
        let group = Entity()
        group.addChild(ring)
        group.addChild(inner)
        return group
    }

    private static func finishCreature(_ entity: Entity, role: CreatureComponent.Role) {
        let bounds = entity.visualBounds(relativeTo: entity)
        entity.components.set(CollisionComponent(shapes: [
            ShapeResource.generateBox(size: simd_max(bounds.extents, [0.05, 0.08, 0.05]))
                .offsetBy(translation: bounds.center)
        ]))
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())
        entity.components.set(GroundingShadowComponent(castsShadow: true))
        entity.components.set(CreatureComponent(role: role))
    }
}
