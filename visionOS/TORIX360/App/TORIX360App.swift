import SwiftUI

@main
struct TORIX360App: App {

    // Immersion style stored as @State so it can be mutated if needed
    @State private var immersionStyle: ImmersionStyle = .full

    var body: some Scene {

        // Entry window — shown before entering the immersive space
        WindowGroup {
            ContentView()
                .frame(width: 640, height: 480)
        }
        .windowStyle(.plain)

        // Full immersive space — takes over the entire field of view
        ImmersiveSpace(id: AppConstants.immersiveSpaceID) {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}

// MARK: - App-wide constants
enum AppConstants {
    static let immersiveSpaceID = "TORIX360Immersive"
    static let sphereRadius: Float = 10.0          // 10 m — surrounds the user
    static let portalRadius: Float = 0.3           // 30 cm portal spheres
    static let transitionDuration: Double = 1.0    // crossfade duration in seconds
}
