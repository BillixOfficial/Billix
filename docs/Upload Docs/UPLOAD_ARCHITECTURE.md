# Upload Feature Architecture

## Overview

The Upload feature uses a **Protocol-Oriented Dependency Injection** architecture that enables easy switching between mock and real API implementations. This is an industry best practice used by companies like Airbnb, Uber, and follows Apple's recommended patterns.

---

## Architecture Layers

```
┌─────────────────────────────────────────┐
│           Views (SwiftUI)               │
│  - UploadHubView                        │
│  - QuickAddFlowView                     │
│  - ScanUploadFlowView                   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│        ViewModels (@MainActor)          │
│  - UploadViewModel                      │
│  - QuickAddViewModel                    │
│  - ScanUploadViewModel                  │
└─────────────┬───────────────────────────┘
              │ Depends on Protocol
              ▼
┌─────────────────────────────────────────┐
│   BillUploadServiceProtocol             │
│   (Interface - defines operations)      │
└──────────┬──────────────┬───────────────┘
           │              │
           ▼              ▼
  ┌────────────────┐  ┌────────────────┐
  │  MockService   │  │  RealService   │
  │ (Mock Data)    │  │ (Real API)     │
  └────────────────┘  └────────────────┘
           │              │
           └──────┬───────┘
                  │ Created by
                  ▼
        ┌──────────────────────┐
        │   Service Factory    │
        │ (Environment-based)  │
        └──────────────────────┘
```

---

## Key Components

### 1. Protocol Definition

**File:** `BillUploadServiceProtocol.swift`

Defines all upload operations:
- `getBillTypes()` - Fetch bill types
- `getProviders(zipCode:billType:)` - Fetch providers
- `submitQuickAdd(request:)` - Submit quick add
- `uploadAndAnalyzeBill(fileData:fileName:source:)` - Upload bill
- `getRecentUploads()` - Fetch history
- `getUploadStatus(uploadId:)` - Check status

**Benefits:**
- Type-safe contract
- Easy to mock
- Compile-time verification
- Enables dependency injection

### 2. Mock Implementation

**File:** `MockBillUploadService.swift`

Features:
- Realistic mock data
- Simulated network delays
- No backend required
- Perfect for development

**Usage:**
```swift
let mockService = MockBillUploadService(mockDelay: 2.0, shouldSucceed: true)
let viewModel = UploadViewModel(uploadService: mockService)
```

### 3. Real Implementation

**File:** `RealBillUploadService.swift`

Features:
- Full API integration (currently stubbed)
- Multipart form-data for uploads
- Bearer token authentication
- Comprehensive error handling

**Integration:**
1. Uncomment real API code
2. Remove mock returns
3. Test in staging
4. Deploy

### 4. Service Factory

**File:** `BillUploadServiceFactory.swift`

Environment-based service creation:

```swift
enum AppEnvironment {
    case development  // Mock
    case staging      // Real API (test)
    case production   // Real API (prod)
}
```

**Switch environments:**
```swift
// In BillUploadServiceFactory.swift
static var current: AppEnvironment {
    #if DEBUG
    return .development  // ← Change to .staging to test API
    #else
    return .production
    #endif
}
```

---

## Data Flow

### Quick Add Flow

```
User → QuickAddStep1 → Select Bill Type
         ↓
QuickAddViewModel.selectBillType()
         ↓
QuickAddStep2 → Enter ZIP → Load Providers
         ↓
uploadService.getProviders(zipCode, billType)
         ↓
Mock: Returns static data
Real: GET /providers?zipCode=...&billTypeId=...
         ↓
QuickAddStep3 → Enter Amount → Submit
         ↓
uploadService.submitQuickAdd(request)
         ↓
Mock: Calculates mock result
Real: POST /quick-add
         ↓
QuickAddStep4 → Display Result
```

### Scan/Upload Flow

```
User → ScanUploadOptions → Select Source
         ↓
ScanUploadViewModel.uploadBill(fileData, fileName, source)
         ↓
uploadService.uploadAndAnalyzeBill(...)
         ↓
Mock: Simulates delay, returns mock analysis
Real: POST /bills/upload (multipart/form-data)
         ↓
Save to SwiftData (StoredBill)
         ↓
ScanUploadResult → Display Analysis
```

---

## ViewModels

### UploadViewModel (Main Coordinator)

**Responsibilities:**
- Coordinate overall upload hub
- Manage recent uploads
- Handle navigation between flows

**Key Methods:**
- `loadRecentUploads()` - Load history
- `startQuickAdd()` - Show Quick Add
- `startScanUpload()` - Show Scan/Upload

