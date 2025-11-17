# Upload Screen - iOS Implementation Plan

**Purpose:** Enable iOS users to upload bill images/PDFs and get AI-powered analysis with marketplace comparisons.

**Architecture:** Privacy-first, localStorage-based (bills stored on device only)

**Backend:** LAW_4_ME Production API (`https://www.billixapp.com/api/v1`)

**AI Processing:** Backend handles everything (Pulse AI + OpenAI GPT-4o-mini)

---

## 🎯 Phase 1: Setup & Foundation - ✅ COMPLETED

### Tasks Completed:

- [x] **Task 1.1:** Install Supabase Swift SDK 2.37.0 via SPM
  - Added all modules: Auth, Storage, Functions, PostgREST, Realtime, Supabase
  - Linked to Billix target in Xcode

- [x] **Task 1.2:** Create Config.swift with production configuration
  - Supabase URL: `https://pkecbalzzcndewlftiit.supabase.co`
  - Supabase Anon Key: Configured
  - API Base URL: `https://www.billixapp.com/api/v1`
  - Max File Size: 10MB
  - Supported Types: PDF, PNG, JPEG, HEIC, GIF, WebP

- [x] **Task 1.3:** Create BillAnalysis.swift with complete API response models
  - `BillAnalysisResponse` - Top-level response
  - `BillAnalysis` - Full analysis data
  - `KeyFact` - Key facts (label + value)
  - `LineItem` - Line item breakdown
  - `CostBreakdown` - Cost categories
  - `MarketplaceComparison` - Area comparisons
  - `FileMetadata` - Upload metadata
  - `UploadErrorResponse` - Error handling

- [x] **Task 1.4:** Create StoredBill.swift SwiftData model
  - UUID-based identification
  - All bill fields (provider, amount, dates, category, etc.)
  - JSON storage for full analysis (`@Attribute(.externalStorage)`)
  - Convenience initializer from API response
  - Fully configured for SwiftData persistence

- [x] **Task 1.5:** Create APIClient.swift with multipart upload implementation
  - Uploads to `/api/v1/bills/upload` endpoint
  - Multipart form-data with boundary
  - Bearer token authentication (`Authorization: Bearer {token}`)
  - Proper MIME type detection
  - Error handling (400, 401, 500)
  - Marketplace contribution support (`/api/v1/marketplace/contribute`)

- [x] **Task 1.6:** Create SupabaseService.swift authentication service
  - Sign up (`signUp`)
  - Sign in (`signIn`)
  - Sign out (`signOut`)
  - Session management (`getSession`, `refreshSession`)
  - Keychain storage (secure token persistence)
  - Session type handling

- [x] **Task 1.7:** Create FileValidator.swift with magic byte validation
  - **Magic byte validation** (not just extensions!)
  - PDF: `0x25 0x50 0x44 0x46` ("%PDF-")
  - PNG: `0x89 0x50 0x4E 0x47...`
  - JPEG: `0xFF 0xD8 0xFF`
  - HEIC: `ftyp heic` at offset 4
  - GIF: `0x47 0x49 0x46`
  - WebP: `RIFF...WEBP`
  - Size limits: 100 bytes (min) - 10MB (max)
  - Extension matching validation

- [x] **Task 1.8:** Update BillixApp.swift with SwiftData configuration
  - Added `StoredBill` to model container
  - Schema includes both `Item` and `StoredBill`

- [x] **Task 1.9:** Fix platform compatibility issues
  - Added `#if os(iOS)` conditionals for keyboard/navigation modifiers
  - Fixed LoginView.swift, HomeView.swift, ExploreView.swift, UploadView.swift, ProfileView.swift, HealthView.swift
  - Cross-platform SwiftUI compatibility

- [x] **Task 1.10:** Resolve all build errors
  - Fixed "No such module 'Supabase'" error
  - Fixed TextField modifier incompatibility
  - Fixed navigationBarTitleDisplayMode macOS errors
  - **Build Status:** ✅ **SUCCESSFUL**

**Time Spent:** ~8-10 hours (including Xcode setup, debugging, SDK integration)

---

## 🏗️ What We're Building Next (Phase 2: Core Upload Flow)

### Goal: End-to-end bill upload functionality

**Timeline:** 32-40 hours (4-5 days)

---

### Task 2.1: Create Upload View Model

