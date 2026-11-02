import ARKit
import Foundation
import Observation
import QuartzCore
import RealityKit
import UIKit

/// Un sort de la barre (touches 1 à 6). Noms et effets originaux.
struct SpellDefinition: Identifiable {
    let id: Int
    let name: String
    let symbol: String
    let color: UIColor
    let speed: Float
    let size: Float
    let cooldown: Double
    /// Le sort « Portail » déplace le joueur au lieu de lancer un projectile.
    var isPortal = false
}

struct InventoryItem: Identifiable {
    let id: ElementKind
    let name: String
    let symbol: String
    var count: Int
}

/// Le village à la première personne : le joueur ne bouge pas dans la pièce réelle,
/// c'est le monde qui glisse autour de lui (déplacement « artificiel »).
///
/// - clavier / manette : marcher dans la direction du regard, courir, pivoter par crans ;
/// - pincer le sol : un portail s'ouvre, on y est transporté ;
/// - 1 à 6 : sorts lancés dans la direction du regard ;
/// - I / M : inventaire et carte ;
/// - on ramasse les objets en passant à côté (ou en les pinçant).
@MainActor
@Observable
final class VillageWorld {
    // MARK: État affiché par le HUD

    private(set) var inventory: [InventoryItem] = []
    var showsInventory = false
    var showsMap = false
    private(set) var toast: String?
    private(set) var cooldowns: [Int: Double] = [:]
    private(set) var hits = 0
    private(set) var mapPosition = SIMD2<Float>.zero
    private(set) var mapHeading: Float = 0
    private(set) var creaturePositions: [SIMD2<Float>] = []
    private(set) var headTracking = false

    let spells: [SpellDefinition] = [
        SpellDefinition(id: 0, name: "Braise", symbol: "flame.fill", color: UIColor(hex: 0xFF8A2A), speed: 9, size: 0.09, cooldown: 0.6),
        SpellDefinition(id: 1, name: "Ondée", symbol: "drop.fill", color: UIColor(hex: 0x5EC8E0), speed: 7, size: 0.11, cooldown: 0.9),
        SpellDefinition(id: 2, name: "Ronce", symbol: "leaf.fill", color: UIColor(hex: 0x6DB24A), speed: 6, size: 0.12, cooldown: 1.2),
        SpellDefinition(id: 3, name: "Étincelle", symbol: "bolt.fill", color: UIColor(hex: 0xF2C230), speed: 14, size: 0.07, cooldown: 0.4),
        SpellDefinition(id: 4, name: "Poussière d'étoile", symbol: "sparkles", color: Palette.mauve, speed: 5, size: 0.14, cooldown: 1.5),
        SpellDefinition(id: 5, name: "Portail", symbol: "circle.circle", color: Palette.spellCyan, speed: 0, size: 0, cooldown: 2, isPortal: true)
    ]

    let layout: VillageLayout

    /// Racine du monde. Sa transformation est l'inverse de celle du joueur.
    let worldRoot = Entity()

    // MARK: Joueur

    @ObservationIgnored private var rigPosition = SIMD3<Float>.zero
    @ObservationIgnored private var rigYaw: Float = 0
    @ObservationIgnored private var glide: (from: SIMD3<Float>, to: SIMD3<Float>, elapsed: Float)?
    @ObservationIgnored private let input = PlayerInput()
    @ObservationIgnored private let effects = ElementEffects()

    // MARK: Suivi de la tête (ARKit)

    @ObservationIgnored private let arSession = ARKitSession()
    @ObservationIgnored private var worldTracking: WorldTrackingProvider?

    // MARK: Contenu vivant

    private struct Projectile {
        let entity: Entity
        var velocity: SIMD3<Float>
        var life: Float
        let color: UIColor
    }

    private struct Creature {
        let entity: Entity
        let home: SIMD2<Float>
        var target: SIMD2<Float>
        var flee: Float = 0
        var phase: Float
    }

