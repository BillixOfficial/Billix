# Explore Screen - "Marketplace & Discovery"

**Purpose:** Let people shop bills like they'd browse Zillow or StockX. Discover bill pricing in their area, compare to peers, and find savings opportunities.

---

## 🎯 Phase 1: Design & Planning

**Goal:** Define marketplace architecture, filtering system, and TruePrice™ comparison logic

### Tasks

- [ ] **Task 1.1:** Create UI/UX wireframes for marketplace
  - **Acceptance Criteria:**
    - High-fidelity mockups for browse, filter, and detail views
    - Mobile and tablet layouts
    - Dark mode variants
    - Loading, empty, and error states
    - Filter panel designs (slide-up modal on iOS)
  - **Tests:** Manual design review and user testing
  - **Effort:** 5 hours

- [ ] **Task 1.2:** Define data models for marketplace
  - **Acceptance Criteria:**
    - `MarketplaceListing` model (provider, plan, price, peerCount, badges)
    - `BillComparison` model (userBill, marketAverage, deviation, savings)
    - `PriceT

rend` model (historical data, moving averages)
    - `Filter` model (billType, location, priceRange, badges)
    - All models Codable and Identifiable
  - **Tests:**
    - Unit tests for model initialization
    - Unit tests for comparison calculations
    - Unit tests for filtering logic
  - **Effort:** 4 hours

- [ ] **Task 1.3:** Design TruePrice™ marketplace algorithm
  - **Acceptance Criteria:**
    - Statistical method for calculating market average
    - Outlier detection and removal
    - Confidence intervals for prices
    - Minimum sample size requirements (e.g., 30 bills)
    - Weighted by recency and verification status
  - **Tests:**
    - Unit tests with known datasets
    - Statistical validation tests
    - Edge case tests (low sample size, high variance)
  - **Effort:** 6 hours

- [ ] **Task 1.4:** Define anonymization and privacy rules
  - **Acceptance Criteria:**
    - No personally identifiable information exposed
    - Aggregation thresholds defined (min 10 users per listing)
    - Data retention policies specified
    - User consent flow documented
  - **Tests:**
    - Privacy audit checklist
    - Data anonymization tests
  - **Effort:** 4 hours

- [ ] **Task 1.5:** Design filtering and search system
  - **Acceptance Criteria:**
    - Bill type filters (Internet, Mobile, Power, etc.)
    - Location filters (ZIP, City, State with auto-complete)
    - Sort options (Cheapest, Best perks, Most verified, Similar to you)
    - Multi-select filter UI
    - Clear all filters option
  - **Tests:**
    - Unit tests for filter combinations
    - UI tests for filter interactions
  - **Effort:** 4 hours

- [ ] **Task 1.6:** Define badge system
  - **Acceptance Criteria:**
    - "Billix-Verified" badge (user-submitted, receipts checked)
    - "Promo Likely" badge (ML prediction)
    - "Fee-Heavy" badge (high fee-to-price ratio)
    - Badge criteria clearly defined
    - Badge icon designs
  - **Tests:**
    - Unit tests for badge assignment logic
    - Visual tests for badge rendering
  - **Effort:** 3 hours

- [ ] **Task 1.7:** Design API contracts for marketplace endpoints
  - **Acceptance Criteria:**
    - GET `/marketplace/listings` with filter params
    - GET `/marketplace/listings/:id` for detail
    - GET `/marketplace/compare` for user vs market
    - POST `/marketplace/verify` for bill verification
    - Pagination support
  - **Tests:**
    - Unit tests for DTO mapping
    - Mock API implementation
  - **Effort:** 4 hours

- [ ] **Task 1.8:** Create navigation and deep linking specs
  - **Acceptance Criteria:**
    - Deep links to specific bill types
    - Deep links to location-based results
    - Deep links to individual listings
    - Share URLs for listings
  - **Tests:**
    - Integration tests for deep links
  - **Effort:** 3 hours

- [ ] **Task 1.9:** Define analytics events for marketplace
  - **Acceptance Criteria:**
    - Browse events (filter applied, sort changed)
    - Interaction events (listing tapped, compare clicked)
    - Conversion events (bill uploaded after browse)
  - **Tests:** Analytics implementation validation
  - **Effort:** 2 hours

**Phase 1 Acceptance Criteria:**
- ✅ All marketplace designs approved
- ✅ TruePrice™ algorithm validated
- ✅ Privacy rules signed off by legal/compliance
- ✅ API contracts defined

---

## 🏗️ Phase 2: Core UI Components

**Goal:** Build marketplace browsing and filtering UI

### Tasks

