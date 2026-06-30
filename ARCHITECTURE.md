# LiveTextScanner — Architecture Plan

## Tech Stack

| Concern | Choice | Why |
|---|---|---|
| UI | SwiftUI (iOS 26) | Native, declarative, Liquid Glass effects |
| State | `@Observable` + `@State` | Modern replacement for `ObservableObject` |
| Camera | AVFoundation | `AVCaptureSession` + sample buffer delegate |
| OCR | Vision (`VNRecognizeTextRequest`) | On-device, fast, multi-language, replaceable via protocol |
| Per-region language | NaturalLanguage (`NLLanguageRecognizer`) | Tags each text observation with a BCP-47 code independently of Vision's hint list |
| Persistence | SwiftData | iOS 17+ native, replaces Core Data |
| Concurrency | Swift Concurrency (`async/await`, `Actor`) | No GCD, no Combine |

---

## Project Layer Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│                                                              │
│  ContentView (NavigationStack)                               │
│      │                                                       │
│  CameraView          HistoryView         CaptureResultView   │
│      │                   │                   │               │
│  CameraViewModel    HistoryViewModel   CaptureViewModel      │
│      │                   │                   │               │
└──────┼───────────────────┼───────────────────┼──────────────┘
       │                   │                   │
┌──────▼───────────────────▼───────────────────▼──────────────┐
│                       DOMAIN LAYER                           │
│                                                              │
│  ┌─────────────────────────────────────┐                     │
│  │           Use Cases                 │                     │
│  │  LiveScanUseCase                    │                     │
│  │  CaptureTextUseCase                 │                     │
│  │  ScanHistoryUseCase                 │                     │
│  └──────────────┬──────────────────────┘                     │
│                 │                                            │
│  ┌──────────────▼──────────────────────┐                     │
│  │        Domain Models                │                     │
│  │  TextRegion  ScanCapture ScanRecord │                     │
│  └─────────────────────────────────────┘                     │
│                                                              │
│  ┌─────────────────────────────────────┐                     │
│  │     Protocols (Ports)               │                     │
│  │  TextRecognitionProtocol  ◄── key   │                     │
│  │  CameraFrameProviderProtocol        │                     │
│  │  ScanRepositoryProtocol             │                     │
│  │  DeduplicationStrategy              │                     │
│  └─────────────────────────────────────┘                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
       │                                    │
┌──────▼────────────────┐   ┌──────────────▼──────────────────┐
│     DATA LAYER        │   │       INFRASTRUCTURE LAYER       │
│                       │   │                                  │
│  ScanRepository       │   │  AVCameraSession                 │
│  SwiftDataStore       │   │  VisionTextRecognizer            │
│  InMemoryStore        │   │  MockTextRecognizer ◄── tests   │
│                       │   │  MockCameraFrameProvider         │
└───────────────────────┘   └──────────────────────────────────┘
```

---

## Layer-by-Layer Breakdown

### 1. Infrastructure Layer — Hardware Adapters

These are the only files that touch real hardware. Everything else talks to protocols.

```
Infrastructure/
├── Camera/
│   ├── AVCameraSession.swift           ← AVCaptureSession, outputs CMSampleBuffers
│   └── MockCameraFrameProvider.swift   ← emits synthetic pixel buffers; used in previews and tests
└── Recognition/
    ├── VisionTextRecognizer.swift      ← wraps VNRecognizeTextRequest + NLLanguageRecognizer
    └── MockTextRecognizer.swift        ← returns configurable fake regions; no hardware needed
```

**Key design:** `AVCameraSession` is an `Actor` — all camera state is protected.
`VisionTextRecognizer` conforms to `TextRecognitionProtocol` so it can be swapped for Google ML Kit, Tesseract, etc. with zero domain changes. It runs `NLLanguageRecognizer` on each recognized string to populate `TextRegion.detectedLanguage` — Vision tells you what languages to *try*; NaturalLanguage tells you what language a string *is*, which is what makes mixed-language documents work.

---

### 2. Domain Layer — Pure Business Logic

No imports of AVFoundation or Vision in this layer.

```
Domain/
├── Models/
│   ├── TextRegion.swift      ← bounding box + string + detectedLanguage for one observation
│   ├── ScanCapture.swift     ← a single frame's worth of recognized text; exposes detectedLanguages sorted by frequency
│   └── ScanRecord.swift      ← a saved scan (SwiftData @Model)
│
├── Protocols/
│   ├── TextRecognitionProtocol.swift       ← AsyncStream<[TextRegion]>
│   ├── CameraFrameProviderProtocol.swift   ← AsyncStream<CVPixelBuffer>
│   ├── ScanRepositoryProtocol.swift        ← save / fetch / delete / search
│   └── DeduplicationStrategy.swift        ← protocol for dedup strategies
│
├── UseCases/
│   ├── LiveScanUseCase.swift       ← drives camera → OCR → dedup pipeline
│   ├── CaptureTextUseCase.swift    ← snapshot current frame, write to repo
│   └── ScanHistoryUseCase.swift    ← search, filter, delete history
│
└── Deduplication/
    └── SimilarityDeduplicator.swift  ← rolling window, edit-distance threshold
