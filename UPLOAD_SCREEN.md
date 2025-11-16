# Upload Screen - "Turn a Bill into an Asset"

**Purpose:** Make uploading feel like unlocking a cheat code, not doing admin. Transform bills into actionable financial data and marketplace assets.

---

## 🎯 Phase 1: Design & Planning

**Goal:** Define upload flow, OCR/AI extraction system, and data validation

### Tasks

- [ ] **Task 1.1:** Create UI/UX flow for upload journey
  - **Acceptance Criteria:**
    - Wireframes for 3-step upload process
    - Bill type selection screen
    - File upload/camera screens
    - Confirmation/editing screen
    - Success/analyzing screen
    - Error recovery flows
    - Dark mode variants
  - **Tests:** Manual design review and user flow testing
  - **Effort:** 5 hours

- [ ] **Task 1.2:** Define data models for upload
  - **Acceptance Criteria:**
    - `BillUpload` model (file, type, status, metadata)
    - `ExtractedBillData` model (provider, amount, dueDate, fees, lineItems)
    - `UploadProgress` model (step, status, message)
    - `BillValidation` model (errors, warnings, suggestions)
    - All models Codable and Identifiable
  - **Tests:**
    - Unit tests for model initialization
    - Unit tests for validation rules
  - **Effort:** 4 hours

- [ ] **Task 1.3:** Design OCR/AI extraction pipeline
  - **Acceptance Criteria:**
    - Document OCR service integration (e.g., Google Vision, AWS Textract)
    - AI model for bill classification
    - Field extraction rules for each bill type
    - Confidence scoring for extracted data
    - Fallback strategies for low confidence
  - **Tests:**
    - Unit tests for extraction logic
    - Integration tests with OCR service
    - Accuracy tests with sample bills
  - **Effort:** 7 hours

- [ ] **Task 1.4:** Define supported bill types and formats
  - **Acceptance Criteria:**
    - Supported types: Internet, Mobile, Power, Water, Gas, Insurance, Streaming
    - Supported formats: PDF, JPG, PNG, HEIC
    - File size limits (max 10MB)
    - Image quality requirements
  - **Tests:**
    - Unit tests for format validation
    - Sample bills for each type
  - **Effort:** 3 hours

- [ ] **Task 1.5:** Design validation and error correction flow
  - **Acceptance Criteria:**
    - Validation rules for each field
    - User-friendly error messages
    - Smart suggestions for corrections
    - Confidence indicators for extracted data
  - **Tests:**
    - Unit tests for validation rules
    - UI tests for error states
  - **Effort:** 4 hours

- [ ] **Task 1.6:** Define upload history and management
  - **Acceptance Criteria:**
    - List of all uploads
    - Status indicators (Analyzing, Complete, Error)
    - Re-upload capability
    - Delete capability
  - **Tests:**
    - Unit tests for history management
    - UI tests for actions
  - **Effort:** 3 hours

- [ ] **Task 1.7:** Design API contracts for upload
  - **Acceptance Criteria:**
    - POST `/uploads/initiate` to start upload
    - POST `/uploads/:id/file` for file upload
    - POST `/uploads/:id/confirm` to confirm extracted data
    - GET `/uploads/:id/status` for processing status
    - Multipart form-data support for files
  - **Tests:**
    - Unit tests for DTO mapping
    - Mock API implementation
  - **Effort:** 4 hours

- [ ] **Task 1.8:** Define privacy and data handling
  - **Acceptance Criteria:**
    - Files encrypted in transit and at rest
    - PII stripped before marketplace aggregation
    - User consent for data sharing
    - Data retention policy (e.g., 12 months)
  - **Tests:**
    - Security audit checklist
    - Encryption tests
  - **Effort:** 4 hours

- [ ] **Task 1.9:** Define analytics events for upload
  - **Acceptance Criteria:**
    - Upload initiation events
    - Step completion events
    - Success/failure events
    - Time-to-upload metrics
  - **Tests:** Analytics validation
  - **Effort:** 2 hours

**Phase 1 Acceptance Criteria:**
- ✅ Upload flow approved
- ✅ OCR/AI pipeline designed
- ✅ Privacy requirements met
- ✅ API contracts defined

---

## 🏗️ Phase 2: Core UI Components

**Goal:** Build upload interface and step-by-step flow

### Tasks

- [ ] **Task 2.1:** Create `UploadHeroView` component
  - **Acceptance Criteria:**
    - Compelling headline and subline
    - Visual showing value (unlock insights)
    - "Get started" CTA
    - Animation on appear
  - **Tests:**
    - UI tests for CTA
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 3 hours

