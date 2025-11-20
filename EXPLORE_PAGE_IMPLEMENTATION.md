# Billix iOS Explore Page Implementation Plan

## Overview
This document outlines the phased implementation plan for building an engaging, addictive Explore page for the Billix iOS app. The page will display both Bills Marketplace and Housing Marketplace data from the LAW_4_ME backend.

**Backend Repository**: [LAW_4_ME](https://github.com/Overtaked00/LAW_4_ME)
**Architecture**: MVVM (Model-View-ViewModel)
**UI Framework**: SwiftUI
**Database**: Supabase
**Estimated Timeline**: 6-8 weeks

## Key Decisions

### Navigation Structure
✅ **SEPARATE TABS** for Bills and Housing (Industry Best Practice)
- Different use cases (recurring utilities vs major housing decisions)
- Different mental models and user intent
- Prevents UI clutter
- Matches successful apps (Zillow, Airbnb, Facebook Marketplace)

### API Endpoints (v1 for iOS Stability)

**Bills Marketplace**:
- `GET /api/v1/marketplace/` - List bills marketplace data
  - Query params: `zip_prefix`, `category`, `sort`

**Housing Marketplace**:
- `GET /api/v1/housing-market/` - Main market data
  - Query params: `zipCode` OR (`city` + `state`), `propertyType`, `bedrooms`
- `GET /api/v1/housing-market/rent-estimate/` - Property rent estimates
  - Query params: `address` OR (`latitude` + `longitude`)
- `GET /api/v1/housing-market/trends/` - Historical trends
  - Query params: `zipCode`, `propertyType`, `months` (6, 12, or 60)
- `GET /api/v1/housing-market/compare/` - Multi-market comparison
- `GET /api/v1/housing-market/listings/` - Comparable listings

---

## Phase 1: Foundation & Network Layer
**Goal**: Set up project structure, API configuration, and data models
**Duration**: 3-4 days

### Tasks
- [ ] Create folder structure following MVVM pattern
  ```
  Billix/
  ├── Features/
  │   ├── Explore/
  │   │   ├── Views/
  │   │   │   ├── BillsExploreView.swift
  │   │   │   ├── HousingExploreView.swift
  │   │   │   └── ExploreTabView.swift
  │   │   ├── ViewModels/
  │   │   │   ├── BillsExploreViewModel.swift
  │   │   │   └── HousingExploreViewModel.swift
  │   │   ├── Models/
  │   │   │   ├── MarketplaceBill.swift
  │   │   │   ├── MarketplaceData.swift
  │   │   │   ├── HousingMarketData.swift
  │   │   │   └── RentEstimate.swift
  │   │   └── Services/
  │   │       ├── MarketplaceService.swift
  │   │       └── HousingMarketService.swift
  ├── Core/
  │   ├── Network/
  │   │   ├── APIClient.swift
  │   │   ├── APIEndpoint.swift
  │   │   └── NetworkError.swift
  │   ├── Cache/
  │   │   ├── CacheManager.swift
  │   │   ├── MemoryCache.swift
  │   │   └── DiskCache.swift
  │   └── Extensions/
  │       └── Date+Extensions.swift
  └── Resources/
      └── APIConfig.swift
  ```

- [ ] Create `APIConfig.swift` with base URL and v1 endpoints
- [ ] Build `APIClient.swift` with async/await networking
- [ ] Create data models matching API responses
- [ ] Implement three-tier caching strategy
- [ ] Create service layer
- [ ] Add network error handling

**Completion Criteria**:
- All models decode successfully from sample API responses
- API client can make authenticated requests to v1 endpoints
- Caching layer stores and retrieves data correctly
- Unit tests pass for network layer (>80% coverage)

---

## Phase 2: Bills Explore UI - Core Views
**Goal**: Build the Bills Marketplace tab with card-based layout
**Duration**: 5-6 days

### Tasks
- [ ] Create `BillsExploreView.swift` - Main container
- [ ] Build `BillsStatsHeaderView.swift` - Live statistics dashboard
- [ ] Create `BillsFilterBarView.swift` - Filter controls
- [ ] Build `BillMarketplaceCard.swift` - Individual bill card
- [ ] Implement `BillsGridView.swift` - Scrollable grid layout
- [ ] Create `BillsExploreViewModel.swift` - Business logic
- [ ] Add microinteractions

**Completion Criteria**:
- Grid displays 2 columns of cards smoothly
- Filters apply correctly and update UI
- Infinite scroll loads next page seamlessly
- Pull-to-refresh updates data

---

## Phase 3: Bills Explore UI - Detail Sheet
**Goal**: Build the detailed bill view modal
**Duration**: 4-5 days

### Tasks
- [ ] Create `BillDetailSheet.swift` - Bottom sheet modal
- [ ] Build `PricingStatisticsView.swift` - Detailed pricing breakdown
- [ ] Create `UsageMetricsView.swift` - Usage statistics
- [ ] Build `PriceDistributionChart.swift` - Visual data representation
- [ ] Add `SampleSizeIndicator.swift` - Social proof component
- [ ] Create `RelatedBillsView.swift` - "Similar in your area" section
- [ ] Add action buttons (Share, Save, Report)

**Completion Criteria**:
- Sheet presents smoothly with spring animation
- All charts render correctly and are interactive
- Data displays accurately match API response

---

## Phase 4: Housing Explore UI - Core Views
**Goal**: Build the Housing Marketplace tab with search and map integration
**Duration**: 6-7 days

### Tasks
- [ ] Create `HousingExploreView.swift` - Main container
- [ ] Build `HousingSearchBar.swift` - Location search
- [ ] Create `HousingFilterSheet.swift` - Advanced filters
- [ ] Build `HousingMarketCard.swift` - Market statistics card
- [ ] Implement `HousingMapView.swift` - Interactive map
- [ ] Create `HousingDetailView.swift` - Detailed market view
- [ ] Build `MarketTrendsChart.swift` - Historical trends visualization
- [ ] Create `ComparablesListView.swift` - Similar properties
- [ ] Build `MarketCompareView.swift` - Multi-market comparison
- [ ] Create `HousingExploreViewModel.swift` - Business logic

**Completion Criteria**:
- Search finds markets by ZIP and city/state
- Map displays market annotations correctly
- Trends charts load and display historical data

---

## Phase 5: Gamification & Engagement
**Goal**: Add addictive features to increase time spent
**Duration**: 4-5 days

### Tasks
- [ ] Create `GamificationManager.swift` - Points and achievements system
- [ ] Define point-earning actions
- [ ] Create achievement badges
- [ ] Build `ProgressHeaderView.swift` - User progress display
- [ ] Create `AchievementToastView.swift` - Achievement unlock notification
- [ ] Build `AchievementsView.swift` - Full achievements screen
- [ ] Add personalization features
- [ ] Implement social proof elements
- [ ] Create FOMO triggers

**Completion Criteria**:
- Points accumulate correctly for all actions
- Achievement unlocks trigger toast notifications
- Recommendations are personalized to user's ZIP

---

## Phase 6: Microinteractions & Polish
**Goal**: Add delightful animations and haptic feedback
**Duration**: 3-4 days

### Tasks
- [ ] Implement haptic feedback
- [ ] Add card animations
- [ ] Create loading states
- [ ] Build pull-to-refresh animations
- [ ] Add chart animations
- [ ] Create sheet presentation animations
- [ ] Add filter animations
- [ ] Implement scroll-based effects
- [ ] Add empty state animations

**Completion Criteria**:
- All interactions feel smooth and responsive
- Animations run at 60 fps on target devices

---

## Phase 7: Performance Optimization
**Goal**: Ensure smooth scrolling and fast data loading
**Duration**: 3-4 days

### Tasks
- [ ] Optimize image loading
- [ ] Improve list/grid performance
- [ ] Optimize data fetching
- [ ] Memory management
- [ ] Reduce app bundle size
- [ ] Database query optimization
- [ ] Network optimization
- [ ] Rendering optimization

**Completion Criteria**:
- App maintains 60 fps during scroll
- Memory usage stays under 150 MB
- App launch time <2 seconds

---

## Phase 8: Accessibility & Dark Mode
**Goal**: Support all users and system preferences
**Duration**: 3-4 days

### Tasks
- [ ] VoiceOver support
- [ ] Dynamic Type support
- [ ] Reduce Motion support
- [ ] Color Contrast
- [ ] Dark Mode implementation
- [ ] Localization preparation
- [ ] Keyboard navigation

**Completion Criteria**:
- VoiceOver can navigate entire app
- All colors meet WCAG AA contrast standards
- Dark Mode looks polished and intentional

---

## Phase 9: Testing & Quality Assurance
**Goal**: Ensure reliability and catch bugs
**Duration**: 4-5 days

### Tasks
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] UI tests with XCUITest
- [ ] Manual QA testing
- [ ] Performance testing
- [ ] Security testing
- [ ] Beta testing