- [ ] **Task 2.1:** Create `FilterChipBar` component
  - **Acceptance Criteria:**
    - Horizontal scrollable chip bar
    - Bill type chips (Internet, Mobile, Power, etc.)
    - Active state styling
    - Multi-select support
    - Accessibility labels
  - **Tests:**
    - UI tests for selection
    - Snapshot tests for all states
    - Accessibility tests
  - **Effort:** 3 hours

- [ ] **Task 2.2:** Create `LocationFilterView` component
  - **Acceptance Criteria:**
    - Auto-complete search for ZIP/City
    - Current location detection
    - Recently searched locations
    - Clear and apply actions
  - **Tests:**
    - UI tests for search
    - Unit tests for auto-complete logic
    - Snapshot tests
  - **Effort:** 5 hours

- [ ] **Task 2.3:** Create `SortPickerView` component
  - **Acceptance Criteria:**
    - Sort options: Cheapest, Best perks, Most verified, Similar to you
    - Radio button selection
    - Bottom sheet presentation on iOS
  - **Tests:**
    - UI tests for selection
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 2 hours

- [ ] **Task 2.4:** Create `MarketplaceListingCard` component
  - **Acceptance Criteria:**
    - Provider name and plan nickname
    - Effective monthly cost with fees
    - TruePrice™ comparison indicator
    - Peer count ("Based on 37 bills")
    - Badges displayed (Verified, Promo, Fee-heavy)
    - Tap to view details
  - **Tests:**
    - UI tests for navigation
    - Snapshot tests for all badge combinations
    - Unit tests for price formatting
    - Accessibility tests
  - **Effort:** 6 hours

- [ ] **Task 2.5:** Create `PriceComparisonBar` component
  - **Acceptance Criteria:**
    - Visual bar showing user price vs market
    - Color-coded (green if under, red if over)
    - Savings/overspend amount
    - Animated fill on appear
  - **Tests:**
    - UI tests for animation
    - Snapshot tests for different comparisons
    - Unit tests for calculation
  - **Effort:** 4 hours

- [ ] **Task 2.6:** Create `TrendChartView` component
  - **Acceptance Criteria:**
    - Line chart for price trends over 12 months
    - Touch to see specific data points
    - Smooth animations
    - Responsive to data ranges
  - **Tests:**
    - UI tests for interaction
    - Snapshot tests
    - Unit tests for data transformation
  - **Effort:** 6 hours

- [ ] **Task 2.7:** Create `BadgeView` component
  - **Acceptance Criteria:**
    - Different styles for each badge type
    - Tooltip on tap explaining badge
    - Consistent sizing
  - **Tests:**
    - UI tests for tooltip
    - Snapshot tests for all badge types
    - Accessibility tests
  - **Effort:** 3 hours

- [ ] **Task 2.8:** Create `EmptyMarketplaceView` component
  - **Acceptance Criteria:**
    - Friendly message for no results
    - Suggestions to adjust filters
    - Option to be first to share in area
  - **Tests:**
    - UI tests for CTAs
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 2 hours

- [ ] **Task 2.9:** Create `CollectionCardView` for curated lists
  - **Acceptance Criteria:**
    - "Starter pack" collections
    - "Biggest overpaid bills" editorial
    - Thumbnail grid preview
    - Tap to browse collection
  - **Tests:**
    - UI tests for navigation
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.10:** Implement infinite scroll for listings
  - **Acceptance Criteria:**
    - Paginated loading
    - Loading indicator at bottom
    - Smooth scroll performance
  - **Tests:**
    - UI tests for pagination
    - Performance tests for scroll
  - **Effort:** 3 hours

**Phase 2 Acceptance Criteria:**
- ✅ All marketplace UI components built
- ✅ Filtering and sorting UI functional
- ✅ Visual regression tests passing
- ✅ Accessibility audit passed

---

## ⚙️ Phase 3: Business Logic & Data Layer

**Goal:** Implement marketplace services, filtering logic, and TruePrice™ calculations

### Tasks

- [ ] **Task 3.1:** Create `ExploreViewModel` with Combine
  - **Acceptance Criteria:**
    - Manages listings state
    - Handles filter and sort updates
    - Pagination state management
    - Loading, loaded, error states
  - **Tests:**
    - Unit tests for state management
    - Unit tests for filter logic
    - Memory leak tests
  - **Effort:** 6 hours

- [ ] **Task 3.2:** Implement `MarketplaceService`
  - **Acceptance Criteria:**
    - Fetches listings with filters
    - Implements pagination
    - Caches recent results
    - Handles errors gracefully
  - **Tests:**
    - Unit tests with mock repository
    - Integration tests
    - Caching behavior tests
  - **Effort:** 5 hours