- [ ] **Task 2.2:** Create `BillTypeSelector` component
  - **Acceptance Criteria:**
    - Grid of bill type cards with icons
    - Clear labels for each type
    - Selection feedback
    - "Other" option for unlisted types
  - **Tests:**
    - UI tests for selection
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.3:** Create `FileUploadView` component
  - **Acceptance Criteria:**
    - "Upload PDF" button with file picker
    - "Upload photo" button with photo library
    - "Take a picture" button with camera
    - Drag-and-drop support (iPad)
    - File type and size validation
  - **Tests:**
    - UI tests for file selection
    - Unit tests for validation
    - Snapshot tests
  - **Effort:** 5 hours

- [ ] **Task 2.4:** Create `CameraView` component
  - **Acceptance Criteria:**
    - Live camera preview
    - Capture button
    - Flash toggle
    - Guide overlay for bill alignment
    - Auto-focus on bill
  - **Tests:**
    - UI tests for camera controls
    - Manual testing on device
  - **Effort:** 6 hours

- [ ] **Task 2.5:** Create `ExtractionProgressView` component
  - **Acceptance Criteria:**
    - Progress indicator with steps
    - Status messages (Extracting text, Analyzing, etc.)
    - Estimated time remaining
    - Cancellable
  - **Tests:**
    - UI tests for progress states
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.6:** Create `DataConfirmationView` component
  - **Acceptance Criteria:**
    - Shows extracted data in editable fields
    - Confidence indicators for each field
    - Warnings for low confidence
    - "Looks good" and "Edit" actions
  - **Tests:**
    - UI tests for editing
    - Unit tests for confidence display
    - Snapshot tests
  - **Effort:** 5 hours

- [ ] **Task 2.7:** Create `UploadSuccessView` component
  - **Acceptance Criteria:**
    - Success animation (checkmark, confetti)
    - "Your report is ready" message
    - CTAs: "View Bill Health" / "Explore Marketplace"
    - Share achievement option
  - **Tests:**
    - UI tests for CTAs
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.8:** Create `UploadHistoryList` component
  - **Acceptance Criteria:**
    - List of past uploads
    - Status badges (Analyzed, Processing, Error)
    - Tap to view details or retry
    - Swipe to delete
  - **Tests:**
    - UI tests for interactions
    - Snapshot tests for states
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.9:** Create error and retry views
  - **Acceptance Criteria:**
    - Upload failed view with retry option
    - OCR failed view with manual entry option
    - Network error view
    - User-friendly messaging
  - **Tests:**
    - UI tests for retry flows
    - Snapshot tests
  - **Effort:** 3 hours

**Phase 2 Acceptance Criteria:**
- ✅ All upload UI components built
- ✅ Camera and file picker functional
- ✅ UI tests passing
- ✅ Accessibility audit passed

---

## ⚙️ Phase 3: Business Logic & Data Layer

**Goal:** Implement upload services, OCR integration, and data validation

### Tasks

- [ ] **Task 3.1:** Create `UploadViewModel` with Combine
  - **Acceptance Criteria:**
    - Manages multi-step upload state
    - Handles file selection and camera capture
    - Triggers OCR and AI extraction
    - Validates extracted data
    - Manages upload history
  - **Tests:**
    - Unit tests for state machine
    - Unit tests for validation
    - Memory leak tests
  - **Effort:** 6 hours

- [ ] **Task 3.2:** Implement `FileUploadService`
  - **Acceptance Criteria:**
    - Uploads files to backend
    - Multipart form-data support
    - Progress tracking
    - Resumable uploads
    - Handles large files efficiently
  - **Tests:**
    - Unit tests with mock API
    - Integration tests
    - Performance tests with large files
  - **Effort:** 5 hours

- [ ] **Task 3.3:** Integrate OCR service (Google Vision / AWS Textract)
  - **Acceptance Criteria:**
    - OCR SDK integrated
    - Text extraction working
    - Handles multi-page PDFs
    - Handles poor quality images
    - Returns confidence scores
  - **Tests:**
    - Integration tests with sample bills
    - Accuracy tests (target 95%+ for good quality)
    - Error handling tests
  - **Effort:** 8 hours

- [ ] **Task 3.4:** Implement `BillClassificationService`
  - **Acceptance Criteria:**
    - AI model classifies bill type
    - Extracts provider name
    - Identifies key fields based on type
    - Returns confidence score
  - **Tests:**
    - Unit tests with known bills
    - Integration tests with AI service
    - Accuracy tests (target 90%+)
  - **Effort:** 7 hours