```

**Deduplication strategy** (spec: favor avoiding merges over aggressive collapsing):
- Maintain a rolling buffer of the last N frames' text blocks
- Normalize each block (trim, lowercase, collapse whitespace)
- Use normalized edit distance — only mark as duplicate if similarity >= 90%
- A new distinct string always passes through, even if close to a prior one
- Text must appear in >= 3 consecutive frames before being considered "stable"

---

### 3. Data Layer — Persistence

```
Data/
├── Repositories/
│   └── ScanRepository.swift    ← implements ScanRepositoryProtocol
└── Persistence/
    ├── SwiftDataStore.swift    ← @Model container, real persistence
    └── InMemoryStore.swift     ← for unit tests, no disk I/O
```

**ScanRecord (@Model):**
```swift
@Model final class ScanRecord {
    var id: UUID
    var number: Int              // sequential capture number, shown in the UI
    var date: Date
    var text: String
    var thumbnailData: Data?
    var detectedLanguages: [String]  // BCP-47 tags sorted by frequency, e.g. ["fr", "en"]
    var sourceRegions: [String]      // raw per-line strings pre-dedup
}
```

---

### 4. Presentation Layer — SwiftUI + @Observable ViewModels

```
Presentation/
├── Camera/
│   ├── CameraView.swift            ← live preview + overlay + controls
│   ├── CameraViewModel.swift       ← @Observable @MainActor; owns liveRegions + currentCapture
│   ├── TextOverlayView.swift       ← Canvas drawing glowing bounding boxes over detected text
│   ├── CameraPreviewView.swift     ← UIViewRepresentable wrapping AVCaptureVideoPreviewLayer
│   ├── ScanStatusBadge.swift       ← top-left glass pill showing detection count / scanning state
│   ├── ShutterButton.swift         ← styled capture button; disabled + dimmed when no text in frame
│   └── GlassStyles.swift           ← glassPill() and glassCircle() View extensions (iOS 26 glass effect)
│
├── Capture/
│   ├── CaptureResultView.swift     ← sheet: captured text, copy button, share sheet
│   └── CaptureViewModel.swift      ← @Observable @MainActor
│
├── History/
│   ├── HistoryView.swift           ← list + search bar
│   ├── HistoryViewModel.swift      ← @Observable @MainActor
│   ├── ScanDetailView.swift        ← full text of a saved scan
│   └── ScanRowView.swift           ← list row: number badge, text preview, timestamp, dominant language
│
├── Settings/
│   ├── SettingsView.swift          ← language auto-detect toggle; opens LanguagePickerView when off
│   └── LanguagePickerView.swift    ← checklist of all Vision-supported BCP-47 languages
│
└── Components/                     ← reusable UI primitives shared across features
    ├── ToastContent.swift          ← Identifiable struct: message + SF Symbol name
    ├── ToastModifier.swift         ← ViewModifier + View.toast(_:) convenience extension
    └── ToastView.swift             ← capsule label; auto-dismissed after 2 s via task(id:)