### QuickAddViewModel (4-Step Flow)

**Responsibilities:**
- Manage Quick Add wizard state
- Validate inputs
- Submit quick add request

**Step State Machine:**
```
billType → provider → amount → result
```

**Key Properties:**
- `currentStep: Step` - Current wizard step
- `selectedBillType: BillType?` - User selection
- `zipCode: String` - User input
- `amount: String` - Bill amount
- `result: QuickAddResult?` - Comparison result

### ScanUploadViewModel (Upload & Analysis)

**Responsibilities:**
- Manage file upload
- Track progress
- Handle analysis results

**State Machine:**
```
idle → selecting → uploading → analyzing → success/error
```

**Key Properties:**
- `uploadState: UploadState` - Current state
- `progress: Double` - 0.0 to 1.0
- `statusMessage: String` - User feedback

---

## Models

### Quick Add Models

**BillType:**
```swift
struct BillType {
    let id: String
    let name: String
    let icon: String
    let category: String
}
```

**Provider:**
```swift
struct Provider {
    let id: String
    let name: String
    let logoName: String
    let serviceArea: String
}
```

**QuickAddResult:**
```swift
struct QuickAddResult {
    let amount: Double
    let areaAverage: Double
    let percentDifference: Double
    let status: Status  // overpaying/underpaying/average
    let potentialSavings: Double?
    let message: String
}
```

### Upload Models

**UploadSource:**
```swift
enum UploadSource {
    case quickAdd
    case camera
    case photos
    case documentScanner
    case documentPicker
}
```

**UploadStatus:**
```swift
enum UploadStatus {
    case processing
    case analyzed
    case needsConfirmation
    case failed
}
```

**RecentUpload:**
```swift
struct RecentUpload {
    let id: UUID
    let provider: String
    let amount: Double
    let source: UploadSource
    let status: UploadStatus
    let uploadDate: Date
}
```

### Bill Analysis (Shared Model)

**BillAnalysis:**
```swift
struct BillAnalysis {
    let provider: String
    let amount: Double
    let billDate: String
    let dueDate: String
    let category: String
    let zipCode: String
    let keyFacts: [KeyFact]
    let lineItems: [LineItem]
    let insights: [Insight]
    let marketplaceComparison: MarketplaceComparison
}
```

---

## Testing Strategy

### Unit Tests (Recommended)

```swift
import XCTest
@testable import Billix

class UploadViewModelTests: XCTestCase {
    @MainActor
    func testQuickAddSuccess() async {
        // Arrange
        let mockService = MockBillUploadService(mockDelay: 0.1)
        let viewModel = QuickAddViewModel(uploadService: mockService)

        // Act
        await viewModel.loadBillTypes()

        // Assert
        XCTAssertFalse(viewModel.billTypes.isEmpty)
    }
}
```

### SwiftUI Previews

```swift
#Preview {
    let mockService = MockBillUploadService(mockDelay: 1.0)
    let viewModel = UploadViewModel(uploadService: mockService)
    return UploadHubView()
        .environmentObject(viewModel)
}
```

---

## SwiftData Integration

### StoredBill Model

```swift
@Model
class StoredBill {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var uploadDate: Date
    var analysisData: Data?  // JSON-encoded BillAnalysis

    var analysis: BillAnalysis? {
        // Decode from analysisData
    }
}
```

### Usage

```swift
// Save bill
let storedBill = StoredBill(
    fileName: fileName,
    uploadDate: Date(),
    analysisData: try? JSONEncoder().encode(analysis)
)
modelContext.insert(storedBill)
try modelContext.save()

// Query bills
@Query var bills: [StoredBill]
```

---

## Error Handling

### UploadError Enum

```swift
enum UploadError: LocalizedError {
    case validationFailed(String)
    case uploadFailed(String)
    case networkError(String)
    case unauthorized
    case serverError(String)
    case invalidURL
    case invalidResponse
}
```

### Client-Side Validation

Before uploading:
- Min file size: 100 bytes
- Max file size: 10 MB
- Allowed extensions: pdf, jpg, jpeg, png, heic
- ZIP code format: 5 digits

### Server-Side Errors

Handled in RealBillUploadService:
- `200` - Success
- `400` - Validation error
- `401` - Unauthorized
- `413` - File too large
- `500` - Server error

---

## Performance Considerations

### Async/Await

All network operations use Swift's async/await:
```swift
func uploadBill() async {
    do {
        let analysis = try await uploadService.uploadAndAnalyzeBill(...)
    } catch {
        // Handle error
    }
}
```

### Progress Tracking