**Completion Criteria**:
- Unit test coverage >80%
- Zero crashes in 100 manual test sessions
- Beta testers report positive experience

---

## Phase 10: Analytics, Monitoring & Launch Prep
**Goal**: Instrument tracking and prepare for App Store
**Duration**: 3-4 days

### Tasks
- [ ] Analytics implementation
- [ ] Key metrics to track
- [ ] Crash reporting
- [ ] App Store preparation
- [ ] Compliance & Legal
- [ ] Launch checklist
- [ ] Post-launch monitoring

**Completion Criteria**:
- Analytics tracking all key events
- App Store listing complete and compelling
- App submitted to App Store review

---

## Success Metrics

### User Engagement
- **Average session duration**: >3 minutes
- **Cards viewed per session**: >10
- **Detail sheet open rate**: >30%
- **Return rate (Day 1)**: >40%
- **Return rate (Day 7)**: >20%

### Performance
- **App launch time**: <2 seconds
- **List scroll performance**: 60 fps
- **Crash-free rate**: >99.5%

---

## Timeline Summary

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Foundation & Network Layer | 3-4 days | 4 days |
| Phase 2: Bills Explore UI - Core Views | 5-6 days | 10 days |
| Phase 3: Bills Explore UI - Detail Sheet | 4-5 days | 15 days |
| Phase 4: Housing Explore UI - Core Views | 6-7 days | 22 days |
| Phase 5: Gamification & Engagement | 4-5 days | 27 days |
| Phase 6: Microinteractions & Polish | 3-4 days | 31 days |
| Phase 7: Performance Optimization | 3-4 days | 35 days |
| Phase 8: Accessibility & Dark Mode | 3-4 days | 39 days |
| Phase 9: Testing & QA | 4-5 days | 44 days |
| Phase 10: Analytics & Launch Prep | 3-4 days | 48 days |

**Total Estimated Duration**: 6-8 weeks (48 working days)