- [ ] **Task 3.5:** Implement field extraction logic
  - **Acceptance Criteria:**
    - Extracts amount, due date, account number
    - Extracts fees and line items
    - Handles different formats per provider
    - Regex patterns for common providers
  - **Tests:**
    - Unit tests for extraction patterns
    - Integration tests with real bills
    - Edge case tests
  - **Effort:** 6 hours

- [ ] **Task 3.6:** Implement data validation service
  - **Acceptance Criteria:**
    - Validates amount format and range
    - Validates date format
    - Validates provider against known list
    - Flags suspicious data for review
  - **Tests:**
    - Unit tests for validation rules
    - Integration tests
  - **Effort:** 4 hours

- [ ] **Task 3.7:** Implement upload history management
  - **Acceptance Criteria:**
    - Persists upload history locally
    - Syncs with backend
    - Handles retry for failed uploads
    - Manages cache for uploaded files
  - **Tests:**
    - Unit tests for persistence
    - Integration tests for sync
  - **Effort:** 4 hours

- [ ] **Task 3.8:** Implement image processing
  - **Acceptance Criteria:**
    - Auto-rotate images
    - Enhance contrast for better OCR
    - Compress images before upload
    - Crop to bill boundaries
  - **Tests:**
    - Unit tests for image processing
    - Visual tests for enhancements
  - **Effort:** 5 hours

- [ ] **Task 3.9:** Implement encryption for uploaded files
  - **Acceptance Criteria:**
    - Files encrypted before upload
    - Encryption keys managed securely
    - Decryption for viewing/editing
  - **Tests:**
    - Unit tests for encryption/decryption
    - Security audit
  - **Effort:** 4 hours

**Phase 3 Acceptance Criteria:**
- ✅ OCR integration working (95%+ accuracy)
- ✅ AI classification functional (90%+ accuracy)
- ✅ File upload reliable and secure
- ✅ All services tested (85%+ coverage)

---

## 🔌 Phase 4: Integration & Data Flow

**Goal:** Connect upload UI to backend services and ensure end-to-end flow

### Tasks

- [ ] **Task 4.1:** Integrate UploadViewModel with UploadView
  - **Acceptance Criteria:**
    - Full upload flow working
    - Progress updates reflected in UI
    - Error handling working
    - Navigation after success
  - **Tests:**
    - Integration tests for full flow
    - UI tests for each step
  - **Effort:** 4 hours

- [ ] **Task 4.2:** Implement backend upload API integration
  - **Acceptance Criteria:**
    - File upload endpoint working
    - OCR trigger endpoint working
    - Status polling endpoint working
    - Webhook for completion (optional)
  - **Tests:**
    - Integration tests with backend
    - Mock server tests
  - **Effort:** 5 hours

- [ ] **Task 4.3:** Implement real-time upload status updates
  - **Acceptance Criteria:**
    - WebSocket or polling for status
    - UI updates in real-time
    - Handles disconnections
  - **Tests:**
    - Integration tests for status updates
    - UI tests for real-time display
  - **Effort:** 4 hours

- [ ] **Task 4.4:** Implement camera permissions handling
  - **Acceptance Criteria:**
    - Request camera permission
    - Handle denied permission gracefully
    - Provide alternative (photo library)
    - Clear permission instructions
  - **Tests:**
    - UI tests for permission flows
  - **Effort:** 2 hours

- [ ] **Task 4.5:** Implement photo library integration
  - **Acceptance Criteria:**
    - Access photo library
    - Image picker UI
    - Handle limited permissions (iOS 14+)
  - **Tests:**
    - UI tests for photo picker
  - **Effort:** 3 hours

- [ ] **Task 4.6:** Implement file picker integration
  - **Acceptance Criteria:**
    - Document picker for PDFs
    - Filter for supported types
    - Handle iCloud documents
  - **Tests:**
    - UI tests for file picker
  - **Effort:** 3 hours

- [ ] **Task 4.7:** Implement background upload support
  - **Acceptance Criteria:**
    - Uploads continue in background
    - Notification on completion
    - Resume on app restart
  - **Tests:**
    - Integration tests for background upload
  - **Effort:** 5 hours

- [ ] **Task 4.8:** Implement retry and recovery mechanisms
  - **Acceptance Criteria:**
    - Auto-retry for network failures
    - Resume failed uploads
    - Clear error messaging
  - **Tests:**
    - Integration tests for retry logic
    - UI tests for error recovery
  - **Effort:** 4 hours

