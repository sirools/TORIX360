import Foundation
import RealityKit
import UIKit

/// Construit la salle circulaire autour de l'utilisateur, uniquement avec des primitives :
/// dallage, murs de briques, plafond, torches vacillantes, brouillard au sol et bourdon d'ambiance.
///
/// Repère : origine = pieds de l'utilisateur, Y vers le haut, -Z devant lui.
@MainActor
enum DungeonRoomBuilder {
    static let radius: Float = 3.6
    static let wallHeight: Float = 3.8
    static let wallSegments = 20

    static func makeRoom() -> Entity {
        let room = Entity()
        room.name = "DungeonRoom"
        room.addChild(makeFloor())
        room.addChild(makeWalls())
        room.addChild(makeCeiling())
        room.addChild(makeTorches())
        room.addChild(makeFog())
        room.addChild(makeAmbience())
        return room
    }

    // MARK: - Sol

    private static func makeFloor() -> Entity {
        let floor = Entity()
        floor.name = "Floor"

        // Fond sombre visible entre les dalles.
        let base = Primitives.cylinder(height: 0.02, radius: radius + 0.3,
                                       Primitives.lit(Palette.black), at: [0, -0.045, 0])
        floor.addChild(base)

        let tile: Float = 0.6
        let tileMesh = MeshResource.generateBox(size: [tile - 0.025, 0.05, tile - 0.025], cornerRadius: 0.008)
        let materials = [Palette.floorDark, Palette.floorMid, Palette.stoneDark].map {
            Primitives.lit($0, roughness: 0.95)
        }

        var rng = SeededRandom(seed: 42)
        let half = Int(ceil(radius / tile))
        for ix in -half...half {
            for iz in -half...half {
                let x = Float(ix) * tile
                let z = Float(iz) * tile
                guard sqrt(x * x + z * z) < radius + 0.2 else { continue }
                let slab = ModelEntity(mesh: tileMesh, materials: [materials[rng.next(materials.count)]])
                slab.position = [x, -0.025 - rng.float(0, 0.012), z]
                floor.addChild(slab)
            }
        }
        return floor
    }

    // MARK: - Murs

    private static func makeWalls() -> Entity {
        let walls = Entity()
        walls.name = "Walls"

        let segmentWidth = 2 * radius * tan(.pi / Float(wallSegments)) + 0.02
        let rowHeight: Float = 0.38
        let rows = Int(wallHeight / rowHeight)
        let depth: Float = 0.3
        let materials = [Palette.stoneDark, Palette.stoneMid, Palette.stoneLight].map {
            Primitives.lit($0, roughness: 0.95)
        }
        // Deux tailles de briques seulement : on partage les maillages (plus rapide à construire).
        let halfBrick = MeshResource.generateBox(size: [segmentWidth / 2 - 0.025, rowHeight - 0.025, depth],
                                                 cornerRadius: 0.012)
        let fullBrick = MeshResource.generateBox(size: [segmentWidth - 0.025, rowHeight - 0.025, depth],
                                                 cornerRadius: 0.012)
        var rng = SeededRandom(seed: 7)

        for segment in 0..<wallSegments {
            let theta = Float(segment) * 2 * .pi / Float(wallSegments)
            let inward = SIMD3<Float>(-sin(theta), 0, cos(theta))   // vers le centre
            let tangent = SIMD3<Float>(cos(theta), 0, sin(theta))
            let center = SIMD3<Float>(sin(theta), 0, -cos(theta)) * (radius + depth / 2)
            let orientation = Primitives.yaw(-theta)

            for row in 0..<rows {
                // Appareillage décalé : 2 demi-briques une rangée sur deux, 1 brique pleine sinon.
                let bricks: [(offset: Float, mesh: MeshResource)] = row.isMultiple(of: 2)
                    ? [(-segmentWidth / 4, halfBrick), (segmentWidth / 4, halfBrick)]
                    : [(Float(0), fullBrick)]
                for brick in bricks {
                    let jut = rng.float(0, 0.04)   // certaines pierres dépassent un peu
                    let entity = ModelEntity(mesh: brick.mesh,
                                             materials: [materials[rng.next(materials.count)]])
                    entity.position = center + tangent * brick.offset + inward * jut
                        + [0, Float(row) * rowHeight + rowHeight / 2, 0]
                    entity.orientation = orientation
                    walls.addChild(entity)
                }
            }
        }
        return walls
    }

    // MARK: - Plafond