- [ ] **Task 3.3:** Implement `TruePriceEngine`
  - **Acceptance Criteria:**
    - Calculates market average from bills
    - Removes statistical outliers
    - Weights by recency and verification
    - Returns confidence intervals
  - **Tests:**
    - Unit tests with known datasets
    - Statistical validation tests
    - Edge case tests
  - **Effort:** 7 hours

- [ ] **Task 3.4:** Implement `FilterEngine`
  - **Acceptance Criteria:**
    - Combines multiple filter criteria
    - Efficient filtering algorithm
    - Smart defaults based on user profile
  - **Tests:**
    - Unit tests for all filter combinations
    - Performance tests with large datasets
  - **Effort:** 4 hours

- [ ] **Task 3.5:** Implement `ComparisonService`
  - **Acceptance Criteria:**
    - Compares user bill to market
    - Calculates savings potential
    - Identifies similar users for comparison
  - **Tests:**
    - Unit tests for comparison logic
    - Integration tests
  - **Effort:** 4 hours

- [ ] **Task 3.6:** Implement `BadgeAssignmentService`
  - **Acceptance Criteria:**
    - Assigns badges based on criteria
    - ML integration for "Promo Likely" prediction
    - Verification workflow for Billix-Verified
  - **Tests:**
    - Unit tests for badge logic
    - Integration tests for verification flow
  - **Effort:** 5 hours

- [ ] **Task 3.7:** Implement `LocationService`
  - **Acceptance Criteria:**
    - Geocoding for ZIP/City
    - Auto-complete suggestions
    - Distance-based filtering
  - **Tests:**
    - Unit tests for geocoding
    - Integration tests with maps API
  - **Effort:** 4 hours

- [ ] **Task 3.8:** Create `MarketplaceRepository`
  - **Acceptance Criteria:**
    - Repository pattern for data access
    - Implements caching strategy
    - Offline support with cached listings
  - **Tests:**
    - Unit tests with mock API
    - Integration tests
    - Caching tests
  - **Effort:** 5 hours

- [ ] **Task 3.9:** Implement anonymization layer
  - **Acceptance Criteria:**
    - Strips PII before aggregation
    - Enforces minimum group sizes
    - Audit logging for data access
  - **Tests:**
    - Unit tests for anonymization
    - Privacy compliance tests
  - **Effort:** 5 hours

**Phase 3 Acceptance Criteria:**
- ✅ TruePrice™ engine validated
- ✅ All services tested (85%+ coverage)
- ✅ Filtering and comparison logic working
- ✅ Privacy compliance verified

---

## 🔌 Phase 4: Integration & Data Flow

**Goal:** Connect marketplace UI to backend and ensure smooth data flow

### Tasks

- [ ] **Task 4.1:** Integrate ExploreViewModel with ExploreView
  - **Acceptance Criteria:**
    - View reactively updates with ViewModel
    - Filter changes trigger data refresh
    - Sort changes update UI
    - Pagination triggers on scroll
  - **Tests:**
    - Integration tests for full flow
    - UI tests for state transitions
  - **Effort:** 4 hours

- [ ] **Task 4.2:** Implement marketplace API client
  - **Acceptance Criteria:**
    - RESTful endpoints implemented
    - Filter parameters serialized correctly
    - Pagination headers handled
    - Rate limiting respected
  - **Tests:**
    - Integration tests with test backend
    - Mock server tests
  - **Effort:** 5 hours

- [ ] **Task 4.3:** Implement real-time price updates
  - **Acceptance Criteria:**
    - Prices update as new bills added
    - WebSocket or polling for updates
    - Optimistic UI updates
  - **Tests:**
    - Integration tests for real-time updates
    - UI tests for optimistic updates
  - **Effort:** 5 hours

- [ ] **Task 4.4:** Implement search and auto-complete
  - **Acceptance Criteria:**
    - Debounced search input
    - Fast auto-complete results
    - Search history saved
  - **Tests:**
    - Integration tests for search
    - Performance tests for auto-complete
  - **Effort:** 4 hours

- [ ] **Task 4.5:** Implement comparison flow
  - **Acceptance Criteria:**
    - User can compare their bill to listing
    - Shows detailed breakdown
    - Suggests actions
  - **Tests:**
    - Integration tests for comparison
    - UI tests for flow
  - **Effort:** 4 hours

- [ ] **Task 4.6:** Implement share functionality
  - **Acceptance Criteria:**
    - Share listing via deep link
    - Generate shareable image
    - Track shares in analytics
  - **Tests:**
    - Integration tests for sharing
    - UI tests for share sheet
  - **Effort:** 3 hours