- [ ] Create `Billix/ViewModels/UploadViewModel.swift`
- [ ] Implement upload state machine (idle, selecting, uploading, analyzing, success, error)
- [ ] Add file selection handlers (camera/photos/files)
- [ ] Integrate `APIClient.uploadBill()` call
- [ ] Parse `BillAnalysisResponse` from API
- [ ] Save to SwiftData using `StoredBill` model
- [ ] Implement error handling with user-friendly messages
- [ ] Add state management with `@Published` properties
- [ ] Implement progress tracking (0-30% upload, 30-90% analyzing, 90-100% saving)
- [ ] Handle all API errors (400, 401, 500, network)
- [ ] Add token refresh logic on 401 (expired token)

**Effort:** 6 hours

---

### Task 2.2: Camera Integration

- [ ] Create `Billix/Views/Camera/CameraView.swift`
- [ ] Create `Billix/Views/Camera/CameraPicker.swift`
- [ ] Implement `UIImagePickerController` or `Camera` picker
- [ ] Add camera permission request with clear messaging
- [ ] Add flash toggle functionality
- [ ] Ensure capture returns high-quality image
- [ ] Convert captured image to Data for upload

**Effort:** 5 hours

---

### Task 2.3: Photo Library Integration

- [ ] Create `Billix/Views/PhotoPicker/PhotoPickerView.swift`
- [ ] Implement `PHPickerViewController` integration
- [ ] Add filter for images only
- [ ] Handle photo library permissions
- [ ] Add multi-selection support (future enhancement)

**Effort:** 3 hours

---

### Task 2.4: Document Picker Integration

- [ ] Create `Billix/Views/DocumentPicker/DocumentPickerView.swift`
- [ ] Implement `UIDocumentPickerViewController` integration
- [ ] Add filter for PDFs only (`.pdf` content type)
- [ ] Add iCloud document support
- [ ] Implement error handling for access issues

**Effort:** 3 hours

---

### Task 2.5: Main Upload Screen

- [ ] Update `Billix/Features/Upload/UploadView.swift` (replace placeholder)
- [ ] Add three prominent buttons (Camera, Photos, PDF)
- [ ] Apply Billix brand colors and design
- [ ] Add progress indicator during upload
- [ ] Implement success animation (checkmark with haptic feedback)
- [ ] Add error display with retry button
- [ ] Implement file validation before upload (client-side check)

**Effort:** 5 hours

---

### Task 2.6: Upload Progress View

- [ ] Create `Billix/Views/Upload/UploadProgressView.swift`
- [ ] Implement linear progress bar with smooth animation
- [ ] Add status text updates based on progress:
  - [ ] 0-30%: "Uploading your bill..."
  - [ ] 30-90%: "Analyzing with AI... (this takes 15-30 seconds)"
  - [ ] 90-100%: "Saving results..."
- [ ] Add cancel button (aborts upload task)
- [ ] Implement haptic feedback on completion

**Effort:** 3 hours

---

### Task 2.7: Analysis Results View

- [ ] Create `Billix/Views/Results/AnalysisResultsView.swift`
- [ ] Create `Billix/Views/Results/Components/KeyFactsGrid.swift`
- [ ] Create `Billix/Views/Results/Components/LineItemsList.swift`
- [ ] Create `Billix/Views/Results/Components/InsightsCards.swift`
- [ ] Create `Billix/Views/Results/Components/MarketplaceCard.swift`
- [ ] Implement Header Section:
  - [ ] Provider name (large, bold)
  - [ ] Total amount (prominent)
  - [ ] Due date (highlighted if soon)
  - [ ] Category badge
- [ ] Implement Key Facts Grid (2 columns):
  - [ ] Display all `keyFacts` from analysis
  - [ ] Label + Value format
  - [ ] Icons for common metrics (kWh, GB, etc.)
- [ ] Implement Line Items List:
  - [ ] Scrollable list of charges
  - [ ] Description + Amount
  - [ ] Category badge (if available)
- [ ] Implement Insights Section:
  - [ ] AI-generated insights cards
  - [ ] Color-coded (savings = green, warnings = red, info = blue)
- [ ] Implement Marketplace Comparison (if available):
  - [ ] Area average vs user's bill
  - [ ] Percentage difference (+14.3% above average)
  - [ ] Color-coded indicator (green = below, red = above)
  - [ ] "Not enough data" fallback
- [ ] Implement Actions:
  - [ ] "Save Bill" button (saves to SwiftData)
  - [ ] "Share" option (future)
  - [ ] "Contribute to Marketplace" toggle

