import Foundation
import RealityKit
import UIKit

/// Sol cliquable (pincer = ouvrir un portail et s'y rendre).
struct GroundComponent: Component {}

/// Portail de pierre : le pincer emmène ailleurs dans le village.
struct PortalLinkComponent: Component {
    let destination: SIMD3<Float>
}

/// Plan du village : sert aux collisions et à la carte (touche M).
struct VillageLayout {
    struct Obstacle {
        let center: SIMD2<Float>
        let radius: Float
    }

    var obstacles: [Obstacle] = []
    var houses: [SIMD2<Float>] = []
    var trees: [SIMD2<Float>] = []
    var paths: [(SIMD2<Float>, SIMD2<Float>)] = []
    var plaza = SIMD2<Float>(0, -14)
    var portal = SIMD2<Float>(5, -5)
    /// Rayon praticable autour du point d'arrivée.
    var walkableRadius: Float = 34
}

/// Construit la « Clairière de Bruyère » : un village original, d'inspiration fantasy colorée,
/// entièrement en primitives (aucun asset externe).
///
/// Repère : origine = point d'arrivée du joueur, Y vers le haut, -Z = devant au départ.
@MainActor
enum VillageBuilder {
    // Palette du village
    static let grass = UIColor(hex: 0x7DB341)
    static let grassDark = UIColor(hex: 0x5F9A35)
    static let grassLight = UIColor(hex: 0x9CC94F)
    static let grassYellow = UIColor(hex: 0xB9CC4A)
    static let dirt = UIColor(hex: 0xB89A6A)
    static let cobble = UIColor(hex: 0xC9C2B4)
    static let stone = UIColor(hex: 0xD8D1C2)
    static let whitewash = UIColor(hex: 0xEDE6D6)
    static let beam = UIColor(hex: 0x6A4A2E)
    static let roof = UIColor(hex: 0x3F7F92)
    static let roofDark = UIColor(hex: 0x2F6577)
    static let water = UIColor(hex: 0x5EC8E0)
    static let autumn = [UIColor(hex: 0xE9892B), UIColor(hex: 0xF2C230), UIColor(hex: 0xD9562B)]
    static let summer = [UIColor(hex: 0x4E9A3A), UIColor(hex: 0x6DB24A), UIColor(hex: 0x3F8A3A)]
    static let sky = UIColor(hex: 0x8FCBF0)

    static func build() -> (root: Entity, layout: VillageLayout) {
        var layout = VillageLayout()
        let root = Entity()
        root.name = "Village"
        var rng = SeededRandom(seed: 2026)

        layout.paths = [
            ([0, 0], [0, -14]), ([0, -14], [15, -14]), ([0, -14], [-15, -14]),
            ([0, -14], [0, -31]), ([0, -2], [5, -5])
        ]

        root.addChild(makeSkyAndLight())
        root.addChild(makeGround(&rng))
        root.addChild(makePaths(layout.paths, &rng))
        root.addChild(makePlaza(layout.plaza, &rng))
        layout.obstacles.append(.init(center: layout.plaza, radius: 1.5))

        // Maisons, porte tournée vers la place (ou vers le chemin d'arrivée).
        let houses: [SIMD2<Float>] = [[-8, -9], [8, -9.5], [-9, -19], [9, -18.5], [-4.8, -25], [4.8, -25.5], [-6, -2.5]]
        for (index, spot) in houses.enumerated() {
            let lookAt = index == houses.count - 1 ? SIMD2<Float>(0, -2.5) : layout.plaza
            let house = makeHouse(variant: index, &rng)
            house.position = [spot.x, 0, spot.y]
            house.orientation = Primitives.yaw(atan2(lookAt.x - spot.x, lookAt.y - spot.y))
            root.addChild(house)
            layout.houses.append(spot)
            layout.obstacles.append(.init(center: spot, radius: 1.9))
        }

        // Portail de pierre près de l'arrivée : il mène au bout du chemin nord.
        let portal = makePortal(destination: [0, 0, -29])
        portal.position = [layout.portal.x, 0, layout.portal.y]
        portal.orientation = Primitives.yaw(atan2(-layout.portal.x, -layout.portal.y))
        root.addChild(portal)
        layout.obstacles.append(.init(center: layout.portal, radius: 1.0))

        root.addChild(makeSignpost())
        layout.obstacles.append(.init(center: [1.8, -2.4], radius: 0.3))

        // Arbres : semés au hasard (graine fixe), loin des chemins, maisons et place.
        let trees = Entity()
        trees.name = "Trees"
        var attempts = 0
        while layout.trees.count < 75 && attempts < 3000 {
            attempts += 1
            let angle = rng.float(0, 2 * .pi)
            let distance = rng.float(5, 33)
            let spot = SIMD2<Float>(sin(angle) * distance, -cos(angle) * distance)
            guard isFree(spot, layout: layout, margin: 2.4) else { continue }
            let scale = rng.float(0.8, 1.4)
            let tree = makeTree(autumn: rng.next(3) != 0, scale: scale, &rng)
            tree.position = [spot.x, 0, spot.y]
            trees.addChild(tree)
            layout.trees.append(spot)
            layout.obstacles.append(.init(center: spot, radius: 0.35 * scale))
        }
        // Lisière de forêt au-delà de la zone praticable.
        for index in 0..<48 {
            let angle = Float(index) / 48 * 2 * .pi + rng.float(-0.05, 0.05)
            let distance = rng.float(37, 46)
            let tree = makeTree(autumn: rng.next(4) == 0, scale: rng.float(1.4, 2.2), &rng)
            tree.position = [sin(angle) * distance, 0, -cos(angle) * distance]
            trees.addChild(tree)
        }
        root.addChild(trees)

        root.addChild(makeScatter(layout: layout, &rng))
        root.addChild(makeHills(&rng))
        return (root, layout)
    }