    @ObservationIgnored private var projectiles: [Projectile] = []
    @ObservationIgnored private var creatures: [Creature] = []
    @ObservationIgnored private var collectibles: [(entity: Entity, kind: ElementKind)] = []
    @ObservationIgnored private var hudClock: Float = 0
    @ObservationIgnored private var rng = SeededRandom(seed: 99)
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init() {
        let (village, layout) = VillageBuilder.build()
        self.layout = layout
        worldRoot.name = "VillageWorld"
        worldRoot.addChild(village)
        worldRoot.addChild(makeAmbience())
        spawnCreatures()
        spawnCollectibles()
    }

    // MARK: - Cycle de vie

    func start() async {
        guard WorldTrackingProvider.isSupported else { return }
        let provider = WorldTrackingProvider()
        do {
            try await arSession.run([provider])
            worldTracking = provider
            headTracking = true
        } catch {
            print("[Village] Suivi de la tête indisponible : \(error)")
        }
    }

    func stop() {
        arSession.stop()
    }

    // MARK: - Boucle par image

    func update(deltaTime: Float) {
        let dt = min(deltaTime, 0.05)
        let head = headPose()
        let headWorld = worldRoot.convert(position: head.position, from: nil)
        let state = input.poll()

        for command in state.commands {
            handle(command, head: head, headWorld: headWorld)
        }

        if var current = glide {
            // Transport par portail : glissement rapide et doux.
            current.elapsed += dt
            let t = min(current.elapsed / 0.45, 1)
            let eased = t * t * (3 - 2 * t)
            rigPosition = current.from + (current.to - current.from) * eased
            glide = t >= 1 ? nil : current
        } else if simd_length(state.move) > 0.08 {
            let forward = flatten(head.forward)
            let right = SIMD3<Float>(-forward.z, 0, forward.x)
            let directionScene = forward * state.move.y + right * state.move.x
            let directionWorld = worldRoot.convert(direction: directionScene, from: nil)
            let speed: Float = state.run ? 4.2 : 1.8
            tryMove(by: flatten(directionWorld) * simd_length(directionScene) * speed * dt, from: headWorld)
        }

        applyRig()
        updateProjectiles(dt)
        updateCreatures(dt, headWorld: headWorld)
        updatePickups(headWorld: headWorld)
        updateCooldowns(dt)

        // Le HUD (carte, coordonnées) n'a pas besoin d'être rafraîchi à chaque image.
        hudClock += dt
        if hudClock > 0.15 {
            hudClock = 0
            mapPosition = [headWorld.x, headWorld.z]
            let forwardWorld = worldRoot.convert(direction: flatten(head.forward), from: nil)
            mapHeading = atan2(forwardWorld.x, -forwardWorld.z)
            creaturePositions = creatures.map { [$0.entity.position.x, $0.entity.position.z] }
        }
    }

    // MARK: - Interaction (pincement)

    /// `scenePoint` : point pincé, en coordonnées de la scène.
    func handleTap(on entity: Entity, scenePoint: SIMD3<Float>) {
        if let element = entity.firstAncestor(with: ElementComponent.self),
           let index = collectibles.firstIndex(where: { $0.entity === element }) {
            pickUp(at: index)
            return
        }
        if let portal = entity.firstAncestor(with: PortalLinkComponent.self),
           let destination = portal.components[PortalLinkComponent.self]?.destination {
            travel(to: destination, label: "Le portail t'emmène au bout du chemin nord.")
            return
        }
        if let creature = creatures.first(where: { entity.isSelf(orDescendantOf: $0.entity) }) {
            hitCreature(creature.entity)
            return
        }
        if entity.components.has(GroundComponent.self) {
            let target = worldRoot.convert(position: scenePoint, from: nil)
            let head = headPose()
            let headWorld = worldRoot.convert(position: head.position, from: nil)
            let offset = SIMD2<Float>(target.x - headWorld.x, target.z - headWorld.z)
            let maxJump: Float = 12
            let clamped = simd_length(offset) > maxJump ? simd_normalize(offset) * maxJump : offset
            travel(to: headWorld + [clamped.x, 0, clamped.y], label: nil)
        }
    }

    // MARK: - Commandes

