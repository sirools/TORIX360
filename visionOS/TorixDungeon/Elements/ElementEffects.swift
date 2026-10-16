import Foundation
import RealityKit
import UIKit

/// Réactions au pincement : rebond (via `LevitationComponent`), particules et son spatialisé.
@MainActor
final class ElementEffects {
    private var sounds: [ElementKind: AudioFileResource] = [:]

    func react(_ element: Entity, kind: ElementKind) {
        let type = ElementFactory.type(for: kind)

        if var state = element.components[LevitationComponent.self], state.fadeOutElapsed == nil {
            state.reactionElapsed = 0
            element.components.set(state)
        }
        burst(on: element, color: type.particleColor)
        playSound(on: element, kind: kind, notes: type.reactionNotes)
    }

    /// Gerbe d'étincelles colorées pendant un court instant.
    func burst(on entity: Entity, color: UIColor) {
        var sparks = ParticleEmitterComponent.Presets.sparks
        sparks.emitterShape = .sphere
        sparks.emitterShapeSize = [0.12, 0.12, 0.12]
        sparks.speed = 0.35
        sparks.mainEmitter.birthRate = 500
        sparks.mainEmitter.lifeSpan = 1.0
        sparks.mainEmitter.size = 0.01
        sparks.mainEmitter.color = .evolving(start: .single(color),
                                             end: .single(color.withAlphaComponent(0)))

        let fx = Entity()
        fx.components.set(sparks)
        entity.addChild(fx)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            if var emitter = fx.components[ParticleEmitterComponent.self] {
                emitter.isEmitting = false
                fx.components.set(emitter)
            }
            try? await Task.sleep(for: .seconds(2))
            fx.removeFromParent()
        }
    }

    /// Joue un petit carillon depuis la position de l'élément (audio spatial RealityKit).
    /// Placeholder généré par `ToneGenerator` ; à remplacer par de vrais sons via `ResourceProvider`.
    private func playSound(on entity: Entity, kind: ElementKind, notes: [Double]) {
        guard let resource = sound(for: kind, notes: notes) else { return }
        if !entity.components.has(SpatialAudioComponent.self) {
            entity.components.set(SpatialAudioComponent(gain: -4))
        }
        entity.playAudio(resource)
    }

    private func sound(for kind: ElementKind, notes: [Double]) -> AudioFileResource? {
        if let cached = sounds[kind] { return cached }
        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("torix-reaction-\(kind.rawValue).wav")
            try ToneGenerator.chime(notes: notes).write(to: url, options: .atomic)
            let resource = try AudioFileResource.load(contentsOf: url)
            sounds[kind] = resource
            return resource
        } catch {
            print("[Effets] Son indisponible pour \(kind): \(error)")
            return nil
        }
    }
}
