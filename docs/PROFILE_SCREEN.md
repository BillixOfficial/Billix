# Profile Screen - "Identity, Settings, & Trust"

**Purpose:** Be the stable place for identity, locations, and future trust/credits. Central hub for account management, privacy controls, and user preferences.

---

## 🎯 Phase 1: Design & Planning

**Goal:** Define profile architecture, privacy system, and account management

### Tasks

- [ ] **Task 1.1:** Create UI/UX wireframes for Profile Screen
  - **Acceptance Criteria:**
    - High-fidelity mockups for profile dashboard
    - Settings sections layouts
    - Privacy control panels
    - Account/plan management screens
    - Dark mode variants
    - Edit profile flows
  - **Tests:** Manual design review and user testing
  - **Effort:** 5 hours

- [ ] **Task 1.2:** Define data models for Profile
  - **Acceptance Criteria:**
    - `UserProfile` model (name, email, phone, avatar, verified status)
    - `Location` model (ZIP, city, state, isPrimary)
    - `ConnectedBill` model (provider, status, lastSync, autoImport)
    - `SubscriptionPlan` model (tier, features, billingCycle, expiryDate)
    - `PrivacySettings` model (anonymization consent, data sharing, marketing)
    - All models Codable and Identifiable
  - **Tests:**
    - Unit tests for model initialization
    - Unit tests for validation
  - **Effort:** 4 hours

- [ ] **Task 1.3:** Design authentication and verification system
  - **Acceptance Criteria:**
    - Phone number verification (OTP)
    - Email verification
    - Optional biometric auth
    - Session management
    - Multi-device support
  - **Tests:**
    - Unit tests for auth logic
    - Integration tests with auth service
    - Security audit
  - **Effort:** 6 hours

- [ ] **Task 1.4:** Design privacy and data control system
  - **Acceptance Criteria:**
    - Granular consent management
    - Anonymization toggle
    - Data export capability (GDPR)
    - Account deletion flow
    - Clear privacy policy integration
  - **Tests:**
    - Privacy audit
    - GDPR compliance check
  - **Effort:** 5 hours

- [ ] **Task 1.5:** Define subscription and billing system
  - **Acceptance Criteria:**
    - Free and Premium tier definitions
    - Feature gating logic
    - Upgrade/downgrade flows
    - Billing integration (Stripe/RevenueCat)
    - Promo code support
  - **Tests:**
    - Unit tests for feature gating
    - Integration tests with billing
  - **Effort:** 6 hours

- [ ] **Task 1.6:** Design multi-location support
  - **Acceptance Criteria:**
    - Primary and secondary locations
    - "Future move" ZIPs
    - Location-based TruePrice™ tuning
    - Moving checklist feature
  - **Tests:**
    - Unit tests for location logic
  - **Effort:** 3 hours

- [ ] **Task 1.7:** Design connected bills management
  - **Acceptance Criteria:**
    - List of uploaded bills
    - Status tracking (Active, Analyzing, Expired)
    - Auto-import capability (future)
    - Provider account linking (future)
    - Delete/archive bills
  - **Tests:**
    - Unit tests for bill management
    - UI tests for actions
  - **Effort:** 4 hours

- [ ] **Task 1.8:** Define API contracts for Profile
  - **Acceptance Criteria:**
    - GET `/profile` for user profile
    - PUT `/profile` for updates
    - GET `/profile/locations` for locations
    - POST `/profile/locations` to add location
    - GET `/profile/bills` for connected bills
    - PUT `/profile/settings/privacy` for privacy
    - GET `/profile/subscription` for plan info
  - **Tests:**
    - Unit tests for DTO mapping
    - Mock API implementation
  - **Effort:** 4 hours

- [ ] **Task 1.9:** Define analytics events for Profile
  - **Acceptance Criteria:**
    - Profile view events
    - Setting change events
    - Subscription upgrade events
    - Privacy toggle events
  - **Tests:** Analytics validation
  - **Effort:** 2 hours

**Phase 1 Acceptance Criteria:**
- ✅ All profile designs approved
- ✅ Privacy system compliant (GDPR, CCPA)
- ✅ Subscription system designed
- ✅ API contracts defined

---

## 🏗️ Phase 2: Core UI Components

**Goal:** Build profile management and settings UI

### Tasks