**Phase 4 Acceptance Criteria:**
- ✅ End-to-end upload flow working
- ✅ Real-time status updates functional
- ✅ Background upload reliable
- ✅ All integration tests passing

---

## ✅ Phase 5: Testing & Quality Assurance

**Goal:** Ensure upload reliability and accuracy

### Tasks

- [ ] **Task 5.1:** Write unit tests for OCR accuracy
  - **Acceptance Criteria:**
    - Test with 100+ sample bills
    - Measure accuracy per bill type
    - Target 95%+ accuracy for good quality
    - Document accuracy by provider
  - **Tests:** Run OCR accuracy test suite
  - **Effort:** 8 hours

- [ ] **Task 5.2:** Write unit tests for validation logic
  - **Acceptance Criteria:**
    - All validation rules tested
    - Edge cases covered
    - Error messages verified
  - **Tests:** Run unit test suite
  - **Effort:** 4 hours

- [ ] **Task 5.3:** Write integration tests for upload service
  - **Acceptance Criteria:**
    - Full upload flow tested
    - Error scenarios tested
    - Retry logic validated
  - **Tests:** Run integration test suite
  - **Effort:** 5 hours

- [ ] **Task 5.4:** Write UI tests for upload journey
  - **Acceptance Criteria:**
    - Happy path tested
    - Camera capture tested
    - File upload tested
    - Error recovery tested
  - **Tests:** Run UI test suite
  - **Effort:** 6 hours

- [ ] **Task 5.5:** Performance testing for upload
  - **Acceptance Criteria:**
    - Upload time < 5 seconds for 2MB file
    - OCR processing < 10 seconds
    - No memory leaks during upload
  - **Tests:**
    - Instruments profiling
    - Performance benchmarks
  - **Effort:** 4 hours

- [ ] **Task 5.6:** Security testing
  - **Acceptance Criteria:**
    - File encryption verified
    - No PII leaked in logs
    - Secure file storage
  - **Tests:**
    - Security audit
    - Penetration testing
  - **Effort:** 4 hours

- [ ] **Task 5.7:** Accessibility testing
  - **Acceptance Criteria:**
    - Camera view accessible
    - File picker accessible
    - Progress updates announced
  - **Tests:**
    - Accessibility audit
    - Manual VoiceOver testing
  - **Effort:** 3 hours

- [ ] **Task 5.8:** Usability testing
  - **Acceptance Criteria:**
    - Test with real users
    - Measure completion rate
    - Collect feedback on flow
    - Target 90%+ completion rate
  - **Tests:** User acceptance testing
  - **Effort:** 5 hours

**Phase 5 Acceptance Criteria:**
- ✅ OCR accuracy > 95%
- ✅ All tests passing
- ✅ Performance benchmarks met
- ✅ Security audit passed
- ✅ User testing successful (90%+ completion)

---

## 💎 Phase 6: Polish & Optimization

**Goal:** Make upload delightful and foolproof

### Tasks

- [ ] **Task 6.1:** Add upload animations and feedback
  - **Acceptance Criteria:**
    - Camera shutter animation
    - Upload progress animation
    - Success confetti animation
    - Haptic feedback throughout
  - **Tests:**
    - Manual testing
    - Performance with animations
  - **Effort:** 5 hours

- [ ] **Task 6.2:** Implement smart bill detection
  - **Acceptance Criteria:**
    - Auto-detect bill boundaries in camera
    - Highlight bill in preview
    - Auto-capture when aligned
    - Guide user to align properly
  - **Tests:**
    - Integration tests
    - Manual testing with devices
  - **Effort:** 6 hours

- [ ] **Task 6.3:** Add contextual tips and guidance
  - **Acceptance Criteria:**
    - Tips for better photos
    - Provider-specific guidance
    - First-time user tutorial
  - **Tests:**
    - UI tests
    - User testing
  - **Effort:** 3 hours

- [ ] **Task 6.4:** Optimize OCR for speed
  - **Acceptance Criteria:**
    - Client-side pre-processing
    - Parallel processing where possible
    - Caching for repeated uploads
  - **Tests:**
    - Performance benchmarks
    - Accuracy maintained
  - **Effort:** 5 hours

- [ ] **Task 6.5:** Implement smart field suggestions
  - **Acceptance Criteria:**
    - Auto-complete for provider names
    - Suggest corrections for typos
    - Learn from user corrections
  - **Tests:**
    - Unit tests for suggestions
    - User testing
  - **Effort:** 4 hours