    private static func makeCeiling() -> Entity {
        let ceiling = Primitives.cylinder(height: 0.1, radius: radius + 0.4,
                                          Primitives.lit(Palette.ceiling), at: [0, wallHeight + 0.05, 0])
        ceiling.name = "Ceiling"
        return ceiling
    }

    // MARK: - Torches

    private static func makeTorches() -> Entity {
        let torches = Entity()
        torches.name = "Torches"
        let wood = Primitives.lit(Palette.woodDark)
        let iron = Primitives.lit(Palette.iron, roughness: 0.5, metallic: 0.8)

        for degrees: Float in [45, 135, 225, 315] {
            let theta = degrees * .pi / 180
            let torch = Entity()
            torch.position = SIMD3<Float>(sin(theta), 0, -cos(theta)) * (radius - 0.05) + [0, 1.9, 0]
            torch.orientation = Primitives.yaw(atan2(-torch.position.x, -torch.position.z))

            torch.addChild(Primitives.box([0.08, 0.12, 0.04], iron, at: [0, -0.05, -0.02]))
            let stick = Primitives.cylinder(height: 0.32, radius: 0.022, wood, at: [0, 0.02, 0.08])
            stick.orientation = simd_quatf(angle: 0.35, axis: [1, 0, 0])
            torch.addChild(stick)

            let flame = Entity()
            flame.position = [0, 0.22, 0.14]
            flame.addChild(Primitives.sphere(0.045, Primitives.unlit(Palette.flame), scale: [0.8, 1.5, 0.8]))
            flame.addChild(Primitives.sphere(0.024, Primitives.unlit(Palette.flameCore),
                                             at: [0, -0.01, 0], scale: [0.8, 1.4, 0.8]))
            flame.components.set(PointLightComponent(color: Palette.torchLight, intensity: 3500,
                                                     attenuationRadius: 5))
            flame.components.set(FlickerComponent(baseIntensity: 3500))

            var embers = ParticleEmitterComponent.Presets.sparks
            embers.emitterShapeSize = [0.04, 0.02, 0.04]
            embers.speed = 0.12
            embers.mainEmitter.birthRate = 6
            embers.mainEmitter.size = 0.004
            embers.mainEmitter.lifeSpan = 1.6
            embers.mainEmitter.color = .evolving(start: .single(Palette.flameCore),
                                                 end: .single(Palette.flame.withAlphaComponent(0)))
            flame.components.set(embers)

            torch.addChild(flame)
            torches.addChild(torch)
        }
        return torches
    }

    // MARK: - Brouillard

    /// Nappe de brume au ras du sol : de grosses particules très transparentes qui dérivent.
    private static func makeFog() -> Entity {
        var fog = ParticleEmitterComponent()
        fog.emitterShape = .box
        fog.birthLocation = .volume
        fog.emitterShapeSize = [radius * 1.8, 0.3, radius * 1.8]
        fog.speed = 0.015
        fog.mainEmitter.birthRate = 30
        fog.mainEmitter.lifeSpan = 12
        fog.mainEmitter.size = 0.9
        fog.mainEmitter.blendMode = .alpha
        fog.mainEmitter.color = .constant(.single(UIColor(white: 0.55, alpha: 0.05)))

        let entity = Entity()
        entity.name = "Fog"
        entity.position = [0, 0.2, 0]
        entity.components.set(fog)
        return entity
    }

    // MARK: - Ambiance sonore

    /// Bourdon grave en boucle, non spatialisé (il « vient » de toute la salle).
    private static func makeAmbience() -> Entity {
        let entity = Entity()
        entity.name = "Ambience"
        entity.components.set(AmbientAudioComponent(gain: -22))
        Task { @MainActor in
            do {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("torix-drone.wav")
                try ToneGenerator.drone().write(to: url, options: .atomic)
                var configuration = AudioFileResource.Configuration()
                configuration.shouldLoop = true
                let resource = try await AudioFileResource(contentsOf: url, configuration: configuration)
                entity.playAudio(resource)
            } catch {
                print("[Ambiance] Bourdon indisponible : \(error)")
            }
        }
        return entity
    }
}

/// Générateur pseudo-aléatoire déterministe : la salle est identique à chaque lancement.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 | 1 }

    mutating func nextUInt64() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Entier dans `0..<upperBound`.
    mutating func next(_ upperBound: Int) -> Int {
        Int(nextUInt64() % UInt64(upperBound))
    }

    /// Flottant dans `min...max`.
    mutating func float(_ min: Float, _ max: Float) -> Float {
        min + (max - min) * Float(nextUInt64() % 10_000) / 10_000
    }
}