- [ ] **Task 2.1:** Create `ProfileHeaderView` component
  - **Acceptance Criteria:**
    - Avatar with edit capability
    - Name and email display
    - Verification badges (phone, email)
    - "Edit profile" button
  - **Tests:**
    - UI tests for edit flow
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.2:** Create `LocationsSection` component
  - **Acceptance Criteria:**
    - List of locations (primary highlighted)
    - Add location button
    - Edit/delete actions
    - ZIP auto-complete
  - **Tests:**
    - UI tests for CRUD operations
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 5 hours

- [ ] **Task 2.3:** Create `ConnectedBillsList` component
  - **Acceptance Criteria:**
    - Grid/list of connected bills
    - Provider logos and names
    - Status badges (Active, Analyzing, etc.)
    - Auto-import toggle (future)
    - Tap for details or delete
  - **Tests:**
    - UI tests for interactions
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 5 hours

- [ ] **Task 2.4:** Create `SubscriptionCard` component
  - **Acceptance Criteria:**
    - Current plan display (Free/Premium)
    - Feature comparison list
    - Upgrade CTA
    - Billing cycle and renewal date
    - Cancel subscription option
  - **Tests:**
    - UI tests for upgrade flow
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 5 hours

- [ ] **Task 2.5:** Create `PrivacyControlPanel` component
  - **Acceptance Criteria:**
    - Toggle for anonymized data sharing
    - Toggle for TruePrice™ inclusion
    - Clear explanations for each toggle
    - "Learn more" links
  - **Tests:**
    - UI tests for toggles
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.6:** Create `EditProfileView` component
  - **Acceptance Criteria:**
    - Form for name, email, phone
    - Avatar upload/change
    - Validation feedback
    - Save/cancel actions
  - **Tests:**
    - UI tests for form submission
    - Unit tests for validation
    - Snapshot tests
  - **Effort:** 5 hours

- [ ] **Task 2.7:** Create `SettingsListView` component
  - **Acceptance Criteria:**
    - Grouped settings sections
    - Disclosure indicators for sub-screens
    - Switches for toggleable settings
    - Clear section headers
  - **Tests:**
    - UI tests for navigation
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.8:** Create `SupportAndAboutView` component
  - **Acceptance Criteria:**
    - Contact support link
    - FAQ link
    - "How Billix works" explainer
    - Terms and Privacy Policy links
    - App version display
  - **Tests:**
    - UI tests for links
    - Snapshot tests
  - **Effort:** 3 hours

- [ ] **Task 2.9:** Create `DataExportView` component
  - **Acceptance Criteria:**
    - Request data export button
    - Export format options (JSON, CSV)
    - Download link when ready
    - Delete account option with confirmation
  - **Tests:**
    - UI tests for export flow
    - Integration tests for data export
  - **Effort:** 4 hours

**Phase 2 Acceptance Criteria:**
- ✅ All profile UI components built
- ✅ Settings navigation working
- ✅ Privacy controls functional
- ✅ Accessibility audit passed

---

## ⚙️ Phase 3: Business Logic & Data Layer

**Goal:** Implement profile services, auth, and privacy controls

### Tasks

- [ ] **Task 3.1:** Create `ProfileViewModel` with Combine
  - **Acceptance Criteria:**
    - Manages user profile state
    - Handles form validation
    - Syncs with backend
    - Loading, loaded, error states
  - **Tests:**
    - Unit tests for state management
    - Unit tests for validation
    - Memory leak tests
  - **Effort:** 6 hours

- [ ] **Task 3.2:** Implement `AuthService`
  - **Acceptance Criteria:**
    - Phone/email verification
    - OTP generation and validation
    - Session token management
    - Biometric auth integration
    - Multi-device session handling
  - **Tests:**
    - Unit tests with mock auth backend
    - Integration tests
    - Security tests
  - **Effort:** 8 hours

- [ ] **Task 3.3:** Implement `ProfileService`
  - **Acceptance Criteria:**
    - Fetches user profile
    - Updates profile data
    - Avatar upload
    - Validates changes
  - **Tests:**
    - Unit tests
    - Integration tests
    - Validation tests
  - **Effort:** 5 hours

- [ ] **Task 3.4:** Implement `LocationService`
  - **Acceptance Criteria:**
    - Manages user locations
    - ZIP auto-complete
    - Geocoding for city/state
    - Validates ZIPs
  - **Tests:**
    - Unit tests
    - Integration tests with geocoding API
  - **Effort:** 5 hours