    private func handle(_ command: PlayerInput.Command, head: (position: SIMD3<Float>, forward: SIMD3<Float>), headWorld: SIMD3<Float>) {
        switch command {
        case .inventory:
            showsInventory.toggle()
        case .map:
            showsMap.toggle()
        case .turnLeft:
            snapTurn(by: .pi / 6, head: head)
        case .turnRight:
            snapTurn(by: -.pi / 6, head: head)
        case .spell(let index):
            cast(index, head: head, headWorld: headWorld)
        }
    }

    /// Rotation par crans de 30°, autour de la tête (et non du centre de la pièce).
    private func snapTurn(by angle: Float, head: (position: SIMD3<Float>, forward: SIMD3<Float>)) {
        let headWorld = worldRoot.convert(position: head.position, from: nil)
        rigYaw += angle
        let headFlat = SIMD3<Float>(head.position.x, 0, head.position.z)
        let rotated = simd_quatf(angle: rigYaw, axis: [0, 1, 0]).act(headFlat)
        rigPosition = SIMD3(headWorld.x, 0, headWorld.z) - rotated
        applyRig()
    }

    private func travel(to destination: SIMD3<Float>, label: String?) {
        let head = headPose()
        let headWorld = worldRoot.convert(position: head.position, from: nil)
        let target = SIMD2<Float>(destination.x, destination.z)
        guard isWalkable(target) else {
            show("Impossible d'ouvrir un portail ici.")
            return
        }
        let delta = SIMD3<Float>(destination.x - headWorld.x, 0, destination.z - headWorld.z)
        spawnPortalFlash(at: [headWorld.x, 0.02, headWorld.z] + flatten(worldRoot.convert(direction: head.forward, from: nil)) * 0.8)
        spawnPortalFlash(at: [destination.x, 0.02, destination.z])
        glide = (rigPosition, rigPosition + delta, 0)
        if let label { show(label) }
    }

    // MARK: - Sorts

    private func cast(_ index: Int, head: (position: SIMD3<Float>, forward: SIMD3<Float>), headWorld: SIMD3<Float>) {
        guard spells.indices.contains(index) else { return }
        let spell = spells[index]
        guard (cooldowns[index] ?? 0) <= 0 else { return }
        cooldowns[index] = spell.cooldown

        let forwardWorld = simd_normalize(worldRoot.convert(direction: head.forward, from: nil))

        if spell.isPortal {
            var distance: Float = 6
            while distance > 1 {
                let candidate = headWorld + flatten(forwardWorld) * distance
                if isWalkable([candidate.x, candidate.z]) { break }
                distance -= 0.5
            }
            travel(to: headWorld + flatten(forwardWorld) * distance, label: nil)
            return
        }

        let orb = Primitives.sphere(spell.size, Primitives.unlit(spell.color))
        orb.position = headWorld + forwardWorld * 0.5 + [0, -0.15, 0]
        var trail = ParticleEmitterComponent.Presets.magic
        trail.emitterShape = .sphere
        trail.emitterShapeSize = SIMD3(repeating: spell.size)
        trail.mainEmitter.birthRate = 150
        trail.mainEmitter.size = 0.015
        trail.mainEmitter.color = .evolving(start: .single(spell.color), end: .single(spell.color.withAlphaComponent(0)))
        let trailEntity = Entity()
        trailEntity.components.set(trail)
        orb.addChild(trailEntity)
        worldRoot.addChild(orb)
        projectiles.append(Projectile(entity: orb, velocity: forwardWorld * spell.speed, life: 2.5, color: spell.color))
    }

    private func updateProjectiles(_ dt: Float) {
        var remaining: [Projectile] = []
        for var projectile in projectiles {
            projectile.life -= dt
            projectile.entity.position += projectile.velocity * dt
            let position = projectile.entity.position

            if let target = creatures.first(where: { simd_distance($0.entity.position + [0, 0.25, 0], position) < 0.55 }) {
                hitCreature(target.entity)
                finish(projectile)
            } else if projectile.life <= 0 || position.y < 0.05 {
                finish(projectile)
            } else {
                remaining.append(projectile)
            }
        }
        projectiles = remaining
    }