```

All ViewModels are `@Observable @MainActor`. No `ObservableObject`, no `@Published`.
Views use `@State` for ownership and `@Bindable` for passing bindings.

The `Components/` group holds UI primitives with no feature-specific logic so they can be reused across `Camera`, `Capture`, and `History` screens without creating cross-feature dependencies.

---

### 5. App / DI Root

```
ContentView.swift                     ← root NavigationStack; routes AppRoute values to destination views
App/
├── LiveTextScannerApp.swift          ← @main, ModelContainer setup
├── AppDependencyContainer.swift      ← wires real vs. mock dependencies; observes LanguageSettings and pushes changes to VisionTextRecognizer
├── AppRoute.swift                    ← Hashable enum used with navigationDestination(for:)
└── LanguageSettings.swift            ← @Observable @MainActor; persists autoDetect + selectedLanguages via UserDefaults
```

Dependencies are injected via `@Environment` — no singletons.
`AppRoute` is the single source of truth for all push-navigation destinations; adding a new screen means adding a case here and a branch in `ContentView`.

`AppDependencyContainer` uses `withObservationTracking` in a recursive pattern to watch `LanguageSettings` and push `activeLanguages` to `VisionTextRecognizer.recognitionLanguages` on every change, without restarting the scan session. The Settings sheet opens directly from `CameraView` rather than going through `AppRoute` because it is a transient configuration overlay, not a navigation destination.

---

### 6. UI Test Target — `LiveTextScannerUITests`

UI tests run against the real app binary with all hardware replaced by fast, deterministic mocks.

**Isolation via launch arguments**

`AppDependencyContainer.init()` checks `ProcessInfo.processInfo.arguments` at startup:

| Argument | Effect |
|---|---|
| `--uitesting` | Replaces `AVCameraSession` with `MockCameraFrameProvider`, `VisionTextRecognizer` with `MockTextRecognizer`, and `SwiftDataStore` with `InMemoryStore`. Resets `UserDefaults` language keys so every test starts from the same default state. |
| `--seed-history` | (Requires `--uitesting`) Calls `InMemoryStore.seedForUITesting()` synchronously, inserting two deterministic `ScanRecord`s ("Hello World from UI test" in English, "Bonjour le monde" in French). |

This means UI tests can run on the iOS Simulator with no camera and no on-disk database, yet exercise real navigation, real SwiftUI state transitions, and real `XCUIElement` interactions.

**Test files**

```
LiveTextScannerUITests/
├── UITestHelpers.swift        ← XCUIApplication.uitestingApp(seedHistory:) factory; waitFor(_:) helper
├── CameraScreenUITests.swift  ← controls presence; shutter disabled when MockTextRecognizer returns no regions
├── SettingsUITests.swift      ← sheet open/close; auto-detect toggle default; language section show/hide
└── HistoryUITests.swift
    ├── HistoryEmptyUITests    ← reachable; empty-state text; search bar; back navigation
    └── HistoryWithDataUITests ← seeded scans visible; tap → detail; swipe-delete; search filter
```

**Running UI tests**

```bash
xcodebuild test \
  -scheme LiveTextScannerUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or select the `LiveTextScannerUITests` scheme in Xcode and press **⌘U**.

---

## Full File Tree

```
LiveTextScanner/
├── ContentView.swift                   ← root NavigationStack, wires routes to views
├── App/
│   ├── LiveTextScannerApp.swift        ← @main, ModelContainer setup
│   ├── AppDependencyContainer.swift    ← wires real vs. mock dependencies; observes LanguageSettings → pushes to recognizer
│   ├── AppRoute.swift                  ← Hashable enum of NavigationStack destinations
│   └── LanguageSettings.swift          ← @Observable user language prefs, persisted via UserDefaults
│
├── Domain/
│   ├── Models/
│   │   ├── TextRegion.swift
│   │   ├── ScanCapture.swift
│   │   └── ScanRecord.swift
│   ├── Protocols/
│   │   ├── TextRecognitionProtocol.swift
│   │   ├── CameraFrameProviderProtocol.swift
│   │   ├── ScanRepositoryProtocol.swift
│   │   └── DeduplicationStrategy.swift
│   ├── UseCases/
│   │   ├── LiveScanUseCase.swift
│   │   ├── CaptureTextUseCase.swift
│   │   └── ScanHistoryUseCase.swift
│   └── Deduplication/
│       └── SimilarityDeduplicator.swift
│
├── Data/
│   ├── Repositories/
│   │   └── ScanRepository.swift
│   └── Persistence/
│       ├── SwiftDataStore.swift
│       └── InMemoryStore.swift
│
├── Infrastructure/
│   ├── Camera/
│   │   ├── AVCameraSession.swift
│   │   └── MockCameraFrameProvider.swift   ← fake frame source for previews & tests
│   └── Recognition/
│       ├── VisionTextRecognizer.swift
│       └── MockTextRecognizer.swift
│
├── Presentation/
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   ├── CameraViewModel.swift
│   │   ├── TextOverlayView.swift           ← Canvas-based bounding-box overlay
│   │   ├── CameraPreviewView.swift         ← UIViewRepresentable wrapping AVCaptureVideoPreviewLayer
│   │   ├── ScanStatusBadge.swift           ← live detection-count pill (top-left)
│   │   ├── ShutterButton.swift             ← camera-style capture button with press animation
│   │   └── GlassStyles.swift               ← View extensions: glassPill(), glassCircle()
│   ├── Capture/
│   │   ├── CaptureResultView.swift
│   │   └── CaptureViewModel.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift
│   │   ├── ScanDetailView.swift
│   │   └── ScanRowView.swift               ← list row with number badge and timestamp
│   ├── Settings/
│   │   ├── SettingsView.swift              ← language auto-detect toggle + language picker sheet
│   │   └── LanguagePickerView.swift        ← scrollable checklist of Vision-supported BCP-47 languages
│   └── Components/
│       ├── ToastContent.swift              ← Identifiable payload (message + SF Symbol)
│       ├── ToastModifier.swift             ← ViewModifier + View.toast() extension
│       └── ToastView.swift                 ← capsule label with auto-dismiss via task(id:)
│
├── LiveTextScannerTests/
│   ├── TestHelpers.swift                   ← shared factories and fixture builders
│   ├── DeduplicationTests.swift
│   ├── LiveScanUseCaseTests.swift
│   ├── CaptureTextUseCaseTests.swift
│   └── ScanHistoryUseCaseTests.swift
│
└── LiveTextScannerUITests/
    ├── UITestHelpers.swift                 ← XCUIApplication extension: uitestingApp(seedHistory:) factory + waitFor helper
    ├── CameraScreenUITests.swift           ← shutter / settings / history buttons; shutter disabled when no text
    ├── SettingsUITests.swift               ← settings sheet lifecycle; auto-detect toggle; language section visibility
    └── HistoryUITests.swift                ← empty-state, seeded scans, tap to detail, swipe-delete, search filter
```