    // MARK: - Ciel et lumière

    private static func makeSkyAndLight() -> Entity {
        let group = Entity()
        group.name = "Sky"

        // Dôme céleste : grande sphère retournée (on la voit de l'intérieur).
        let dome = Primitives.sphere(250, Primitives.unlit(sky))
        dome.scale = [-1, 1, 1]
        group.addChild(dome)

        // Soleil et nuages
        let sunDirection = simd_normalize(SIMD3<Float>(-0.5, 0.55, -0.65))
        group.addChild(Primitives.sphere(9, Primitives.unlit(UIColor(hex: 0xFFF4D6)), at: sunDirection * 180))
        var rng = SeededRandom(seed: 11)
        let cloudMaterial = Primitives.unlit(UIColor(white: 1, alpha: 1))
        for _ in 0..<12 {
            let angle = rng.float(0, 2 * .pi)
            let center = SIMD3<Float>(sin(angle) * rng.float(90, 140), rng.float(35, 60), -cos(angle) * rng.float(90, 140))
            for _ in 0..<4 {
                group.addChild(Primitives.sphere(rng.float(5, 9), cloudMaterial,
                                                 at: center + [rng.float(-9, 9), rng.float(-2, 2), rng.float(-5, 5)],
                                                 scale: [1.4, 0.55, 1]))
            }
        }

        // Soleil (avec ombres) + lumière d'appoint douce venant du ciel opposé.
        let sun = Entity()
        var sunLight = DirectionalLightComponent(color: UIColor(hex: 0xFFF1D0), intensity: 5000)
        sunLight.isRealWorldProxy = false
        sun.components.set(sunLight)
        sun.components.set(DirectionalLightComponent.Shadow(maximumDistance: 25, depthBias: 2))
        sun.look(at: .zero, from: sunDirection * 20, relativeTo: nil)
        group.addChild(sun)

        let fill = Entity()
        fill.components.set(DirectionalLightComponent(color: UIColor(hex: 0xBFDFFF), intensity: 1800))
        fill.look(at: .zero, from: [0.6, 0.8, 0.7], relativeTo: nil)
        group.addChild(fill)
        return group
    }

    // MARK: - Sol

    private static func makeGround(_ rng: inout SeededRandom) -> Entity {
        let ground = Primitives.cylinder(height: 0.2, radius: 90, Primitives.lit(grass, roughness: 1), at: [0, -0.1, 0])
        ground.name = "Ground"
        ground.components.set(CollisionComponent(shapes: [.generateBox(size: [180, 0.2, 180])]))
        ground.components.set(InputTargetComponent())
        ground.components.set(GroundComponent())

        // Taches de couleur pour un rendu « peint ».
        let patches = [grassDark, grassLight, grassYellow].map { Primitives.lit($0, roughness: 1) }
        for index in 0..<110 {
            let angle = rng.float(0, 2 * .pi)
            let distance = rng.float(0, 40)
            let patch = Primitives.cylinder(height: 0.01, radius: rng.float(0.8, 3.2), patches[rng.next(patches.count)],
                                            at: [sin(angle) * distance, 0.1 + 0.002 * Float(index % 5), -cos(angle) * distance])
            patch.scale = [1, 1, rng.float(0.5, 1)]
            ground.addChild(patch)
        }
        return ground
    }