    private func finish(_ projectile: Projectile) {
        let position = projectile.entity.position
        projectile.entity.removeFromParent()
        let impact = Entity()
        impact.position = position
        worldRoot.addChild(impact)
        effects.burst(on: impact, color: projectile.color)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            impact.removeFromParent()
        }
    }

    // MARK: - Créatures

    private func spawnCreatures() {
        let homes: [SIMD2<Float>] = [[6, -6], [-7, -6], [12, -21], [-12, -23], [3, -30], [-3, -9], [14, -4]]
        for home in homes {
            let entity = Entity()
            let model = HedgehogElement.makeModel()
            model.scale = SIMD3(repeating: 1.6)
            model.position = [0, 0.16, 0]
            entity.addChild(model)
            entity.position = [home.x, 0, home.y]
            let bounds = entity.visualBounds(relativeTo: entity)
            entity.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents * 1.2).offsetBy(translation: bounds.center)]))
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())
            entity.components.set(GroundingShadowComponent(castsShadow: true))
            worldRoot.addChild(entity)
            creatures.append(Creature(entity: entity, home: home, target: home, phase: rng.float(0, 6)))
        }
    }

    private func updateCreatures(_ dt: Float, headWorld: SIMD3<Float>) {
        let player = SIMD2<Float>(headWorld.x, headWorld.z)
        for index in creatures.indices {
            var creature = creatures[index]
            let entity = creature.entity
            let position = SIMD2<Float>(entity.position.x, entity.position.z)
            creature.phase += dt

            var direction = SIMD2<Float>.zero
            var speed: Float = 0.5
            if creature.flee > 0 {
                creature.flee -= dt
                direction = position - player
                speed = 2.6
            } else {
                let toTarget = creature.target - position
                if simd_length(toTarget) < 0.3 {
                    creature.target = creature.home + [rng.float(-4, 4), rng.float(-4, 4)]
                    if !isWalkable(creature.target) { creature.target = creature.home }
                }
                direction = creature.target - position
            }

            if simd_length(direction) > 0.01 {
                let step = simd_normalize(direction) * speed * dt
                let next = position + step
                if isWalkable(next) {
                    entity.position = [next.x, 0.03 * abs(sin(creature.phase * 9)), next.y]
                } else {
                    creature.target = creature.home
                }
                entity.orientation = Primitives.yaw(atan2(direction.x, direction.y))
            }
            creatures[index] = creature
        }
    }

    private func hitCreature(_ entity: Entity) {
        guard let index = creatures.firstIndex(where: { $0.entity === entity }) else { return }
        creatures[index].flee = 2.5
        effects.react(entity, kind: .herisson)
        hits += 1
        show("Touché ! Le hérisson détale. (\(hits))")
    }

    // MARK: - Objets à ramasser

    private func spawnCollectibles() {
        let spots: [(ElementKind, SIMD2<Float>)] = [
            (.soulier, [2.6, -11.5]), (.cle, [10.5, -14]), (.eclatDeSort, [-11, -15]),
            (.chandelle, [-6.5, -27]), (.grimoire, [12, -7]), (.cle, [-2, -30])
        ]
        for (kind, spot) in spots {
            let entity = ElementFactory.make(kind, position: [spot.x, 1.0, spot.y], orientation: Primitives.yaw(rng.float(0, 6)))
            worldRoot.addChild(entity)
            collectibles.append((entity, kind))
        }
    }

    private func updatePickups(headWorld: SIMD3<Float>) {
        if let index = collectibles.firstIndex(where: {
            simd_distance(SIMD2($0.entity.position.x, $0.entity.position.z), SIMD2(headWorld.x, headWorld.z)) < 0.9
        }) {
            pickUp(at: index)
        }
    }

    private func pickUp(at index: Int) {
        let (entity, kind) = collectibles.remove(at: index)
        effects.react(entity, kind: kind)
        entity.components.remove(InputTargetComponent.self)
        if var levitation = entity.components[LevitationComponent.self] {
            levitation.fadeOutElapsed = 0
            entity.components.set(levitation)
        }

        let info = Self.itemInfo(kind)
        if let existing = inventory.firstIndex(where: { $0.id == kind }) {
            inventory[existing].count += 1
        } else {
            inventory.append(InventoryItem(id: kind, name: info.name, symbol: info.symbol, count: 1))
        }
        show("+1 \(info.name)")
    }

    private static func itemInfo(_ kind: ElementKind) -> (name: String, symbol: String) {
        switch kind {
        case .soulier: ("Soulier ocre et mauve", "shoe.fill")
        case .cle: ("Clé sans serrure", "key.fill")
        case .eclatDeSort: ("Éclat de sort", "sparkle")
        case .chandelle: ("Chandelle", "flame")
        case .grimoire: ("Grimoire", "book.closed.fill")
        case .herisson: ("Piquant de hérisson", "leaf")
        case .porte: ("Porte", "door.left.hand.closed")
        }
    }

    // MARK: - Déplacement et collisions

    private func applyRig() {
        let rig = Transform(scale: .one, rotation: simd_quatf(angle: rigYaw, axis: [0, 1, 0]), translation: rigPosition)
        worldRoot.transform = Transform(matrix: rig.matrix.inverse)
    }

    private func tryMove(by delta: SIMD3<Float>, from headWorld: SIMD3<Float>) {
        let head = SIMD2<Float>(headWorld.x, headWorld.z)
        let step = SIMD2<Float>(delta.x, delta.z)
        if isWalkable(head + step) {
            rigPosition += delta
        } else if isWalkable(head + [step.x, 0]) {
            rigPosition += [delta.x, 0, 0]       // glisse le long de l'obstacle
        } else if isWalkable(head + [0, step.y]) {
            rigPosition += [0, 0, delta.z]
        }
    }

    private func isWalkable(_ point: SIMD2<Float>) -> Bool {
        guard simd_length(point) < layout.walkableRadius else { return false }
        return !layout.obstacles.contains { simd_distance(point, $0.center) < $0.radius + 0.25 }
    }

    // MARK: - Tête

    private func headPose() -> (position: SIMD3<Float>, forward: SIMD3<Float>) {
        if let worldTracking, worldTracking.state == .running,
           let anchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            let matrix = anchor.originFromAnchorTransform
            let position = SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
            let forward = -SIMD3<Float>(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z)
            return (position, simd_normalize(forward))
        }
        // Simulateur ou suivi indisponible : tête debout au centre, regard droit devant.
        return ([0, 1.6, 0], [0, 0, -1])
    }

    private func flatten(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let flat = SIMD3<Float>(vector.x, 0, vector.z)
        return simd_length(flat) > 0.0001 ? simd_normalize(flat) : [0, 0, -1]
    }

    // MARK: - Effets, messages, sons

    private func spawnPortalFlash(at position: SIMD3<Float>) {
        var material = UnlitMaterial(color: Palette.spellCyan)
        material.blending = .transparent(opacity: 0.6)
        let ring = Primitives.cylinder(height: 0.01, radius: 0.7, material, at: position)
        worldRoot.addChild(ring)
        effects.burst(on: ring, color: Palette.spellCyan)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            ring.removeFromParent()
        }
    }

    private func updateCooldowns(_ dt: Float) {
        guard cooldowns.values.contains(where: { $0 > 0 }) else { return }
        for (index, remaining) in cooldowns where remaining > 0 {
            cooldowns[index] = max(0, remaining - Double(dt))
        }
    }

    private func show(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    /// Ambiance : gazouillis d'oiseaux générés (aucun son externe).
    private func makeAmbience() -> Entity {
        let entity = Entity()
        entity.name = "Ambience"
        entity.components.set(AmbientAudioComponent(gain: -14))
        Task { @MainActor in
            do {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("torix-birds.wav")
                try ToneGenerator.birds().write(to: url, options: .atomic)
                var configuration = AudioFileResource.Configuration()
                configuration.shouldLoop = true
                let resource = try await AudioFileResource(contentsOf: url, configuration: configuration)
                entity.playAudio(resource)
            } catch {
                print("[Village] Ambiance indisponible : \(error)")
            }
        }
        return entity
    }
}
