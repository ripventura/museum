# Museum - visionOS Museum Portal App

A SwiftUI visionOS app that serves as a portal for museum visitors to interact and immerse themselves in 3D assets and environments.

## Project Structure

```
Museum/
├── Museum/                          # App source code
│   ├── MuseumApp.swift              # @main entry point (WindowGroup scene)
│   ├── ContentView.swift            # Main UI view
│   ├── Info.plist                   # Supports multiple scenes
│   └── Assets.xcassets/             # visionOS solid image stack icon
├── MuseumTests/                     # Swift Testing framework tests
│   └── MuseumTests.swift
├── Packages/
│   └── RealityKitContent/           # Local SPM package for 3D assets
│       ├── Package.swift            # Swift 6.2, visionOS 26+
│       └── Sources/RealityKitContent/
│           ├── RealityKitContent.swift          # Bundle.module export
│           └── RealityKitContent.rkassets/      # USDA scenes & materials
└── Museum.xcodeproj/
```

## Build & Run

- **Platform**: visionOS 26.2+ (xros / xrsimulator)
- **Bundle ID**: `com.vitorcesco.Museum`
- **Swift**: 6.2 with `MainActor` default isolation and approachable concurrency enabled
- **Xcode**: 26.2+ required
- Build and run via Xcode targeting visionOS Simulator or device

## Architecture (MVVM Variant)

The app uses a light MVVM architecture with clearly defined layers (top to bottom):

### 1. Views
- SwiftUI views with business logic extracted into view models
- Never cascade multiple `.sheet`, `.alert` or similar modifiers — use a single declaration controlled by a Controller
- Prefer alternatives to event subscribing modifiers (`.onAppear`, `.task`, `.onChange`) — only use when strictly necessary

### 2. View Models
- Synthesizers that compute states from one or more dependencies (engines, managers, controllers)
- Views react to view model state
- Typically have a private `setupBindings()` method called during construction to subscribe to Combine publishers

### 3. Middle Layer
- **Engines**: Specialized classes performing a single specific task. Do not orchestrate results or process errors. May depend on other engines and/or operators.
- **Managers**: Orchestrators that coordinate one or more engines to achieve a goal. Handle error processing.

### 4. Operators (Lowest Level)
- Only depend on other operators or system-level APIs
- Handle resource loading, wrap third-party APIs, etc.

### 5. Controllers
- Reserved for navigation purposes (e.g., controlling navigation stack rendering)
- Sit at the same high level as view models in the hierarchy

### Key Principles
- **Protocol Oriented Programming**: All middle to low level classes must sit behind a protocol
- **Dependency Injection**: Uses [Factory](https://github.com/hmlongco/Factory) library
- DI extensions must be declared at the top of the same file as the class they resolve — not in generic "DI" files
- **Modern async/await** over Combine publishers where available
- **Data propagation** preferred over Combine publishers
- Only public/internal methods on the class body; private methods go in private extensions in the same file

## Dependencies

- **Factory** — Dependency injection
- **RealityKitContent** — Local SPM package containing 3D scene assets (USDA format) and materials

## Testing

- Uses **Swift Testing** framework (not XCTest)
- Lower and middle layer classes must have unit tests on all public interfaces
- Create mocks to simplify DI and control the testing environment
- Consider edge cases when writing tests
- When adding tests to an existing file, check for redundancy/overlap with existing tests — rework both if needed for unified coverage

## Code Style

- Public/internal methods on the class body; private methods in `private extension` blocks at the bottom of the same file
- Prefer async/await over Combine
- Prefer data propagation over publishers
- All protocols and implementations for middle/low layers
- Factory container extensions co-located with their resolved types