---

## Key Engineering Decisions

| Requirement | Solution |
|---|---|
| OCR engine must be replaceable | `TextRecognitionProtocol` — Vision is one conforming type |
| Testable without camera | `MockTextRecognizer` + `MockCameraFrameProvider` inject fake data |
| Dedup: favor distinct over merged | Edit-distance >= 90% threshold + 3-frame stability window |
| No mutable shared state races | All ViewModels `@MainActor`; camera work in `Actor` |
| History search | SwiftData `#Predicate` on `ScanRecord.text` + `date` |
| Share sheet | `ShareLink` (native SwiftUI, no UIKit needed) |
| Copy to clipboard | `UIPasteboard.general.string` inside a `.toolbar` button |
| Per-region language tag | `NLLanguageRecognizer` run on each Vision observation — Vision picks the recognition *model*, NaturalLanguage identifies the *result* |
| Mixed-language documents | Each `TextRegion` carries its own `detectedLanguage`; `ScanCapture.detectedLanguages` aggregates them by frequency |
| Live language preference updates | `withObservationTracking` loop in `AppDependencyContainer` pushes to recognizer without stopping the camera |
| Language prefs survive relaunch | `LanguageSettings` writes to `UserDefaults` via `didSet` on every change |

---

## Functional Requirements Coverage

| Requirement | Covered By |
|---|---|
| Live camera preview | `AVCameraSession` + `CameraView` |
| Highlight detected text regions | `TextOverlayView` draws bounding boxes per frame |
| Overlay clears when no text visible | `LiveScanUseCase` emits empty regions every frame; `CameraViewModel.currentRegions` clears immediately |
| Capture text from current frame | `CaptureTextUseCase` |
| Copy to clipboard | `CaptureResultView` toolbar button |
| Share via system sheet | `ShareLink` in `CaptureResultView` |
| Deduplication across frames | `SimilarityDeduplicator` in `LiveScanUseCase` |
| Persist scans across launches | SwiftData `ScanRecord` |
| List saved scans | `HistoryView` + `HistoryViewModel` |
| Search and filter scans | SwiftData `#Predicate` + search bar |
| Delete scans | `ScanHistoryUseCase.delete()` + swipe-to-delete |
| Multi-language recognition | `VNRecognizeTextRequest.automaticallyDetectsLanguage` + per-region `NLLanguageRecognizer` |
| Mixed-language documents | Each `TextRegion` tagged independently; `ScanCapture.detectedLanguages` aggregates by frequency |
| User language configuration | `SettingsView` (auto-detect toggle) + `LanguagePickerView` (per-language checklist) |
| Language persists across launches | `LanguageSettings` writes to `UserDefaults`; read back on init |
| Detected languages shown on capture | `DetectedLanguagesRow` in `CaptureResultView` |
| Detected language shown in history | Dominant language in `ScanRowView` timestamp row |
| Unit testable business logic | All use cases + deduplicator have no hardware dependencies |
| Testable without camera | `MockTextRecognizer` + `MockCameraFrameProvider` |
| UI-testable without hardware | `--uitesting` launch arg wires mocks + `InMemoryStore`; `--seed-history` pre-populates scan list |