Upload progress is simulated in mock, real in production:
```swift
for i in 1...3 {
    try await Task.sleep(nanoseconds: 300_000_000)
    progress = 0.2 + (Double(i) * 0.2)
}
```

### Memory Management

Large files are handled efficiently:
- JPEG compression: 0.8 quality
- SwiftData stores JSON, not raw images
- Thumbnails can be generated on-demand

---

## Adding New Upload Methods

Want to add email or SMS upload? Here's how:

### 1. Add to UploadSource

```swift
enum UploadSource {
    case quickAdd
    case camera
    case photos
    case email      // ← Add
    case sms        // ← Add
}
```

### 2. Update Protocol (if needed)

```swift
protocol BillUploadServiceProtocol {
    func submitEmailBill(emailData: Data) async throws -> BillAnalysis
}
```

### 3. Implement in Services

```swift
// MockBillUploadService
func submitEmailBill(emailData: Data) async throws -> BillAnalysis {
    return MockUploadDataService.generateMockBillAnalysis(...)
}

// RealBillUploadService
func submitEmailBill(emailData: Data) async throws -> BillAnalysis {
    // POST /bills/email
}
```

### 4. Add UI Component

Create new view in `Views/Components/` or update existing flows.

---

## File Structure

```
Billix/
├── Services/
│   └── Upload/
│       ├── BillUploadServiceProtocol.swift    (Interface)
│       ├── MockBillUploadService.swift        (Mock impl)
│       ├── RealBillUploadService.swift        (Real impl)
│       ├── BillUploadServiceFactory.swift     (Factory)
│       └── MockUploadDataService.swift        (Static data)
├── Models/
│   └── Upload/
│       ├── QuickAddModels.swift               (BillType, Provider, etc)
│       └── UploadModels.swift                 (UploadSource, Status, etc)
├── Features/
│   └── Upload/
│       ├── ViewModels/
│       │   ├── UploadViewModel.swift
│       │   ├── QuickAddViewModel.swift
│       │   └── ScanUploadViewModel.swift
│       └── Views/
│           ├── UploadHubView.swift            (Main screen)
│           ├── QuickAdd/                       (4 step views)
│           ├── ScanUpload/                     (3 upload views)
│           └── Components/                     (Reusable UI)
└── docs/
    ├── API_INTEGRATION_GUIDE.md               (This file's companion)
    └── UPLOAD_ARCHITECTURE.md                 (This file)
```

---

## Best Practices

### ✅ DO

- Use dependency injection for testability
- Keep ViewModels @MainActor for UI updates
- Use async/await for network operations
- Validate on client before sending to server
- Handle all error cases gracefully
- Provide loading states and progress feedback
- Use SwiftData for local persistence

### ❌ DON'T

- Hardcode API URLs in views
- Make network calls directly from views
- Skip error handling
- Forget to update progress indicators
- Mix mock and real data
- Commit sensitive data (tokens, keys)

---

## Migration Path

### Current State: Mock Only
✅ Development with mock data
✅ No backend required
✅ Fast iteration

### Next: Staging API
🔄 Uncomment real API code in RealBillUploadService
🔄 Change AppEnvironment to .staging
🔄 Test all flows
🔄 Fix API mismatches

### Final: Production API
🎯 Deploy backend to production
🎯 Change AppEnvironment to .production for releases
🎯 Monitor errors and performance

---

## Troubleshooting

### Problem: "Cannot connect to API"

**Check:**
1. Is AppEnvironment set to `.development`? (uses mock)
2. Is the staging/production URL correct?
3. Is the device/simulator connected to internet?
4. Are you sending the Bearer token?

### Problem: "401 Unauthorized"

**Check:**
1. Is user logged in? (`AuthService.shared.currentUser`)
2. Is token valid and not expired?
3. Is Authorization header formatted correctly?

### Problem: "File upload fails"

**Check:**
1. File size < 10MB?
2. File type allowed (PDF, JPG, PNG, HEIC)?
3. Multipart form data formatted correctly?
4. Content-Type header includes boundary?

---

## Resources

- **Apple Documentation:**
  - [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
  - [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)
  - [SwiftData](https://developer.apple.com/xcode/swiftdata/)

- **Industry Patterns:**
  - [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
  - [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

- **Project Files:**
  - `API_INTEGRATION_GUIDE.md` - API endpoint documentation
  - `RealBillUploadService.swift` - Implementation with TODOs
  - `BillUploadServiceFactory.swift` - Environment switching

---

## Support

For architecture questions or issues, please refer to:
1. This document
2. Code comments in service files
3. Unit tests (when implemented)
4. SwiftUI previews for UI testing

Happy coding! 🚀