- [ ] **Task 6.6:** Add upload templates for common providers
  - **Acceptance Criteria:**
    - Pre-configured field mappings
    - Provider-specific validation
    - Faster extraction for known formats
  - **Tests:**
    - Integration tests per provider
  - **Effort:** 6 hours

- [ ] **Task 6.7:** Implement batch upload support
  - **Acceptance Criteria:**
    - Upload multiple bills at once
    - Queue management
    - Parallel processing
  - **Tests:**
    - Integration tests for batch
    - Performance tests
  - **Effort:** 5 hours

- [ ] **Task 6.8:** Add upload gamification
  - **Acceptance Criteria:**
    - Achievement for first upload
    - Milestone badges (5, 10, 25 uploads)
    - Leaderboard for community (optional)
  - **Tests:**
    - UI tests for achievements
  - **Effort:** 4 hours

**Phase 6 Acceptance Criteria:**
- ✅ Upload feels magical and effortless
- ✅ OCR speed and accuracy optimized
- ✅ Smart features working
- ✅ Batch upload functional

---

## 📚 Phase 7: Documentation & Handoff

**Goal:** Complete upload documentation

### Tasks

- [ ] **Task 7.1:** Document OCR/AI pipeline
  - **Acceptance Criteria:**
    - Integration guide for OCR service
    - AI model specifications
    - Accuracy benchmarks documented
  - **Tests:** Technical review
  - **Effort:** 4 hours

- [ ] **Task 7.2:** Write upload API documentation
  - **Acceptance Criteria:**
    - All endpoints documented
    - File format requirements
    - Error codes explained
  - **Tests:** API documentation review
  - **Effort:** 3 hours

- [ ] **Task 7.3:** Create privacy and security documentation
  - **Acceptance Criteria:**
    - Encryption methods documented
    - PII handling explained
    - Data retention policies
  - **Tests:** Legal review
  - **Effort:** 3 hours

- [ ] **Task 7.4:** Write developer guide for upload
  - **Acceptance Criteria:**
    - How to add new bill types
    - How to customize extraction
    - How to test OCR accuracy
  - **Tests:** Developer walkthrough
  - **Effort:** 3 hours

- [ ] **Task 7.5:** Create user help documentation
  - **Acceptance Criteria:**
    - How to upload a bill
    - Tips for better photos
    - Troubleshooting guide
  - **Tests:** User testing
  - **Effort:** 3 hours

- [ ] **Task 7.6:** Document analytics events
  - **Acceptance Criteria:**
    - All upload events listed
    - Funnel analysis setup
  - **Tests:** Analytics validation
  - **Effort:** 2 hours

- [ ] **Task 7.7:** Create release notes
  - **Acceptance Criteria:**
    - Upload features highlighted
    - OCR accuracy metrics
    - Future enhancements
  - **Tests:** Stakeholder review
  - **Effort:** 2 hours

- [ ] **Task 7.8:** Conduct code review and handoff
  - **Acceptance Criteria:**
    - Code review completed
    - Team walkthrough done
    - Production-ready
  - **Tests:** Code review checklist
  - **Effort:** 3 hours

**Phase 7 Acceptance Criteria:**
- ✅ All documentation complete
- ✅ Code review approved
- ✅ Ready for production

---

## 📊 Success Metrics

- **Completion Rate:** 90%+ of initiated uploads complete successfully
- **OCR Accuracy:** 95%+ for good quality images
- **Classification Accuracy:** 90%+ for bill type
- **Upload Time:** < 30 seconds end-to-end
- **User Satisfaction:** 4.5+ stars for upload experience
- **Retry Rate:** < 5% of uploads need retry

---

## 🔗 Dependencies

- Backend upload API
- OCR service (Google Vision / AWS Textract)
- AI classification model
- File storage service (S3, CloudKit)
- Image processing libraries
- Analytics service

---

## 📅 Estimated Timeline

- **Phase 1:** 36 hours (4-5 days)
- **Phase 2:** 38 hours (5 days)
- **Phase 3:** 49 hours (6-7 days)
- **Phase 4:** 30 hours (4 days)
- **Phase 5:** 39 hours (5 days)
- **Phase 6:** 38 hours (5 days)
- **Phase 7:** 23 hours (3 days)

**Total Estimated Effort:** 253 hours (~6-7 weeks for one developer)

---

## 🚀 Next Steps

1. Review and approve Phase 1 plan
2. Select and integrate OCR service
3. Collect sample bills for testing
4. Begin Phase 1 Task 1.1: Upload flow wireframes
