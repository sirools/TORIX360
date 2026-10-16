import RealityKit

/// État d'animation d'un élément : apparition (fondu + montée), lévitation,
/// réaction au pincement et disparition.
///
/// Tout est calculé à la main dans `LevitationSystem`, image par image :
/// simple à lire, simple à régler.
struct LevitationComponent: Component {
    var basePosition: SIMD3<Float>
    var baseOrientation: simd_quatf
    var tuning: LevitationTuning

    var elapsed: Float = 0
    var phaseOffset: Float = .random(in: 0...(2 * .pi))
    /// Fréquence du flottement (Hz).
    var frequency: Float = 0.3

    /// Non nil pendant la petite réaction (rebond) au pincement.
    var reactionElapsed: Float?
    static let reactionDuration: Float = 0.9

    /// Non nil pendant la disparition. L'entité est retirée de la scène à la fin.
    var fadeOutElapsed: Float?
    static let fadeOutDuration: Float = 1.6

    init(basePosition: SIMD3<Float>, baseOrientation: simd_quatf, tuning: LevitationTuning) {
        self.basePosition = basePosition
        self.baseOrientation = baseOrientation
        self.tuning = tuning
    }
}

struct LevitationSystem: System {
    private static let query = EntityQuery(where: .has(LevitationComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        var finished: [Entity] = []

        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var state = entity.components[LevitationComponent.self] else { continue }
            state.elapsed += dt

            // 1. Apparition : fondu + montée depuis un peu plus bas.
            let appear = smoothstep(state.elapsed / state.tuning.fadeInDuration)
            var opacity = appear
            var offsetY = -state.tuning.riseDistance * (1 - appear)

            // 2. Lévitation : léger va-et-vient vertical.
            offsetY += state.tuning.amplitude * appear
                * sin(2 * .pi * state.frequency * state.elapsed + state.phaseOffset)

            // 3. Réaction au pincement : petit bond + gonflement.
            var scale: Float = 1
            if let reaction = state.reactionElapsed {
                let k = reaction / LevitationComponent.reactionDuration
                if k >= 1 {
                    state.reactionElapsed = nil
                } else {
                    let bump = sin(k * .pi) * (1 - k * 0.5)
                    offsetY += 0.08 * bump
                    scale += 0.22 * bump
                    state.reactionElapsed = reaction + dt
                }
            }

            // 4. Disparition : fondu + envol.
            if let fadeOut = state.fadeOutElapsed {
                let k = smoothstep(fadeOut / LevitationComponent.fadeOutDuration)
                opacity *= 1 - k
                offsetY += 0.35 * k
                state.fadeOutElapsed = fadeOut + dt
                if fadeOut >= LevitationComponent.fadeOutDuration {
                    finished.append(entity)
                    continue
                }
            }

            entity.position = state.basePosition + [0, offsetY, 0]
            entity.orientation = state.baseOrientation
                * simd_quatf(angle: state.tuning.spinSpeed * state.elapsed, axis: [0, 1, 0])
            entity.scale = SIMD3(repeating: scale)
            entity.components.set(OpacityComponent(opacity: opacity))
            entity.components.set(state)
        }

        for entity in finished {
            entity.removeFromParent()
        }
    }

    private func smoothstep(_ x: Float) -> Float {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Scintillement des flammes

/// Fait vaciller une lumière ponctuelle (et la flamme qui la porte).
struct FlickerComponent: Component {
    var baseIntensity: Float
    var seed: Float = .random(in: 0...100)
    var time: Float = 0
}

struct FlickerSystem: System {
    private static let query = EntityQuery(where: .has(FlickerComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var flicker = entity.components[FlickerComponent.self] else { continue }
            flicker.time += dt
            let t = flicker.time + flicker.seed
            let k = 0.86 + 0.08 * sin(t * 11) + 0.05 * sin(t * 27.3) + 0.03 * sin(t * 53.1)

            if var light = entity.components[PointLightComponent.self] {
                light.intensity = flicker.baseIntensity * k
                entity.components.set(light)
            }
            entity.scale = [1, k, 1]
            entity.components.set(flicker)
        }
    }
}
