import RealityKit
import UIKit

/// Petites briques géométriques pour fabriquer les placeholders.
/// Remplaçables plus tard par des USDZ (bundle ou NAS) sans toucher au reste.
@MainActor
enum Primitives {
    // MARK: Matériaux

    /// Matériau mat éclairé par la scène (torches, chandelles…).
    static func lit(_ color: UIColor, roughness: Float = 0.85, metallic: Float = 0) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: roughness)
        material.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: metallic)
        return material
    }

    /// Matériau qui « brille » légèrement tout en restant éclairé.
    static func glowing(_ color: UIColor, intensity: Float = 1.5) -> PhysicallyBasedMaterial {
        var material = lit(color, roughness: 0.4)
        material.emissiveColor = .init(color: color)
        material.emissiveIntensity = intensity
        return material
    }

    /// Matériau non éclairé : couleur pleine, idéal pour flammes et cristaux.
    static func unlit(_ color: UIColor) -> UnlitMaterial {
        UnlitMaterial(color: color)
    }

    // MARK: Formes

    static func box(_ size: SIMD3<Float>, _ material: any Material, cornerRadius: Float = 0,
                    at position: SIMD3<Float> = .zero) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: size, cornerRadius: cornerRadius),
                                 materials: [material])
        entity.position = position
        return entity
    }

    static func sphere(_ radius: Float, _ material: any Material,
                       at position: SIMD3<Float> = .zero, scale: SIMD3<Float> = .one) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material])
        entity.position = position
        entity.scale = scale
        return entity
    }

    /// Cylindre vertical (axe Y), centré sur `position`.
    static func cylinder(height: Float, radius: Float, _ material: any Material,
                         at position: SIMD3<Float> = .zero) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateCylinder(height: height, radius: radius),
                                 materials: [material])
        entity.position = position
        return entity
    }

    /// Cône dont la pointe est vers +Y (avant rotation), centré sur `position`.
    static func cone(height: Float, radius: Float, _ material: any Material,
                     at position: SIMD3<Float> = .zero) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateCone(height: height, radius: radius),
                                 materials: [material])
        entity.position = position
        return entity
    }

    // MARK: Orientation

    /// Rotation autour de l'axe vertical.
    static func yaw(_ radians: Float) -> simd_quatf {
        simd_quatf(angle: radians, axis: [0, 1, 0])
    }
}