- [ ] **Task 3.5:** Implement `PrivacyService`
  - **Acceptance Criteria:**
    - Manages consent settings
    - Enforces privacy rules throughout app
    - Data anonymization enforcement
    - GDPR data export
    - Account deletion flow
  - **Tests:**
    - Unit tests for privacy logic
    - Integration tests
    - Privacy audit tests
  - **Effort:** 7 hours

- [ ] **Task 3.6:** Integrate subscription and billing (Stripe/RevenueCat)
  - **Acceptance Criteria:**
    - Subscription status fetching
    - Upgrade/downgrade flows
    - Payment processing
    - Receipt validation (iOS)
    - Promo code redemption
  - **Tests:**
    - Integration tests with billing service
    - Sandbox testing
    - Subscription state tests
  - **Effort:** 8 hours

- [ ] **Task 3.7:** Implement feature gating system
  - **Acceptance Criteria:**
    - Checks subscription tier
    - Gates premium features
    - Shows upgrade prompts
    - Handles tier changes
  - **Tests:**
    - Unit tests for gating logic
    - Integration tests
  - **Effort:** 4 hours

- [ ] **Task 3.8:** Create `ProfileRepository`
  - **Acceptance Criteria:**
    - Repository pattern for data access
    - Caching for profile data
    - Syncs changes to backend
  - **Tests:**
    - Unit tests with mock API
    - Integration tests
    - Caching tests
  - **Effort:** 5 hours

- [ ] **Task 3.9:** Implement connected bills management
  - **Acceptance Criteria:**
    - Lists user's bills
    - Syncs bill status
    - Handles bill deletion
    - Auto-import setup (future)
  - **Tests:**
    - Unit tests
    - Integration tests
  - **Effort:** 4 hours

**Phase 3 Acceptance Criteria:**
- ✅ Authentication robust and secure
- ✅ Privacy controls enforced
- ✅ Subscription system functional
- ✅ All services tested (85%+ coverage)

---

## 🔌 Phase 4: Integration & Data Flow

**Goal:** Connect profile UI to backend services

### Tasks

- [ ] **Task 4.1:** Integrate ProfileViewModel with ProfileView
  - **Acceptance Criteria:**
    - View reactively updates with ViewModel
    - Profile edits sync
    - Settings changes persist
  - **Tests:**
    - Integration tests for full flow
    - UI tests for state transitions
  - **Effort:** 4 hours

- [ ] **Task 4.2:** Implement profile API client
  - **Acceptance Criteria:**
    - All profile endpoints working
    - Proper authentication headers
    - Error handling
  - **Tests:**
    - Integration tests with backend
    - Mock server tests
  - **Effort:** 4 hours

- [ ] **Task 4.3:** Implement real-time profile sync
  - **Acceptance Criteria:**
    - Profile updates sync across devices
    - Conflict resolution for concurrent edits
    - Optimistic UI updates
  - **Tests:**
    - Integration tests for sync
    - Multi-device tests
  - **Effort:** 5 hours

- [ ] **Task 4.4:** Implement phone and email verification flows
  - **Acceptance Criteria:**
    - OTP sent and validated
    - Verification status updated
    - Retry mechanism
  - **Tests:**
    - Integration tests for verification
    - UI tests for flows
  - **Effort:** 5 hours

- [ ] **Task 4.5:** Integrate billing and subscription management
  - **Acceptance Criteria:**
    - Upgrade flow triggers payment
    - Receipt validation completes
    - Subscription status updates
    - Cancellation works
  - **Tests:**
    - Integration tests with Stripe/RevenueCat
    - Sandbox purchase tests
  - **Effort:** 6 hours

- [ ] **Task 4.6:** Implement privacy data export
  - **Acceptance Criteria:**
    - User requests export
    - Backend generates data package
    - User receives download link
    - Format complies with GDPR
  - **Tests:**
    - Integration tests for export
    - Data completeness tests
  - **Effort:** 5 hours

- [ ] **Task 4.7:** Implement account deletion
  - **Acceptance Criteria:**
    - Confirmation dialog
    - Deletion request sent to backend
    - Data deletion initiated
    - User logged out
  - **Tests:**
    - Integration tests for deletion
    - Data removal verification
  - **Effort:** 4 hours

