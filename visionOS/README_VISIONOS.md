# TORIX360 — Apple Vision Pro (visionOS)

Native visionOS port of the TORIX360 immersive web experience.
Built with **RealityKit + SwiftUI**, targeting **visionOS 1.0+**.

---

## Architecture

```
visionOS/TORIX360/
├── App/
│   └── TORIX360App.swift          # App entry point + ImmersiveSpace registration
├── Views/
│   ├── ContentView.swift          # Launch screen ("Entrer dans TORIX" button)
│   ├── ImmersiveView.swift        # Full-immersion RealityKit scene (main loop)
│   └── InterstitialView.swift     # Narrative overlay between worlds
├── ViewModels/
│   └── WorldViewModel.swift       # Reactive state (current world, transition lock)
├── Entities/
│   ├── SphereWorldEntity.swift    # 6 panoramic sphere worlds + crossfade
│   └── PortalEntity.swift         # Interactive portal balls (look + pinch to travel)
└── Managers/
    └── PortalManager.swift        # World adjacency graph + portal colours
```

### JS → Swift mapping

| Web (Three.js)              | visionOS (RealityKit)              |
|-----------------------------|------------------------------------|
| `SphereManager`             | `SphereWorldEntity`                |
| `portalManager.js`          | `PortalManager`                    |
| `PortalFunctions.js`        | `PortalEntity` + `ImmersiveView`   |
| `interstitialComponent.js`  | `InterstitialView`                 |
| `main.js` (global state)    | `WorldViewModel`                   |
| Mouse click on portal       | Look at portal + pinch (index+thumb)|
| `OrbitControls`             | Head tracking (built-in visionOS)  |
| `SphereGeometry.scale(-1)`  | `entity.scale = SIMD3(-1, 1, 1)`  |
| `requestAnimationFrame`     | `Task` / RealityKit render loop    |

---

## Prerequisites

| Tool | Version |
|------|---------|
| Mac  | macOS 14 Sonoma or later |
| Xcode | 15.2 or later |
| Apple Vision Pro | Device or visionOS Simulator |
| Apple Developer Account | Required to run on device |

---

## Setup in Xcode

### 1. Create a new visionOS project

1. Open **Xcode → File → New → Project**
2. Select **visionOS → App**
3. Name it `TORIX360`
4. Set **Interface** to `SwiftUI`, **Language** to `Swift`
5. Enable **"Include immersive space"** if the option is shown
6. Choose a location and click **Create**

### 2. Add the Swift source files

Delete the placeholder files Xcode generates (`ContentView.swift`, etc.) and drag
in the files from this folder, preserving the group structure:

```
App/TORIX360App.swift
Views/ContentView.swift
Views/ImmersiveView.swift
Views/InterstitialView.swift
ViewModels/WorldViewModel.swift
Entities/SphereWorldEntity.swift
Entities/PortalEntity.swift
Managers/PortalManager.swift
```

### 3. Add the panoramic image assets

Drag the following files from `src/assets/images/` into **Assets.xcassets**
(Xcode will create image set entries automatically):

```
artwork1.jpg
artwork2.jpg
artwork3.jpg
artwork4.jpg
artwork5.jpg
artwork-final-V1.jpg
```

> **Important:** The asset names in Xcode must match exactly what is listed in
> `SphereWorldEntity.imageNames`. If Xcode renames `artwork-final-V1` to
> `artwork-final-V1 1`, update the array accordingly.

### 4. Configure Info.plist

Add the following key so visionOS allows full immersion:

```xml
<key>NSWorldSensingUsageDescription</key>
<string>TORIX360 uses spatial awareness to place portals in your environment.</string>
```

In Xcode: **Target → Info → Custom iOS Target Properties → + → NSWorldSensingUsageDescription**

### 5. Set the Deployment Target

**Target → General → Minimum Deployments → visionOS 1.0**

### 6. Build & Run

- **Simulator:** Select `Apple Vision Pro` simulator → ▶ Run
- **Device:** Connect Vision Pro via cable, trust the device, select it → ▶ Run

---

## Interaction model

| Action | Vision Pro gesture |
|--------|--------------------|
| Look around the 360° world | Move your head naturally |
| Highlight a portal | Look directly at it (gaze hover) |
| Travel through a portal | Look at it + **pinch** (index finger + thumb) |
| Dismiss interstitial | Tap "Explorer" or pinch outside the panel |

---

## Extending the experience

### Add the 3D models (champagne, pearl)

Convert the existing GLTF assets to USDZ:

```bash
# Install Reality Converter or use the usdzconvert CLI
usdzconvert src/assets/models/champagne.gltf champagne.usdz
usdzconvert src/assets/models/pearl.gltf pearl.usdz
```

Then load them in `ImmersiveView`:

```swift
if let entity = try? await Entity(named: "champagne") {
    entity.position = SIMD3(0, 0, -2)
    content.add(entity)
}
```

### Spatial audio

Add ambient audio per world using `SpatialAudioComponent`:

```swift
var audio = SpatialAudioComponent()
audio.directLevel = -6
audio.reverbLevel = -3
entity.components[SpatialAudioComponent.self] = audio
```

### Hand tracking (direct touch)

Replace `SpatialTapGesture` with `DragGesture` + `PhysicsBodyComponent` for
direct hand interaction (reaching out and touching portals).

---

## File count summary

| File | Lines | Role |
|------|-------|------|
| `TORIX360App.swift` | ~25 | App + ImmersiveSpace registration |
| `ContentView.swift` | ~65 | Launch UI |
| `ImmersiveView.swift` | ~110 | Scene orchestration |
| `InterstitialView.swift` | ~70 | Narrative overlay |
| `WorldViewModel.swift` | ~60 | Reactive state |
| `SphereWorldEntity.swift` | ~85 | Panoramic spheres |
| `PortalEntity.swift` | ~80 | Interactive portals |
| `PortalManager.swift` | ~55 | World graph + colours |
