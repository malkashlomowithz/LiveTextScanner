# LiveTextScanner — Architecture Plan

## Tech Stack

| Concern | Choice | Why |
|---|---|---|
| UI | SwiftUI (iOS 17+) | Native, declarative, no UIKit needed |
| State | `@Observable` + `@State` | Modern replacement for `ObservableObject` |
| Camera | AVFoundation | `AVCaptureSession` + sample buffer delegate |
| OCR | Vision (`VNRecognizeTextRequest`) | On-device, fast, multi-language, replaceable via protocol |
| Persistence | SwiftData | iOS 17+ native, replaces Core Data |
| Concurrency | Swift Concurrency (`async/await`, `Actor`) | No GCD, no Combine |

---

## Project Layer Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│                                                              │
│  CameraView          HistoryView         SettingsView        │
│      │                   │                   │  (optional)   │
│  CameraViewModel    HistoryViewModel   LanguageViewModel     │
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
│   └── AVCameraSession.swift       ← AVCaptureSession, outputs CMSampleBuffers
└── Recognition/
    ├── VisionTextRecognizer.swift  ← wraps VNRecognizeTextRequest
    └── MockTextRecognizer.swift    ← feeds fake frames, no hardware needed
```

**Key design:** `AVCameraSession` is an `Actor` — all camera state is protected.
`VisionTextRecognizer` conforms to `TextRecognitionProtocol` so it can be swapped
for Google ML Kit, Tesseract, etc. with zero domain changes.

---

### 2. Domain Layer — Pure Business Logic

No imports of AVFoundation or Vision in this layer.

```
Domain/
├── Models/
│   ├── TextRegion.swift      ← bounding box + string for one detected word/line
│   ├── ScanCapture.swift     ← a single frame's worth of recognized text
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
    var date: Date
    var text: String
    var thumbnailData: Data?
    var language: String?        // BCP-47 tag, e.g. "en", "fr"
    var sourceRegions: [String]  // raw per-line strings pre-dedup
}
```

---

### 4. Presentation Layer — SwiftUI + @Observable ViewModels

```
Presentation/
├── Camera/
│   ├── CameraView.swift          ← live preview + text bounding-box overlay
│   ├── TextOverlayView.swift     ← draws highlighted rectangles over detected text
│   └── CameraViewModel.swift     ← @Observable @MainActor
│
├── Capture/
│   ├── CaptureResultView.swift   ← sheet: shows captured text, copy, share
│   └── CaptureViewModel.swift    ← @Observable @MainActor
│
├── History/
│   ├── HistoryView.swift         ← list + search bar + filter chips
│   ├── ScanDetailView.swift      ← full text of a saved scan
│   └── HistoryViewModel.swift    ← @Observable @MainActor, uses @Query
│
└── Settings/                     ← optional
    ├── SettingsView.swift
    └── LanguagePickerView.swift
```

All ViewModels are `@Observable @MainActor`. No `ObservableObject`, no `@Published`.
Views use `@State` for ownership and `@Bindable` for passing bindings.

---

### 5. App / DI Root

```
App/
├── LiveTextScannerApp.swift          ← @main, ModelContainer setup
└── AppDependencyContainer.swift      ← wires real vs. mock dependencies
```

Dependencies are injected via `@Environment` — no singletons.

---

## Full File Tree

```
LiveTextScanner/
├── App/
│   ├── LiveTextScannerApp.swift
│   └── AppDependencyContainer.swift
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
│   │   └── AVCameraSession.swift
│   └── Recognition/
│       ├── VisionTextRecognizer.swift
│       └── MockTextRecognizer.swift
│
├── Presentation/
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   ├── TextOverlayView.swift
│   │   └── CameraViewModel.swift
│   ├── Capture/
│   │   ├── CaptureResultView.swift
│   │   └── CaptureViewModel.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── ScanDetailView.swift
│   │   └── HistoryViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── LanguagePickerView.swift
│
└── LiveTextScannerTests/
    ├── DeduplicationTests.swift
    ├── LiveScanUseCaseTests.swift
    ├── CaptureTextUseCaseTests.swift
    └── ScanHistoryUseCaseTests.swift
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

---

## Functional Requirements Coverage

| Requirement | Covered By |
|---|---|
| Live camera preview | `AVCameraSession` + `CameraView` |
| Highlight detected text regions | `TextOverlayView` draws bounding boxes |
| Capture text from current frame | `CaptureTextUseCase` |
| Copy to clipboard | `CaptureResultView` toolbar button |
| Share via system sheet | `ShareLink` in `CaptureResultView` |
| Deduplication across frames | `SimilarityDeduplicator` in `LiveScanUseCase` |
| Persist scans across launches | SwiftData `ScanRecord` |
| List saved scans | `HistoryView` + `HistoryViewModel` |
| Search and filter scans | SwiftData `#Predicate` + search bar |
| Delete scans | `ScanHistoryUseCase.delete()` + swipe-to-delete |
| Multi-language recognition | `VNRecognizeTextRequest.recognitionLanguages` |
| Language configuration | `SettingsView` + `LanguagePickerView` |
| Unit testable business logic | All use cases + deduplicator have no hardware dependencies |
| Testable without camera | `MockTextRecognizer` + `MockCameraFrameProvider` |