- [ ] **Task 4.8:** Implement error handling and recovery
  - **Acceptance Criteria:**
    - Network errors handled
    - Auth errors trigger re-login
    - Validation errors shown inline
  - **Tests:**
    - Integration tests for error scenarios
  - **Effort:** 3 hours

**Phase 4 Acceptance Criteria:**
- ✅ Full profile flow working end-to-end
- ✅ Verification flows functional
- ✅ Billing integration working
- ✅ All integration tests passing

---

## ✅ Phase 5: Testing & Quality Assurance

**Goal:** Ensure profile security and reliability

### Tasks

- [ ] **Task 5.1:** Security testing for authentication
  - **Acceptance Criteria:**
    - OTP cannot be brute-forced
    - Session tokens secure
    - Biometric auth properly integrated
    - No auth bypass vulnerabilities
  - **Tests:**
    - Security audit
    - Penetration testing
  - **Effort:** 6 hours

- [ ] **Task 5.2:** Privacy compliance testing
  - **Acceptance Criteria:**
    - GDPR compliance verified
    - CCPA compliance verified
    - Data export contains all user data
    - Deletion removes all PII
  - **Tests:**
    - Privacy audit
    - Data completeness tests
  - **Effort:** 6 hours

- [ ] **Task 5.3:** Subscription and billing testing
  - **Acceptance Criteria:**
    - All purchase flows tested
    - Subscription state transitions tested
    - Cancellation and refunds tested
    - Receipt validation robust
  - **Tests:**
    - Integration tests with sandbox
    - Edge case tests
  - **Effort:** 6 hours

- [ ] **Task 5.4:** Write unit tests for ProfileViewModel
  - **Acceptance Criteria:**
    - 90%+ code coverage
    - All validation logic tested
    - State transitions tested
  - **Tests:** Run unit test suite
  - **Effort:** 5 hours

- [ ] **Task 5.5:** Write integration tests for profile service
  - **Acceptance Criteria:**
    - All CRUD operations tested
    - Sync logic tested
    - Error scenarios covered
  - **Tests:** Run integration test suite
  - **Effort:** 5 hours

- [ ] **Task 5.6:** Write UI tests for profile flows
  - **Acceptance Criteria:**
    - Edit profile tested
    - Settings changes tested
    - Verification flows tested
    - Subscription upgrade tested
  - **Tests:** Run UI test suite
  - **Effort:** 6 hours

- [ ] **Task 5.7:** Performance testing
  - **Acceptance Criteria:**
    - Profile loads in < 1 second
    - Settings updates instant
    - No memory leaks
  - **Tests:**
    - Instruments profiling
    - Performance benchmarks
  - **Effort:** 3 hours

- [ ] **Task 5.8:** Accessibility testing
  - **Acceptance Criteria:**
    - All settings accessible
    - Forms navigable with VoiceOver
    - Toggles properly labeled
  - **Tests:**
    - Accessibility audit
    - Manual VoiceOver testing
  - **Effort:** 3 hours

**Phase 5 Acceptance Criteria:**
- ✅ Security audit passed
- ✅ Privacy compliance verified
- ✅ All tests passing
- ✅ Performance benchmarks met

---

## 💎 Phase 6: Polish & Optimization

**Goal:** Make profile management seamless

### Tasks

- [ ] **Task 6.1:** Add profile animations
  - **Acceptance Criteria:**
    - Avatar upload animation
    - Settings toggle animations
    - Success feedback animations
    - Haptic feedback
  - **Tests:**
    - Manual testing
    - Performance with animations
  - **Effort:** 4 hours

- [ ] **Task 6.2:** Implement smart verification suggestions
  - **Acceptance Criteria:**
    - Prompt to verify phone if not done
    - Explain benefits of verification
    - Remind at appropriate times
  - **Tests:**
    - UI tests
    - User testing
  - **Effort:** 3 hours

- [ ] **Task 6.3:** Add subscription upgrade prompts
  - **Acceptance Criteria:**
    - Contextual upgrade suggestions
    - Show value of premium features
    - Clear pricing and benefits
    - Easy to dismiss
  - **Tests:**
    - UI tests
    - A/B testing for messaging
  - **Effort:** 5 hours

- [ ] **Task 6.4:** Implement smart location suggestions
  - **Acceptance Criteria:**
    - Suggest adding current location
    - Suggest future move ZIPs based on browsing
    - Moving checklist feature
  - **Tests:**
    - Integration tests
    - User testing
  - **Effort:** 4 hours