**Effort:** 8 hours

---

### Task 2.8: Error Handling UI

- [ ] Create `Billix/Views/Upload/ErrorView.swift`
- [ ] Add error message handling:
  - [ ] Network error → "No internet connection. Please try again."
  - [ ] 401 error → "Session expired. Please log in again."
  - [ ] 400 error → Show API error message (e.g., "File too large")
  - [ ] 500 error → "Something went wrong on our end. Please try again later."
  - [ ] Timeout → "Upload taking too long. Check your connection."
- [ ] Add retry button for all errors except 401
- [ ] Add "Go to Login" button for 401 errors

**Effort:** 3 hours

---

### Task 2.9: Integration Testing

- [ ] Test Camera → Upload → Results → Save flow
- [ ] Test Photos → Upload → Results → Save flow
- [ ] Test PDF → Upload → Results → Save flow
- [ ] Test Network failure → Error → Retry flow
- [ ] Verify bill persists in SwiftData after save
- [ ] Verify marketplace comparison displays when available
- [ ] Test with 5+ different bill types:
  - [ ] Electric bill
  - [ ] Gas bill
  - [ ] Internet bill
  - [ ] Water bill
  - [ ] Phone bill

**Effort:** 4 hours

---

## Phase 2 Acceptance Criteria

- [ ] User can take photo of bill → get AI analysis
- [ ] User can select photo from library → get AI analysis
- [ ] User can upload PDF → get AI analysis
- [ ] Analysis displays provider, amount, key facts, line items, insights
- [ ] Marketplace comparison shows when available
- [ ] Bill saves to SwiftData (local device storage)
- [ ] Error handling works for all failure cases
- [ ] Upload progress shows status messages
- [ ] End-to-end flow feels smooth and polished

**Estimated Time:** 40 hours (5 days)

---

## 📚 Backend Integration Details

### How It Works (Privacy-First Architecture)

```
iOS App → Upload bill (camera/photo/PDF)
    ↓
Client-side validation (FileValidator)
    - Check file type via magic bytes
    - Check size (100 bytes - 10MB)
    ↓
Upload to /api/v1/bills/upload (APIClient)
    - Multipart form-data
    - Bearer token: Authorization: Bearer {accessToken}
    ↓
Backend: Temp storage (guest-temp/ in Supabase)
    - Auto-deleted after 10 minutes
    ↓
Backend: Pulse AI extraction
    - Extracts all text, tables, data from PDF/image
    - Schema-less (works with any bill format)
    ↓
Backend: OpenAI GPT-4o-mini analysis
    - Provider, amount, category, subcategory
    - Due date, ZIP code, usage metrics
    - Key facts (adaptive to bill type)
    - Line items, cost breakdown
    - AI insights (savings opportunities, warnings)
    ↓
Backend: Returns BillAnalysisResponse
    - Full structured analysis
    - Marketplace comparison (if available)
    ↓
Backend: Deletes temp file immediately
    - Zero permanent storage on server
    ↓
iOS App: Receives analysis
    - Display to user
    - Save to SwiftData (local device storage)
    ↓
iOS App: (Optional) Contribute to marketplace
    - POST to /api/v1/marketplace/contribute
    - Anonymized data (ZIP → first 3 digits, no user_id)
```

### What Backend Handles (You Don't Need to Build)

- ✅ PDF/Image OCR extraction (Pulse AI)
- ✅ Bill classification (OpenAI)
- ✅ Field extraction and parsing (OpenAI)
- ✅ Data validation (backend)
- ✅ Marketplace aggregation (backend)
- ✅ File cleanup (backend)
- ✅ Provider auto-creation (backend)

### What iOS Handles (What You're Building)

- ✅ File selection (camera/photos/PDF)
- ✅ Client-side validation (type, size)
- ✅ API calls with bearer token
- ✅ Progress tracking
- ✅ Results display
- ✅ Local storage (SwiftData)
- ✅ User experience & animations

---

## 🔗 API Endpoints

### Upload Bill

**URL:** `POST https://www.billixapp.com/api/v1/bills/upload`

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: multipart/form-data; boundary={boundary}
```

**Request Body:**
```
--{boundary}
Content-Disposition: form-data; name="file"; filename="bill.pdf"
Content-Type: application/pdf