- [ ] **Task 4.7:** Implement favorites/bookmarks
  - **Acceptance Criteria:**
    - User can save favorite listings
    - Syncs across devices
    - Quick access to favorites
  - **Tests:**
    - Integration tests for sync
    - UI tests for favorites
  - **Effort:** 4 hours

- [ ] **Task 4.8:** Implement error handling and retry
  - **Acceptance Criteria:**
    - Network errors handled gracefully
    - Auto-retry with exponential backoff
    - Fallback to cached data
  - **Tests:**
    - Integration tests for error scenarios
    - UI tests for error states
  - **Effort:** 3 hours

**Phase 4 Acceptance Criteria:**
- ✅ Full marketplace flow working
- ✅ Real-time updates functional
- ✅ Search and filtering performant
- ✅ All integration tests passing

---

## ✅ Phase 5: Testing & Quality Assurance

**Goal:** Comprehensive testing for marketplace reliability

### Tasks

- [ ] **Task 5.1:** Write unit tests for TruePrice™ algorithm
  - **Acceptance Criteria:**
    - 100% coverage on price calculation
    - Statistical edge cases tested
    - Outlier detection validated
  - **Tests:** Run unit test suite
  - **Effort:** 5 hours

- [ ] **Task 5.2:** Write unit tests for filtering logic
  - **Acceptance Criteria:**
    - All filter combinations tested
    - Performance with large datasets
    - Edge cases covered
  - **Tests:** Run unit test suite
  - **Effort:** 4 hours

- [ ] **Task 5.3:** Write integration tests for marketplace service
  - **Acceptance Criteria:**
    - Full CRUD operations tested
    - Pagination tested
    - Error scenarios covered
  - **Tests:** Run integration test suite
  - **Effort:** 5 hours

- [ ] **Task 5.4:** Write UI tests for marketplace flows
  - **Acceptance Criteria:**
    - Browse and filter flow
    - Compare flow
    - Share flow
    - Empty and error states
  - **Tests:** Run UI test suite
  - **Effort:** 6 hours

- [ ] **Task 5.5:** Performance testing
  - **Acceptance Criteria:**
    - Listings load in < 2 seconds
    - Scroll at 60fps with 1000+ items
    - Filter changes instant (< 100ms)
  - **Tests:**
    - Instruments profiling
    - Performance benchmarks
  - **Effort:** 4 hours

- [ ] **Task 5.6:** Privacy compliance testing
  - **Acceptance Criteria:**
    - No PII exposed in listings
    - Anonymization verified
    - Aggregation thresholds enforced
  - **Tests:**
    - Privacy audit
    - Data sampling tests
  - **Effort:** 4 hours

- [ ] **Task 5.7:** Accessibility testing
  - **Acceptance Criteria:**
    - VoiceOver navigation works
    - Filters accessible
    - Charts have text alternatives
  - **Tests:**
    - Accessibility audit
    - Manual VoiceOver testing
  - **Effort:** 3 hours

- [ ] **Task 5.8:** Regression testing
  - **Acceptance Criteria:**
    - All tests still passing
    - No visual regressions
    - Performance maintained
  - **Tests:** Full test suite run
  - **Effort:** 3 hours

**Phase 5 Acceptance Criteria:**
- ✅ All tests passing (unit, integration, UI)
- ✅ Code coverage > 85%
- ✅ Performance benchmarks met
- ✅ Privacy audit passed

---

## 💎 Phase 6: Polish & Optimization

**Goal:** Refine marketplace UX and optimize for scale

### Tasks

- [ ] **Task 6.1:** Add marketplace animations
  - **Acceptance Criteria:**
    - Card entrance animations
    - Filter panel slide-up animation
    - Price comparison fill animation
    - Haptic feedback on interactions
  - **Tests:**
    - Manual testing
    - Performance with animations
  - **Effort:** 5 hours

- [ ] **Task 6.2:** Implement smart caching strategy
  - **Acceptance Criteria:**
    - Cache recent searches
    - Prefetch likely next pages
    - Intelligent cache invalidation
  - **Tests:**
    - Integration tests for caching
    - Memory usage monitoring
  - **Effort:** 4 hours

- [ ] **Task 6.3:** Optimize listing images and logos
  - **Acceptance Criteria:**
    - Lazy loading for off-screen
    - Image compression
    - CDN integration
  - **Tests:**
    - Performance testing
    - Network usage monitoring
  - **Effort:** 3 hours