- [ ] **Task 6.5:** Add profile completion gamification
  - **Acceptance Criteria:**
    - Progress indicator for profile completion
    - Badges for milestones
    - Explain benefits of complete profile
  - **Tests:**
    - UI tests
    - User engagement metrics
  - **Effort:** 4 hours

- [ ] **Task 6.6:** Implement referral system (future)
  - **Acceptance Criteria:**
    - Generate referral codes
    - Track referrals
    - Reward for successful referrals
  - **Tests:**
    - Integration tests
  - **Effort:** 6 hours

- [ ] **Task 6.7:** Add advanced privacy controls
  - **Acceptance Criteria:**
    - Granular data sharing controls
    - Privacy dashboard showing usage
    - Data access logs
  - **Tests:**
    - Privacy audit
    - User testing
  - **Effort:** 5 hours

- [ ] **Task 6.8:** Optimize for large accounts
  - **Acceptance Criteria:**
    - Efficient loading for many bills
    - Pagination where needed
    - Smooth performance
  - **Tests:**
    - Performance tests with large datasets
  - **Effort:** 3 hours

**Phase 6 Acceptance Criteria:**
- ✅ Profile management delightful
- ✅ Upgrade prompts effective
- ✅ Privacy controls comprehensive
- ✅ Performance optimized

---

## 📚 Phase 7: Documentation & Handoff

**Goal:** Complete profile documentation

### Tasks

- [ ] **Task 7.1:** Document authentication system
  - **Acceptance Criteria:**
    - Auth flow diagrams
    - Security measures documented
    - OTP implementation explained
  - **Tests:** Technical review
  - **Effort:** 4 hours

- [ ] **Task 7.2:** Document privacy system
  - **Acceptance Criteria:**
    - Privacy controls explained
    - GDPR compliance documented
    - Data handling policies
  - **Tests:** Legal review
  - **Effort:** 4 hours

- [ ] **Task 7.3:** Document subscription system
  - **Acceptance Criteria:**
    - Billing integration guide
    - Feature gating logic
    - Subscription state machine
  - **Tests:** Developer walkthrough
  - **Effort:** 4 hours

- [ ] **Task 7.4:** Write user documentation for profile
  - **Acceptance Criteria:**
    - How to edit profile
    - How to manage privacy
    - How to upgrade subscription
  - **Tests:** User testing
  - **Effort:** 3 hours

- [ ] **Task 7.5:** Document API endpoints
  - **Acceptance Criteria:**
    - All profile endpoints
    - Authentication requirements
    - Error codes
  - **Tests:** API documentation review
  - **Effort:** 3 hours

- [ ] **Task 7.6:** Create support documentation
  - **Acceptance Criteria:**
    - FAQ for profile issues
    - Troubleshooting guides
    - Contact support flows
  - **Tests:** Support team review
  - **Effort:** 3 hours

- [ ] **Task 7.7:** Document analytics events
  - **Acceptance Criteria:**
    - All profile events listed
    - Subscription funnel tracking
  - **Tests:** Analytics validation
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

- **Profile Completion:** 80%+ of users complete profile
- **Verification Rate:** 70%+ verify phone/email
- **Subscription Conversion:** 15%+ convert to premium
- **Privacy Awareness:** 90%+ understand data controls
- **Support Tickets:** < 2% related to profile issues
- **Session Security:** 0 auth breaches

---

## 🔗 Dependencies

- Backend profile API
- Authentication service (OTP, biometrics)
- Billing service (Stripe/RevenueCat)
- Geocoding API for locations
- Analytics service
- Email/SMS service for verification

---

## 📅 Estimated Timeline

- **Phase 1:** 39 hours (5 days)
- **Phase 2:** 39 hours (5 days)
- **Phase 3:** 52 hours (6-7 days)
- **Phase 4:** 36 hours (4-5 days)
- **Phase 5:** 40 hours (5 days)
- **Phase 6:** 34 hours (4-5 days)
- **Phase 7:** 26 hours (3 days)

**Total Estimated Effort:** 266 hours (~6-7 weeks for one developer)

---

## 🚀 Next Steps

1. Review and approve Phase 1 plan
2. Select billing provider (Stripe vs RevenueCat)
3. Set up authentication infrastructure
4. Legal review of privacy controls
5. Begin Phase 1 Task 1.1: Profile screen wireframes
