# LiveTextScanner

A real-time OCR scanner for iOS. Point the camera at any text, see it highlighted live, capture it with one tap, and browse your scan history.

---

## Requirements

| Tool | Version |
|---|---|
| Xcode | 26.0 or later |
| iOS deployment target | 26.0 |
| Swift | 6.2 |
| Device | iPhone with a rear camera (simulator cannot use the camera) |

No third-party dependencies — everything uses Apple frameworks only.

---

## Setup

1. **Clone the repo**

   ```bash
   git clone <repo-url>
   cd LiveTextScanner
   ```

2. **Open in Xcode**

   ```bash
   open LiveTextScanner.xcodeproj
   ```

3. **Set a development team**

   Select the `LiveTextScanner` target → Signing & Capabilities → set *Team* to your Apple ID or developer account. The app requires camera access, which mandates a real signing identity.

4. **Add camera usage description** *(if not already present)*

   `Info.plist` must contain `NSCameraUsageDescription`. The project includes this key; if you create a new scheme from scratch, add it manually.

5. **Run on a physical device**

   Select your connected iPhone as the destination and press **Run** (⌘R). The app will request camera permission on first launch.

---

## Running Tests

### Unit tests

The unit test suite runs entirely without hardware — all camera and OCR dependencies are replaced by in-memory mocks.

```bash
xcodebuild test \
  -scheme LiveTextScanner \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or press **⌘U** inside Xcode with the `LiveTextScanner` scheme selected.

Covers:
- `SimilarityDeduplicator` — edit-distance thresholds and stability window
- `LiveScanUseCase` — frame-to-capture pipeline with `MockCameraFrameProvider` + `MockTextRecognizer`
- `CaptureTextUseCase` — snapshot, language derivation, and persistence via `InMemoryStore`
- `ScanHistoryUseCase` — search, filter, and delete saved records

### UI tests

UI tests also run on the Simulator — no physical device or camera needed. The `--uitesting` launch argument replaces `AVCameraSession` and `VisionTextRecognizer` with fast mocks, and swaps SwiftData for an `InMemoryStore`. An optional `--seed-history` argument pre-populates the store with two deterministic scan records for history-screen tests.

```bash
xcodebuild test \
  -scheme LiveTextScannerUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or select the `LiveTextScannerUITests` scheme in Xcode and press **⌘U**.

Covers:
- Camera screen — shutter, settings, and history controls present; shutter disabled when no text detected
- Settings sheet — open/close lifecycle; auto-detect toggle default state; language section visibility
- History (empty) — navigation, empty-state message, search bar, back button
- History (with data) — seeded scans visible, tap to detail, swipe-to-delete, search filter

---

## How to Use

| Action | How |
|---|---|
| Scan | Open the app — the live overlay highlights detected text automatically |
| Capture | Tap the shutter button (enabled only when text is in frame) |
| Copy | In the capture sheet, tap **Copy** |
| Share | In the capture sheet, tap **Share** |
| History | Tap the clock icon (top-right) to browse and search past scans |
| Delete a scan | Swipe left on any row in History |
| Change language settings | Tap the gear icon (top-right on the camera screen) |

---

## Architecture

The project follows a strict layered architecture. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full breakdown. In brief:

```
Presentation  →  Domain (Use Cases + Models)  →  Data / Infrastructure
```

- **Infrastructure** — the only layer that touches hardware (`AVCameraSession`, `VisionTextRecognizer`)
- **Domain** — pure Swift, no framework imports; all OCR and camera access is behind protocols
- **Data** — SwiftData persistence via `ScanRecord`
- **Presentation** — SwiftUI views backed by `@Observable @MainActor` view models

Swapping the OCR engine (e.g. for Google ML Kit) requires implementing one protocol (`TextRecognitionProtocol`) with no changes elsewhere.

---

## Assumptions

### Device & OS
- The app targets iOS 26 and is not designed to run on earlier releases. SwiftData, `@Observable`, `AsyncStream.makeStream()`, and several SwiftUI APIs used here require iOS 17+ at minimum; some APIs are iOS 26-specific.
- A physical device is required for the camera. The Xcode Simulator cannot provide a live camera feed, so `AVCameraSession` will not function there. The rest of the app (History, capture sheet) works in the simulator.

### Camera permission
- The user grants camera access when prompted. There is no secondary in-app explanation screen; iOS's standard permission dialog is considered sufficient for a developer/prototype tool.

### OCR quality
- Vision's `VNRecognizeTextRequest` runs at `.accurate` level with `usesLanguageCorrection = true`. Recognition quality depends on lighting and print quality — handwriting works but with lower accuracy than printed text.
- Language detection defaults to **auto-detect** (`automaticallyDetectsLanguage = true`). The user can switch to a fixed list of languages in Settings, which may improve accuracy on known-language documents.
- Each recognized text observation is also run through `NLLanguageRecognizer` to attach a per-region BCP-47 tag independently of the Vision language hint. This is what surfaces detected languages in the capture sheet and history rows, and is what makes mixed-language document attribution work.

### Deduplication
- A text block must appear in **3 or more consecutive frames** before being considered stable and yielded as a capture. This prevents single-frame noise from becoming captures.
- Two blocks are treated as duplicates when their normalized edit-distance similarity is **≥ 90%**. The threshold deliberately favors distinctness — near-identical but slightly different strings are kept separate rather than merged.

### Persistence
- Scans are saved to a local SwiftData store. There is no iCloud sync or CloudKit integration. Data lives on-device only and is lost if the app is deleted.
- No authentication or per-user isolation is implemented; the app is designed for single-user personal use.

### Live overlay vs. captures
- The green bounding-box overlay reflects **raw per-frame OCR output** and updates every frame, including clearing when no text is visible. This is intentionally separate from the saved capture, which uses the deduplication pipeline.
- The shutter button captures a snapshot of whatever Vision sees in the current frame, not a deduplicated stable result — so a quick tap on noisy frames may include transient detections.

### Language settings
- Language preferences are stored in `UserDefaults` and survive app restarts.
- Changing the language setting takes effect on the next camera frame — the scan session does not restart.
- In auto-detect mode (the default), Vision selects the recognition model per frame. In manual mode, only the languages the user selected are attempted; if no languages are selected, Vision falls back to English.
- The list of available languages is queried from Vision at runtime via `VNRecognizeTextRequest.supportedRecognitionLanguages()` and reflects whatever is installed on the device.

### No secrets or API keys
- All processing is on-device. No network requests are made and no API keys are required.
