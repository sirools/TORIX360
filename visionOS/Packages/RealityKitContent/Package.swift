// swift-tools-version:5.9
// Paquet Reality Composer Pro : ouvre ce dossier dans Reality Composer Pro
// (File > Open) pour éditer visuellement le décor du donjon (DungeonDecor.usda).
import PackageDescription

let package = Package(
    name: "RealityKitContent",
    platforms: [
        .visionOS(.v1),
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "RealityKitContent", targets: ["RealityKitContent"])
    ],
    dependencies: [],
    targets: [
        .target(name: "RealityKitContent", dependencies: [])
    ]
)