- [ ] **Task 6.4:** Implement predictive search
  - **Acceptance Criteria:**
    - ML-based search suggestions
    - Learns from user behavior
    - Instant results
  - **Tests:**
    - Integration tests
    - Performance tests
  - **Effort:** 6 hours

- [ ] **Task 6.5:** Add contextual help and tooltips
  - **Acceptance Criteria:**
    - Explain badges on tap
    - Tooltip for TruePrice™
    - First-time user guidance
  - **Tests:**
    - UI tests for tooltips
    - User testing
  - **Effort:** 3 hours

- [ ] **Task 6.6:** Implement personalized recommendations
  - **Acceptance Criteria:**
    - "Similar to you" sorting works
    - ML-based bill matching
    - Adapts to user preferences
  - **Tests:**
    - Integration tests
    - User acceptance testing
  - **Effort:** 6 hours

- [ ] **Task 6.7:** Optimize for iPad and large screens
  - **Acceptance Criteria:**
    - Multi-column layout on iPad
    - Filter panel as sidebar
    - Charts larger and more detailed
  - **Tests:**
    - UI tests on iPad
    - Visual regression tests
  - **Effort:** 5 hours

- [ ] **Task 6.8:** Add dark mode optimizations
  - **Acceptance Criteria:**
    - Charts readable in dark mode
    - Colors maintain contrast
    - Images adapt appropriately
  - **Tests:**
    - Visual testing in dark mode
    - Accessibility audit
  - **Effort:** 3 hours

**Phase 6 Acceptance Criteria:**
- ✅ Marketplace feels fast and responsive
- ✅ Personalization working effectively
- ✅ Beautiful on all device sizes
- ✅ Dark mode polished

---

## 📚 Phase 7: Documentation & Handoff

**Goal:** Complete marketplace documentation

### Tasks

- [ ] **Task 7.1:** Document TruePrice™ algorithm
  - **Acceptance Criteria:**
    - Formula fully explained
    - Statistical methods documented
    - Example calculations provided
  - **Tests:** Technical review
  - **Effort:** 4 hours

- [ ] **Task 7.2:** Write marketplace API documentation
  - **Acceptance Criteria:**
    - All endpoints documented
    - Filter parameters explained
    - Response schemas provided
  - **Tests:** API documentation review
  - **Effort:** 4 hours

- [ ] **Task 7.3:** Create privacy documentation
  - **Acceptance Criteria:**
    - Anonymization process explained
    - Data retention policies
    - User rights documented
  - **Tests:** Legal review
  - **Effort:** 3 hours

- [ ] **Task 7.4:** Write developer guide for marketplace
  - **Acceptance Criteria:**
    - How to add new bill types
    - How to add new filters
    - How to customize badges
  - **Tests:** Developer walkthrough
  - **Effort:** 3 hours

- [ ] **Task 7.5:** Create user documentation
  - **Acceptance Criteria:**
    - How to browse marketplace
    - How to use filters
    - Understanding TruePrice™
  - **Tests:** User testing
  - **Effort:** 3 hours

- [ ] **Task 7.6:** Document analytics events
  - **Acceptance Criteria:**
    - All marketplace events listed
    - Event parameters documented
  - **Tests:** Analytics validation
  - **Effort:** 2 hours

- [ ] **Task 7.7:** Create release notes
  - **Acceptance Criteria:**
    - Marketplace features highlighted
    - Known limitations
    - Future enhancements planned
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

- **Engagement:** 70%+ of users browse marketplace within first session
- **Discovery:** Users find 3+ relevant listings per search
- **Accuracy:** TruePrice™ within 5% of actual market average
- **Performance:** Listings load in < 2 seconds
- **Privacy:** 0 PII leaks in marketplace
- **Conversion:** 30%+ of browsers upload a bill for comparison

---

## 🔗 Dependencies

- Backend marketplace API
- TruePrice™ calculation service
- ML service for badge prediction
- Geocoding/maps API
- CDN for provider logos
- Analytics service

---

## 📅 Estimated Timeline

- **Phase 1:** 35 hours (4-5 days)
- **Phase 2:** 38 hours (5 days)
- **Phase 3:** 45 hours (5-6 days)
- **Phase 4:** 32 hours (4 days)
- **Phase 5:** 34 hours (4-5 days)
- **Phase 6:** 35 hours (4-5 days)
- **Phase 7:** 24 hours (3 days)

**Total Estimated Effort:** 243 hours (~6-7 weeks for one developer)

---

## 🚀 Next Steps

1. Review and approve Phase 1 plan
2. Begin Phase 1 Task 1.1: Marketplace wireframes
3. Validate TruePrice™ algorithm with data science team
4. Get privacy approval from legal/compliance