{binary file data}
--{boundary}--
```

**Success Response (200):**
```json
{
  "success": true,
  "analysis": {
    "provider": "DTE Energy",
    "amount": 124.56,
    "billDate": "2025-01-15",
    "dueDate": "2025-02-01",
    "category": "utilities",
    "subcategory": "electricity",
    "zipCode": "48104",
    "keyFacts": [
      {"label": "Usage", "value": "450 kWh"},
      {"label": "Rate", "value": "$0.28/kWh"}
    ],
    "lineItems": [
      {
        "description": "Electricity Supply",
        "amount": 45.23,
        "category": "supply"
      }
    ],
    "insights": [
      "Your usage is 15% higher than last month",
      "Consider off-peak hours to save $8/month"
    ],
    "marketplaceComparison": {
      "areaAverage": 110.00,
      "percentDiff": 13.2,
      "zipPrefix": "481",
      "position": "above"
    }
  },
  "metadata": {
    "fileName": "bill.pdf",
    "fileSize": 234567,
    "fileType": "application/pdf"
  }
}
```

**Error Responses:**

**400 - File Validation:**
```json
{"error": "Unsupported file type. Please upload PDF, PNG, JPEG, or HEIC files only."}
```

**400 - File Too Large:**
```json
{"error": "File too large. Maximum size is 10MB"}
```

**401 - Unauthorized:**
```json
{"error": "Authentication required"}
```

**500 - Server Error:**
```json
{
  "error": "Failed to analyze bill",
  "details": "Pulse AI API error: 403 - Trial period expired"
}
```

---

### Marketplace Contribution

**URL:** `POST https://www.billixapp.com/api/v1/marketplace/contribute`

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "provider": "DTE Energy",
  "category": "utilities",
  "subcategory": "electricity",
  "amount": 124.56,
  "zip_prefix": "481",
  "usage_metrics": {
    "usage": 450,
    "unit": "kWh"
  }
}
```

**Success Response (200):**
```json
{"success": true, "message": "Contribution added to marketplace"}
```

---

## 📊 Success Metrics

- **Upload Success Rate:** 95%+ of uploads complete successfully
- **Upload Time:** < 5 seconds (file upload only)
- **Analysis Time:** 15-30 seconds (backend AI processing)
- **User Satisfaction:** 4.5+ stars for upload experience
- **Error Recovery:** 90%+ of errors resolve with retry

---

## 🚀 What's Next After Phase 2

### Phase 3: Polish & Features (24 hours)

- Marketplace comparison UI enhancements
- Upload history view (list of saved bills)
- Background upload support
- Success animations
- Retry logic improvements
- Haptic feedback

### Phase 4: Testing & QA (16 hours)

- Unit tests (UploadViewModel, APIClient, FileValidator)
- UI tests (upload flows)
- Real bill testing (20+ different providers)
- Performance testing
- Memory leak detection

---

## 📅 Summary

**Phase 1 (Setup):** ✅ **COMPLETE** (16 hours actual)
- Supabase SDK integrated
- Models created
- API client built
- File validation ready
- SwiftData configured
- Build successful

**Phase 2 (Core Upload):** 🔨 **IN PROGRESS** (40 hours estimated)
- File selection UI
- Camera/Photos/PDF pickers
- Upload view model
- Progress tracking
- Results display
- Error handling

**Phase 3 (Polish):** ⏳ **NOT STARTED** (24 hours estimated)

**Phase 4 (Testing):** ⏳ **NOT STARTED** (16 hours estimated)

**Total Estimate:** 96 hours (12 days for 1 developer)

---

## 💡 Key Architecture Decisions

### Why Privacy-First (localStorage/SwiftData)?

- **Legal:** Avoids GLBA compliance (no financial data on server)
- **Privacy:** Users own their data
- **Speed:** Instant bill access (no API calls)
- **Cost:** Zero database storage costs
- **Trust:** Complete user control

### Why Backend Handles AI?

- **Simplicity:** iOS just uploads → displays results
- **Flexibility:** Can swap AI services without iOS app update
- **Performance:** Heavy AI processing on server, not device
- **Cost:** Centralized API usage tracking
- **Quality:** Consistent results across all platforms

### Why Magic Byte Validation?

- **Security:** Prevents fake file extensions (virus.exe renamed to bill.pdf)
- **Reliability:** Confirms actual file type, not just name
- **Best Practice:** Industry standard for file validation

---

**Ready to start Phase 2!** All foundational work is complete and the build is successful. Time to build the upload UI! 🚀