    // MARK: - Chemins et place

    private static func makePaths(_ paths: [(SIMD2<Float>, SIMD2<Float>)], _ rng: inout SeededRandom) -> Entity {
        let group = Entity()
        group.name = "Paths"
        let dirtMaterial = Primitives.lit(dirt, roughness: 1)
        let cobbleMaterial = Primitives.lit(cobble, roughness: 0.95)
        let dirtMesh = MeshResource.generateCylinder(height: 0.012, radius: 0.9)
        let cobbleMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.25)

        for (start, end) in paths {
            let length = simd_length(end - start)
            let steps = Int(length / 0.6)
            let side = simd_normalize(SIMD2<Float>(-(end - start).y, (end - start).x))
            for step in 0...steps {
                let t = Float(step) / Float(max(steps, 1))
                let point = start + (end - start) * t
                let dirtEntity = ModelEntity(mesh: dirtMesh, materials: [dirtMaterial])
                dirtEntity.position = [point.x + rng.float(-0.15, 0.15), 0.008, point.y + rng.float(-0.15, 0.15)]
                dirtEntity.scale = [rng.float(0.85, 1.2), 1, rng.float(0.85, 1.2)]
                group.addChild(dirtEntity)

                if rng.next(10) < 6 {
                    let offset = side * rng.float(-0.6, 0.6)
                    let cobbleEntity = ModelEntity(mesh: cobbleMesh, materials: [cobbleMaterial])
                    cobbleEntity.position = [point.x + offset.x, 0.02, point.y + offset.y]
                    cobbleEntity.scale = [rng.float(0.7, 1.4), 1, rng.float(0.6, 1.1)]
                    cobbleEntity.orientation = Primitives.yaw(rng.float(0, .pi))
                    group.addChild(cobbleEntity)
                }
            }
        }
        return group
    }

    private static func makePlaza(_ center: SIMD2<Float>, _ rng: inout SeededRandom) -> Entity {
        let plaza = Entity()
        plaza.name = "Plaza"
        plaza.position = [center.x, 0, center.y]

        plaza.addChild(Primitives.cylinder(height: 0.03, radius: 4.6, Primitives.lit(stone, roughness: 0.95), at: [0, 0.015, 0]))
        let cobbleMaterial = Primitives.lit(cobble, roughness: 0.95)
        for ring in 0..<3 {
            let radius = 1.9 + Float(ring) * 0.9
            let count = 14 + ring * 7
            for index in 0..<count {
                let angle = Float(index) / Float(count) * 2 * .pi + Float(ring) * 0.2
                let block = Primitives.box([0.55, 0.035, 0.38], cobbleMaterial, cornerRadius: 0.05,
                                           at: [sin(angle) * radius, 0.035, cos(angle) * radius])
                block.orientation = Primitives.yaw(angle + rng.float(-0.1, 0.1))
                plaza.addChild(block)
            }
        }

        // Fontaine
        let stoneMaterial = Primitives.lit(stone, roughness: 0.9)
        plaza.addChild(Primitives.cylinder(height: 0.5, radius: 1.25, stoneMaterial, at: [0, 0.25, 0]))
        var waterMaterial = PhysicallyBasedMaterial()
        waterMaterial.baseColor = .init(tint: water)
        waterMaterial.roughness = 0.1
        waterMaterial.emissiveColor = .init(color: water)
        waterMaterial.emissiveIntensity = 0.3
        plaza.addChild(Primitives.cylinder(height: 0.02, radius: 1.1, waterMaterial, at: [0, 0.46, 0]))
        plaza.addChild(Primitives.cylinder(height: 1.3, radius: 0.16, stoneMaterial, at: [0, 0.9, 0]))
        plaza.addChild(Primitives.cylinder(height: 0.14, radius: 0.5, stoneMaterial, at: [0, 1.55, 0]))
        plaza.addChild(Primitives.sphere(0.12, Primitives.glowing(water, intensity: 2), at: [0, 1.7, 0]))

        var spray = ParticleEmitterComponent.Presets.magic
        spray.emitterShape = .sphere
        spray.emitterShapeSize = [0.3, 0.1, 0.3]
        spray.mainEmitter.birthRate = 60
        spray.mainEmitter.size = 0.02
        spray.mainEmitter.color = .constant(.single(UIColor(hex: 0xD8F6FF)))
        let sprayEntity = Entity()
        sprayEntity.position = [0, 1.7, 0]
        sprayEntity.components.set(spray)
        plaza.addChild(sprayEntity)
        return plaza
    }

    // MARK: - Maisons

    /// Maisonnette originale : socle de pierre, murs chaulés, colombages, toit à deux pans bleu-vert.
    /// Porte sur la face +Z.
    private static func makeHouse(variant: Int, _ rng: inout SeededRandom) -> Entity {
        let house = Entity()
        let width: Float = 2.6 + Float(variant % 3) * 0.3
        let depth: Float = 2.4
        let height: Float = 2.4 + Float(variant % 2) * 0.5

        let stoneMaterial = Primitives.lit(stone, roughness: 0.95)
        let wallMaterial = Primitives.lit(whitewash, roughness: 0.9)
        let beamMaterial = Primitives.lit(beam, roughness: 0.85)
        let roofMaterial = Primitives.lit(variant.isMultiple(of: 2) ? roof : roofDark, roughness: 0.7)

        house.addChild(Primitives.box([width + 0.3, 0.35, depth + 0.3], stoneMaterial, cornerRadius: 0.05, at: [0, 0.175, 0]))
        house.addChild(Primitives.box([width, height, depth], wallMaterial, at: [0, 0.35 + height / 2, 0]))

        // Colombages d'angle et poutre haute
        for x in [-width / 2, width / 2] {
            for z in [-depth / 2, depth / 2] {
                house.addChild(Primitives.box([0.16, height, 0.16], beamMaterial, at: [x, 0.35 + height / 2, z]))
            }
        }
        house.addChild(Primitives.box([width + 0.1, 0.14, 0.14], beamMaterial, at: [0, 0.35 + height, depth / 2]))

        // Porte arrondie
        let doorHeight: Float = 1.5
        house.addChild(Primitives.box([0.85, doorHeight, 0.08], beamMaterial, at: [0, 0.35 + doorHeight / 2, depth / 2 + 0.02]))
        let arch = Primitives.cylinder(height: 0.08, radius: 0.425, beamMaterial, at: [0, 0.35 + doorHeight, depth / 2 + 0.02])
        arch.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        house.addChild(arch)
        house.addChild(Primitives.sphere(0.05, Primitives.lit(Palette.gold, roughness: 0.3, metallic: 1),
                                         at: [0.28, 0.35 + doorHeight * 0.5, depth / 2 + 0.08]))

        // Fenêtres
        let glass = Primitives.glowing(UIColor(hex: 0xFFD98A), intensity: 0.6)
        for x in [-width / 2 + 0.5, width / 2 - 0.5] where width > 2.7 || x > 0 {
            house.addChild(Primitives.box([0.5, 0.5, 0.06], glass, at: [x, 0.35 + height * 0.62, depth / 2 + 0.02]))
            house.addChild(Primitives.box([0.62, 0.08, 0.1], beamMaterial, at: [x, 0.35 + height * 0.62 - 0.29, depth / 2 + 0.04]))
        }

        // Toit à deux pans (faîtage selon X)
        let roofBase = 0.35 + height
        let pitch: Float = 0.62
        let slopeLength = (depth / 2 + 0.35) / cos(pitch)
        for sign: Float in [-1, 1] {
            let slope = Primitives.box([width + 0.6, 0.2, slopeLength], roofMaterial, cornerRadius: 0.04)
            slope.orientation = simd_quatf(angle: sign * pitch, axis: [1, 0, 0])
            slope.position = [0, roofBase + sin(pitch) * slopeLength / 2, sign * cos(pitch) * slopeLength / 2]
            house.addChild(slope)
        }
        // Pignons
        let gableHeight = tan(pitch) * depth / 2
        for x in [-width / 2, width / 2] {
            let gable = Primitives.box([0.12, gableHeight * 0.7, depth * 0.55], wallMaterial,
                                       at: [x, roofBase + gableHeight * 0.35, 0])
            house.addChild(gable)
        }
        // Cheminée
        house.addChild(Primitives.box([0.4, 1.1, 0.4], stoneMaterial, at: [width / 2 - 0.5, roofBase + 0.7, -0.35]))

        house.components.set(GroundingShadowComponent(castsShadow: true))
        return house
    }

    // MARK: - Portail, panneau

    private static func makePortal(destination: SIMD3<Float>) -> Entity {
        let portal = Entity()
        portal.name = "Portal"
        let stoneMaterial = Primitives.lit(stone, roughness: 0.9)
        let runeMaterial = Primitives.glowing(Palette.spellCyan, intensity: 1.5)
        let radius: Float = 1.25
        let count = 14
        for index in 0..<count {
            // Arche : on ne garde pas les blocs sous le sol.
            let angle = Float(index) / Float(count) * 2 * .pi
            let center = SIMD3<Float>(sin(angle) * radius, 1.25 + cos(angle) * radius, 0)
            guard center.y > 0.1 else { continue }
            let block = Primitives.box([0.42, 0.34, 0.4], stoneMaterial, cornerRadius: 0.05, at: center)
            block.orientation = simd_quatf(angle: -angle, axis: [0, 0, 1])
            portal.addChild(block)
            if index.isMultiple(of: 3) {
                portal.addChild(Primitives.box([0.1, 0.1, 0.02], runeMaterial, at: center + [0, 0, 0.21]))
            }
        }
        portal.addChild(Primitives.box([0.7, 0.3, 0.6], stoneMaterial, cornerRadius: 0.05, at: [-1.1, 0.15, 0]))
        portal.addChild(Primitives.box([0.7, 0.3, 0.6], stoneMaterial, cornerRadius: 0.05, at: [1.1, 0.15, 0]))

        var veilMaterial = UnlitMaterial(color: Palette.spellCyan)
        veilMaterial.blending = .transparent(opacity: 0.45)
        let veil = Primitives.cylinder(height: 0.03, radius: 1.05, veilMaterial, at: [0, 1.25, 0])
        veil.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        portal.addChild(veil)

        var swirl = ParticleEmitterComponent.Presets.magic
        swirl.emitterShape = .sphere
        swirl.emitterShapeSize = [1.6, 1.6, 0.1]
        swirl.mainEmitter.birthRate = 80
        swirl.mainEmitter.size = 0.02
        swirl.mainEmitter.color = .constant(.single(Palette.spellCyan))
        let swirlEntity = Entity()
        swirlEntity.position = [0, 1.25, 0]
        swirlEntity.components.set(swirl)
        portal.addChild(swirlEntity)

        let bounds = portal.visualBounds(relativeTo: portal)
        portal.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)]))
        portal.components.set(InputTargetComponent())
        portal.components.set(HoverEffectComponent())
        portal.components.set(PortalLinkComponent(destination: destination))
        portal.components.set(GroundingShadowComponent(castsShadow: true))
        return portal
    }

    private static func makeSignpost() -> Entity {
        let sign = Entity()
        sign.position = [1.8, 0, -2.4]
        sign.orientation = Primitives.yaw(atan2(-1.8, 2.4))
        let wood = Primitives.lit(beam, roughness: 0.85)
        sign.addChild(Primitives.cylinder(height: 1.6, radius: 0.06, wood, at: [0, 0.8, 0]))
        sign.addChild(Primitives.box([1.1, 0.42, 0.06], Primitives.lit(UIColor(hex: 0xA77B4F), roughness: 0.85),
                                     cornerRadius: 0.03, at: [0, 1.45, 0]))

        let mesh = MeshResource.generateText("Clairière de Bruyère", extrusionDepth: 0.01,
                                             font: .boldSystemFont(ofSize: 0.09))
        let text = ModelEntity(mesh: mesh, materials: [Primitives.unlit(UIColor(hex: 0xFFF3D9))])
        let bounds = text.visualBounds(relativeTo: nil)
        text.position = [-bounds.center.x, 1.45 - bounds.center.y, 0.035]
        sign.addChild(text)
        return sign
    }

    // MARK: - Végétation, rochers, collines

    private static func makeTree(autumn: Bool, scale: Float, _ rng: inout SeededRandom) -> Entity {
        let tree = Entity()
        let trunkHeight: Float = 1.6 * scale
        tree.addChild(Primitives.cylinder(height: trunkHeight, radius: 0.13 * scale,
                                          Primitives.lit(beam, roughness: 0.9), at: [0, trunkHeight / 2, 0]))
        let palette = autumn ? Self.autumn : Self.summer
        let clusters = 3 + rng.next(3)
        for _ in 0..<clusters {
            let radius = rng.float(0.55, 0.9) * scale
            let offset = SIMD3<Float>(rng.float(-0.5, 0.5) * scale, trunkHeight + rng.float(0.1, 0.9) * scale, rng.float(-0.5, 0.5) * scale)
            tree.addChild(Primitives.sphere(radius, Primitives.lit(palette[rng.next(palette.count)], roughness: 0.9),
                                            at: offset, scale: [1, 0.85, 1]))
        }
        tree.components.set(GroundingShadowComponent(castsShadow: true))
        return tree
    }

    private static func makeScatter(layout: VillageLayout, _ rng: inout SeededRandom) -> Entity {
        let group = Entity()
        group.name = "Scatter"
        let flowerMesh = MeshResource.generateSphere(radius: 0.035)
        let flowerMaterials = [UIColor.white, UIColor(hex: 0xFFE27A), UIColor(hex: 0xF7A8C8)].map { Primitives.lit($0, roughness: 0.8) }
        let bushMaterials = summer.map { Primitives.lit($0, roughness: 0.9) }
        let rockMaterial = Primitives.lit(UIColor(hex: 0xA9A397), roughness: 0.95)

        for _ in 0..<260 {
            let spot = randomSpot(&rng, maxDistance: 34)
            guard isFree(spot, layout: layout, margin: 0.9) else { continue }
            let flower = ModelEntity(mesh: flowerMesh, materials: [flowerMaterials[rng.next(flowerMaterials.count)]])
            flower.position = [spot.x, 0.04, spot.y]
            group.addChild(flower)
        }
        for _ in 0..<70 {
            let spot = randomSpot(&rng, maxDistance: 34)
            guard isFree(spot, layout: layout, margin: 1.4) else { continue }
            let bush = Entity()
            bush.position = [spot.x, 0, spot.y]
            for _ in 0..<(2 + rng.next(2)) {
                bush.addChild(Primitives.sphere(rng.float(0.25, 0.45), bushMaterials[rng.next(bushMaterials.count)],
                                                at: [rng.float(-0.3, 0.3), 0.18, rng.float(-0.3, 0.3)], scale: [1, 0.7, 1]))
            }
            group.addChild(bush)
        }
        for _ in 0..<22 {
            let spot = randomSpot(&rng, maxDistance: 34)
            guard isFree(spot, layout: layout, margin: 1.4) else { continue }
            group.addChild(Primitives.sphere(rng.float(0.2, 0.5), rockMaterial, at: [spot.x, 0.05, spot.y], scale: [1.3, 0.6, 1]))
        }
        return group
    }

    private static func makeHills(_ rng: inout SeededRandom) -> Entity {
        let hills = Entity()
        hills.name = "Hills"
        let materials = [grassDark, grass, UIColor(hex: 0x4F8A3A)].map { Primitives.lit($0, roughness: 1) }
        for index in 0..<18 {
            let angle = Float(index) / 18 * 2 * .pi + rng.float(-0.1, 0.1)
            let distance = rng.float(62, 78)
            hills.addChild(Primitives.sphere(rng.float(14, 24), materials[rng.next(materials.count)],
                                             at: [sin(angle) * distance, -4, -cos(angle) * distance], scale: [1.4, 0.55, 1]))
        }
        return hills
    }

    // MARK: - Aides

    private static func randomSpot(_ rng: inout SeededRandom, maxDistance: Float) -> SIMD2<Float> {
        let angle = rng.float(0, 2 * .pi)
        let distance = sqrt(rng.float(0, 1)) * maxDistance
        return [sin(angle) * distance, -cos(angle) * distance]
    }

    /// Vrai si le point est loin des chemins, de la place, des maisons, du portail et de l'arrivée.
    static func isFree(_ spot: SIMD2<Float>, layout: VillageLayout, margin: Float) -> Bool {
        if simd_length(spot) < 3 { return false }
        if simd_distance(spot, layout.plaza) < 5.5 { return false }
        if simd_distance(spot, layout.portal) < 2.5 { return false }
        for (start, end) in layout.paths where distanceToSegment(spot, start, end) < margin + 0.6 {
            return false
        }
        for obstacle in layout.obstacles where simd_distance(spot, obstacle.center) < obstacle.radius + margin {
            return false
        }
        return true
    }

    static func distanceToSegment(_ point: SIMD2<Float>, _ start: SIMD2<Float>, _ end: SIMD2<Float>) -> Float {
        let segment = end - start
        let t = max(0, min(1, simd_dot(point - start, segment) / max(simd_length_squared(segment), 0.0001)))
        return simd_distance(point, start + segment * t)
    }
}
