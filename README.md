# Museum

A SwiftUI visionOS app that serves as a portal for museum visitors to interact and immerse themselves in 3D assets and environments.

## Getting Started

### Prerequisites

- **Xcode 26.2+**
- **visionOS 26.2+ SDK**
- **Swift 6.2**

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/vitorcesco/Museum.git
   cd Museum
   ```

2. Open `Museum.xcodeproj` in Xcode. The local `RealityKitContent` SPM package and all other dependencies are resolved automatically.

3. Select a visionOS Simulator or device target, then build and run.

## Architecture

The app follows a layered MVVM variant with clearly separated responsibilities:

```
Views → ViewModels → Managers → Engines → Operators
                  ↘ Controllers (navigation)
```

| Layer | Role |
|---|---|
| **Views** | SwiftUI views. Declare view models as `@ObservedObject`; lifecycle is controlled by Factory scope (`.singleton`, `.shared`, `.unique`). |
| **ViewModels** | `ObservableObject` with `@Published` properties. Expose synchronous methods that spawn internal `Task` for async work. Subscribe to dependencies via a `setupBindings()` method called from `init`. |
| **Managers** | Orchestrators that coordinate multiple engines toward a goal. Handle error processing. |
| **Engines** | Single-task specialists. Do not orchestrate results or process errors. |
| **Operators** | Lowest level. Wrap system APIs and third-party libraries. |
| **Controllers** | Manage navigation state (e.g., immersive space phase). Sit at the same level as view models. |

### Dependency Injection

Uses [Factory](https://github.com/hmlongco/Factory) with the pattern `Container.shared.factoryName()` as default init parameters. Container extensions live at the top of the same file as the class they resolve.

### Directory Layout

```
Museum/
├── Models/          # Value types (enums, structs)
├── Operators/       # System API wrappers
├── Engines/         # Single-task specialists
├── Managers/        # Orchestrators
├── ViewModels/      # ObservableObject view models
├── Views/           # SwiftUI views
├── Controllers/     # Navigation state
├── ContentView.swift
└── MuseumApp.swift
```

## Best Practices

- **Protocol-oriented**: All middle and low-level classes sit behind a protocol.
- **Swift 6.2 MainActor default isolation**: The app target enables default MainActor isolation. Never add explicit `@MainActor` on Views, ViewModels, or their protocols. Use `nonisolated` on lower layers.
- **DI co-location**: Factory container extensions are declared at the top of the same file as the class they resolve.
- **Access control**: Public/internal methods on the class body; private methods in `private extension` blocks at the bottom of the file.
- **Async/await over Combine**: Prefer modern async/await. Use data propagation over publishers where possible.
- **Testing**: Uses Swift Testing (`@Test`, `#expect`). Follow the `makeSUT()` factory pattern in a private extension. Inject mocks via init parameters. The test target does not inherit default MainActor isolation, so tests accessing main-actor-isolated types need explicit `@MainActor`.

## Dependencies

| Package | Purpose |
|---|---|
| [Factory](https://github.com/hmlongco/Factory) | Dependency injection |
| [Equatable](https://github.com/ordo-one/equatable) | `@Equatable` macro for SwiftUI view diffing |
| RealityKitContent | Local SPM package containing 3D scene assets (USDA) and materials |

## Testing

Tests live in the `MuseumTests/` target and use the **Swift Testing** framework. Shared mocks are in `MuseumTests/Mocks/`.

Run tests from Xcode or via the command line:

```bash
xcodebuild test -project Museum.xcodeproj -scheme Museum -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```
