# Health Screen - "Bill Health & Leak Detection"

**Purpose:** This is where the $5 paid value lives: deep, human-like insights into bill health, leak detection, and actionable recommendations.

---

## 🎯 Phase 1: Design & Planning

**Goal:** Define Bill Health algorithm, insight generation system, and action planning

### Tasks

- [ ] **Task 1.1:** Create UI/UX wireframes for Health Screen
  - **Acceptance Criteria:**
    - High-fidelity mockups for health score dashboard
    - Per-bill insight card designs
    - Action plan UI
    - Risk flag designs
    - Education section layouts
    - Dark mode variants
  - **Tests:** Manual design review and user testing
  - **Effort:** 5 hours

- [ ] **Task 1.2:** Define data models for Bill Health
  - **Acceptance Criteria:**
    - `BillHealthScore` model (overall score, breakdown, trend)
    - `BillInsight` model (bill, summary, details, confidence)
    - `ActionPlan` model (recommendations, priority, effort)
    - `RiskFlag` model (type, severity, description)
    - `BillLiteracy` model (tips, explanations, links)
    - All models Codable and Identifiable
  - **Tests:**
    - Unit tests for model initialization
    - Unit tests for score calculations
  - **Effort:** 4 hours

- [ ] **Task 1.3:** Design Bill Health Score algorithm
  - **Acceptance Criteria:**
    - Multi-factor scoring (TruePrice deviation, fee anomalies, promo expiry, autopay risk)
    - Weighted formula documented
    - Score ranges defined (0-49 Poor, 50-79 Moderate, 80-100 Good)
    - Trend calculation (improving, stable, declining)
    - Per-bill sub-scores
  - **Tests:**
    - Unit tests with known scenarios
    - Statistical validation
    - Edge case tests
  - **Effort:** 7 hours

- [ ] **Task 1.4:** Design AI insight generation system
  - **Acceptance Criteria:**
    - LLM integration for human-like insights
    - Prompt templates for different scenarios
    - Insight categorization (price, fees, anomalies, opportunities)
    - Confidence scoring for insights
    - Fact-checking against TruePrice™ data
  - **Tests:**
    - Integration tests with LLM
    - Quality tests for insight relevance
  - **Effort:** 8 hours

- [ ] **Task 1.5:** Define leak detection rules
  - **Acceptance Criteria:**
    - Loyalty penalty detection (same plan, rising price)
    - Fee creep detection (new fees added)
    - Promo expiry detection
    - Autopay hiding price increases
    - Usage spike detection
    - Fraud/mistake patterns
  - **Tests:**
    - Unit tests for each detection rule
    - Accuracy tests with historical data
  - **Effort:** 6 hours

- [ ] **Task 1.6:** Design action plan generation
  - **Acceptance Criteria:**
    - Prioritized recommendations
    - Effort estimation (quick, medium, involved)
    - Savings estimation
    - Call script generation (future)
    - Timeline recommendations
  - **Tests:**
    - Unit tests for recommendation logic
    - User testing for clarity
  - **Effort:** 5 hours

- [ ] **Task 1.7:** Define Bill Literacy content system
  - **Acceptance Criteria:**
    - Curated tips library
    - Contextual education based on bills
    - Glossary of terms
    - Video/article content structure
  - **Tests:**
    - Content review
    - User comprehension testing
  - **Effort:** 4 hours

- [ ] **Task 1.8:** Design API contracts for Health
  - **Acceptance Criteria:**
    - GET `/health/score` for overall health
    - GET `/health/bills/:id/insights` for per-bill insights
    - GET `/health/action-plan` for recommendations
    - GET `/health/literacy/tips` for education content
  - **Tests:**
    - Unit tests for DTO mapping
    - Mock API implementation
  - **Effort:** 4 hours

- [ ] **Task 1.9:** Define privacy for insights
  - **Acceptance Criteria:**
    - Insights generated server-side
    - No raw bill data exposed in UI
    - PII redacted from examples
  - **Tests:** Privacy audit
  - **Effort:** 3 hours

**Phase 1 Acceptance Criteria:**
- ✅ Bill Health algorithm validated
- ✅ AI insight system designed
- ✅ Leak detection rules defined
- ✅ API contracts signed off

---

## 🏗️ Phase 2: Core UI Components

**Goal:** Build health dashboard and insight display

### Tasks

- [ ] **Task 2.1:** Create `OverallHealthScoreCard` component
  - **Acceptance Criteria:**
    - Large score display (0-100)
    - Color gradient based on score
    - Interpretation text
    - Trend indicator (↑↓→)
    - Circular progress ring
  - **Tests:**
    - UI tests for all score ranges
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.2:** Create `HealthSummaryStrip` component
  - **Acceptance Criteria:**
    - 3 key stats (overspend, highest risk, autopay risk)
    - Icon for each stat
    - Color-coding
    - Tap for details
  - **Tests:**
    - UI tests
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 3 hours

- [ ] **Task 2.3:** Create `BillInsightCard` component
  - **Acceptance Criteria:**
    - Expandable/collapsible accordion
    - Bill snapshot (provider, amount, label)
    - AI-generated insight summary (2-3 bullets)
    - Action plan subsection
    - Risk flags displayed
    - Tap to expand for full details
  - **Tests:**
    - UI tests for expand/collapse
    - Snapshot tests for all states
    - Accessibility tests
  - **Effort:** 6 hours

- [ ] **Task 2.4:** Create `ActionPlanView` component
  - **Acceptance Criteria:**
    - Prioritized list of actions
    - Effort badges (Quick, Medium, Involved)
    - Savings potential shown
    - Check-off capability
    - "Generate call script" button (future)
  - **Tests:**
    - UI tests for interactions
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 5 hours

- [ ] **Task 2.5:** Create `RiskFlagBadge` component
  - **Acceptance Criteria:**
    - Different icons for risk types
    - Severity colors (high, medium, low)
    - Tooltip with explanation
    - Tap for detailed view
  - **Tests:**
    - UI tests for tooltip
    - Snapshot tests for all types
    - Accessibility tests
  - **Effort:** 3 hours

- [ ] **Task 2.6:** Create `BillLiteracyCard` component
  - **Acceptance Criteria:**
    - Rotating tips
    - "Learn more" expansion
    - Visual illustrations
    - Share tip feature
  - **Tests:**
    - UI tests
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 4 hours

- [ ] **Task 2.7:** Create `HealthTrendChart` component
  - **Acceptance Criteria:**
    - Line chart of score over time
    - Annotations for major events (bill uploads, changes)
    - Touch to see specific months
  - **Tests:**
    - UI tests for interaction
    - Snapshot tests
    - Accessibility tests
  - **Effort:** 5 hours

- [ ] **Task 2.8:** Create `EmptyHealthView` component
  - **Acceptance Criteria:**
    - Shown when no bills uploaded
    - Clear CTA to upload first bill
    - Explanation of what health score means
  - **Tests:**
    - UI tests
    - Snapshot tests
  - **Effort:** 2 hours

- [ ] **Task 2.9:** Create `InsightDetailView` component
  - **Acceptance Criteria:**
    - Full-screen detail for an insight
    - Supporting data and charts
    - Related insights
    - Share insight option
  - **Tests:**
    - UI tests for navigation
    - Snapshot tests
  - **Effort:** 5 hours

**Phase 2 Acceptance Criteria:**
- ✅ All health UI components built
- ✅ Insights display correctly
- ✅ Action plans user-friendly
- ✅ Accessibility audit passed

---

## ⚙️ Phase 3: Business Logic & Data Layer

**Goal:** Implement health scoring, insight generation, and action planning

### Tasks

- [ ] **Task 3.1:** Create `HealthViewModel` with Combine
  - **Acceptance Criteria:**
    - Manages overall health state
    - Manages per-bill insights
    - Handles action plan tracking
    - Loading, loaded, error states
  - **Tests:**
    - Unit tests for state management
    - Memory leak tests
  - **Effort:** 6 hours

- [ ] **Task 3.2:** Implement `BillHealthEngine`
  - **Acceptance Criteria:**
    - Calculates overall health score
    - Calculates per-bill sub-scores
    - Determines trend (improving/declining)
    - Multi-factor weighting
    - Handles edge cases (no bills, single bill)
  - **Tests:**
    - Unit tests with known scenarios
    - Edge case tests
    - Statistical validation
  - **Effort:** 8 hours

- [ ] **Task 3.3:** Implement `LeakDetectionService`
  - **Acceptance Criteria:**
    - Detects loyalty penalties
    - Detects fee creep
    - Detects promo expiry
    - Detects autopay hiding increases
    - Detects usage anomalies
    - Detects potential fraud/mistakes
  - **Tests:**
    - Unit tests for each detection type
    - Integration tests with historical data
    - False positive/negative analysis
  - **Effort:** 7 hours

- [ ] **Task 3.4:** Integrate LLM for insight generation
  - **Acceptance Criteria:**
    - OpenAI / Anthropic API integration
    - Prompt engineering for bill insights
    - Context injection (TruePrice, user history)
    - Response parsing and validation
    - Fallback for API failures
  - **Tests:**
    - Integration tests with LLM
    - Quality tests for insights
    - Cost optimization tests
  - **Effort:** 8 hours

- [ ] **Task 3.5:** Implement `ActionPlanGenerator`
  - **Acceptance Criteria:**
    - Generates recommendations based on insights
    - Prioritizes by savings potential
    - Estimates effort for each action
    - Personalizes based on user profile
  - **Tests:**
    - Unit tests for recommendation logic
    - User testing for relevance
  - **Effort:** 6 hours

- [ ] **Task 3.6:** Implement risk scoring system
  - **Acceptance Criteria:**
    - Assigns severity to each risk
    - Aggregates risks for overall score
    - Trends risks over time
  - **Tests:**
    - Unit tests for risk scoring
    - Integration tests
  - **Effort:** 4 hours

- [ ] **Task 3.7:** Create `HealthRepository`
  - **Acceptance Criteria:**
    - Fetches health data from backend
    - Caches health scores
    - Syncs action plan progress
  - **Tests:**
    - Unit tests with mock API
    - Integration tests
    - Caching tests
  - **Effort:** 5 hours

- [ ] **Task 3.8:** Implement Bill Literacy content service
  - **Acceptance Criteria:**
    - Fetches curated tips
    - Contextual tips based on bills
    - Marks tips as read
  - **Tests:**
    - Unit tests
    - Integration tests
  - **Effort:** 3 hours

- [ ] **Task 3.9:** Implement insight confidence scoring
  - **Acceptance Criteria:**
    - Scores LLM insights for reliability
    - Fact-checks against TruePrice™
    - Flags low-confidence insights
  - **Tests:**
    - Unit tests for confidence logic
    - Accuracy validation
  - **Effort:** 5 hours

**Phase 3 Acceptance Criteria:**
- ✅ Bill Health algorithm working (90%+ accuracy)
- ✅ Leak detection reliable
- ✅ AI insights high quality
- ✅ All services tested (85%+ coverage)

---

## 🔌 Phase 4: Integration & Data Flow

**Goal:** Connect health UI to backend services

### Tasks

- [ ] **Task 4.1:** Integrate HealthViewModel with HealthView
  - **Acceptance Criteria:**
    - View reactively updates with ViewModel
    - Insights load and display
    - Action plan syncs
  - **Tests:**
    - Integration tests for full flow
    - UI tests for state transitions
  - **Effort:** 4 hours

- [ ] **Task 4.2:** Implement health API client
  - **Acceptance Criteria:**
    - All health endpoints working
    - Proper error handling
    - Rate limiting respected
  - **Tests:**
    - Integration tests with backend
    - Mock server tests
  - **Effort:** 4 hours

- [ ] **Task 4.3:** Implement real-time health updates
  - **Acceptance Criteria:**
    - Score updates when new bills added
    - Insights refresh automatically
    - WebSocket or polling
  - **Tests:**
    - Integration tests for real-time updates
    - UI tests
  - **Effort:** 5 hours

- [ ] **Task 4.4:** Implement action plan tracking
  - **Acceptance Criteria:**
    - User can check off completed actions
    - Progress syncs to backend
    - Notifications for pending actions
  - **Tests:**
    - Integration tests for sync
    - UI tests for tracking
  - **Effort:** 4 hours

- [ ] **Task 4.5:** Implement insight sharing
  - **Acceptance Criteria:**
    - Share insight as image
    - Share via deep link
    - Track shares in analytics
  - **Tests:**
    - UI tests for sharing
  - **Effort:** 3 hours

- [ ] **Task 4.6:** Implement notification triggers
  - **Acceptance Criteria:**
    - Notify when health score drops
    - Notify for new high-severity risks
    - Notify for action deadlines
  - **Tests:**
    - Integration tests for notifications
  - **Effort:** 4 hours

- [ ] **Task 4.7:** Implement historical health data
  - **Acceptance Criteria:**
    - View score over time
    - View past insights
    - Compare months
  - **Tests:**
    - Integration tests
    - UI tests for timeline
  - **Effort:** 4 hours

- [ ] **Task 4.8:** Implement error handling and fallbacks
  - **Acceptance Criteria:**
    - LLM failures handled gracefully
    - Fallback to rule-based insights
    - Network errors recoverable
  - **Tests:**
    - Integration tests for error scenarios
  - **Effort:** 3 hours

**Phase 4 Acceptance Criteria:**
- ✅ Full health flow working end-to-end
- ✅ Real-time updates functional
- ✅ Action tracking synced
- ✅ All integration tests passing

---

## ✅ Phase 5: Testing & Quality Assurance

**Goal:** Ensure health insights are accurate and actionable

### Tasks

- [ ] **Task 5.1:** Validate Bill Health algorithm accuracy
  - **Acceptance Criteria:**
    - Test with 100+ real bills
    - Compare to manual scoring
    - Target 90%+ agreement
    - Document edge cases
  - **Tests:** Run validation test suite
  - **Effort:** 8 hours

- [ ] **Task 5.2:** Validate leak detection accuracy
  - **Acceptance Criteria:**
    - Test with known leak scenarios
    - Measure false positive rate (< 5%)
    - Measure false negative rate (< 10%)
  - **Tests:** Run detection test suite
  - **Effort:** 6 hours

- [ ] **Task 5.3:** Quality test AI insights
  - **Acceptance Criteria:**
    - Test with diverse bills
    - Measure relevance (user survey)
    - Measure actionability
    - Target 85%+ user satisfaction
  - **Tests:** User acceptance testing
  - **Effort:** 8 hours

- [ ] **Task 5.4:** Write unit tests for health engine
  - **Acceptance Criteria:**
    - 95%+ code coverage
    - All scoring logic tested
    - Edge cases covered
  - **Tests:** Run unit test suite
  - **Effort:** 6 hours

- [ ] **Task 5.5:** Write integration tests for health service
  - **Acceptance Criteria:**
    - Full health flow tested
    - LLM integration tested with mocks
    - Error scenarios covered
  - **Tests:** Run integration test suite
  - **Effort:** 5 hours

- [ ] **Task 5.6:** Write UI tests for health screen
  - **Acceptance Criteria:**
    - Browse insights tested
    - Expand/collapse tested
    - Action plan tracking tested
  - **Tests:** Run UI test suite
  - **Effort:** 5 hours

- [ ] **Task 5.7:** Performance testing
  - **Acceptance Criteria:**
    - Health screen loads in < 2 seconds
    - Insight generation < 5 seconds
    - No memory leaks
  - **Tests:**
    - Instruments profiling
    - Performance benchmarks
  - **Effort:** 4 hours

- [ ] **Task 5.8:** Accessibility testing
  - **Acceptance Criteria:**
    - VoiceOver reads insights correctly
    - Charts have text alternatives
    - Action plan accessible
  - **Tests:**
    - Accessibility audit
    - Manual testing
  - **Effort:** 3 hours

**Phase 5 Acceptance Criteria:**
- ✅ Algorithm accuracy validated (90%+)
- ✅ AI insights quality verified (85%+ satisfaction)
- ✅ All tests passing
- ✅ Performance benchmarks met

---

## 💎 Phase 6: Polish & Optimization

**Goal:** Make health insights truly valuable

### Tasks

- [ ] **Task 6.1:** Refine insight quality with A/B testing
  - **Acceptance Criteria:**
    - Test different prompt variations
    - Measure user engagement per variant
    - Optimize for clarity and actionability
  - **Tests:**
    - A/B testing framework
    - User surveys
  - **Effort:** 6 hours

- [ ] **Task 6.2:** Add call script generation
  - **Acceptance Criteria:**
    - LLM generates negotiation scripts
    - Personalized to user and provider
    - Includes talking points
  - **Tests:**
    - Quality tests for scripts
    - User testing
  - **Effort:** 6 hours

- [ ] **Task 6.3:** Implement smart insights prioritization
  - **Acceptance Criteria:**
    - Most important insights shown first
    - Learns from user interactions
    - Adapts to user goals
  - **Tests:**
    - Integration tests
    - User testing
  - **Effort:** 5 hours

- [ ] **Task 6.4:** Add data visualizations for insights
  - **Acceptance Criteria:**
    - Charts for fee breakdown
    - Comparison charts vs TruePrice™
    - Trend visualizations
  - **Tests:**
    - UI tests
    - Accessibility tests
  - **Effort:** 6 hours

- [ ] **Task 6.5:** Implement contextual education
  - **Acceptance Criteria:**
    - Explain terms inline
    - Videos for complex topics
    - "Why this matters" sections
  - **Tests:**
    - User comprehension testing
  - **Effort:** 5 hours

- [ ] **Task 6.6:** Add insight actions automation (future)
  - **Acceptance Criteria:**
    - One-click to schedule call
    - Auto-fill provider contact forms
    - Reminder setting
  - **Tests:**
    - Integration tests
  - **Effort:** 7 hours

- [ ] **Task 6.7:** Optimize LLM costs
  - **Acceptance Criteria:**
    - Batch insight generation
    - Cache common insights
    - Use cheaper models where appropriate
  - **Tests:**
    - Cost monitoring
    - Quality maintained
  - **Effort:** 4 hours

- [ ] **Task 6.8:** Add health score sharing
  - **Acceptance Criteria:**
    - Share score with family/friends
    - Privacy controls
    - Comparison feature (optional)
  - **Tests:**
    - Privacy audit
    - UI tests
  - **Effort:** 4 hours

**Phase 6 Acceptance Criteria:**
- ✅ Insights highly actionable
- ✅ Call scripts valuable
- ✅ User engagement high
- ✅ LLM costs optimized

---

## 📚 Phase 7: Documentation & Handoff

**Goal:** Document health system and insights

### Tasks

- [ ] **Task 7.1:** Document Bill Health algorithm
  - **Acceptance Criteria:**
    - Formula fully explained
    - Factor weights documented
    - Scoring thresholds
    - Example calculations
  - **Tests:** Technical review
  - **Effort:** 4 hours

- [ ] **Task 7.2:** Document leak detection rules
  - **Acceptance Criteria:**
    - Each detection type explained
    - Thresholds and triggers
    - False positive mitigation
  - **Tests:** Technical review
  - **Effort:** 3 hours

- [ ] **Task 7.3:** Document LLM integration
  - **Acceptance Criteria:**
    - Prompt templates
    - API integration guide
    - Cost optimization strategies
  - **Tests:** Developer walkthrough
  - **Effort:** 4 hours

- [ ] **Task 7.4:** Create user documentation for health
  - **Acceptance Criteria:**
    - Understanding health score
    - Reading insights
    - Using action plans
  - **Tests:** User testing
  - **Effort:** 3 hours

- [ ] **Task 7.5:** Document API endpoints
  - **Acceptance Criteria:**
    - All health endpoints
    - Request/response examples
    - Error codes
  - **Tests:** API documentation review
  - **Effort:** 3 hours

- [ ] **Task 7.6:** Create content guidelines for insights
  - **Acceptance Criteria:**
    - Tone and voice guidelines
    - Do's and don'ts
    - Quality standards
  - **Tests:** Content review
  - **Effort:** 3 hours

- [ ] **Task 7.7:** Document analytics events
  - **Acceptance Criteria:**
    - All health events listed
    - Funnel analysis
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

- **Algorithm Accuracy:** 90%+ agreement with manual scoring
- **Insight Quality:** 85%+ user satisfaction
- **Leak Detection:** < 5% false positives, < 10% false negatives
- **Actionability:** 70%+ of users act on at least one recommendation
- **User Value:** Health insights are #1 reason for $5 subscription
- **Performance:** Health screen loads in < 2 seconds

---

## 🔗 Dependencies

- Backend health API
- LLM service (OpenAI / Anthropic)
- TruePrice™ calculation service
- Bill history data
- Analytics service
- Notification service

---

## 📅 Estimated Timeline

- **Phase 1:** 46 hours (6 days)
- **Phase 2:** 37 hours (5 days)
- **Phase 3:** 52 hours (6-7 days)
- **Phase 4:** 31 hours (4 days)
- **Phase 5:** 45 hours (5-6 days)
- **Phase 6:** 43 hours (5-6 days)
- **Phase 7:** 25 hours (3 days)

**Total Estimated Effort:** 279 hours (~7-8 weeks for one developer)

---

## 🚀 Next Steps

1. Review and approve Phase 1 plan
2. Select LLM provider for insights
3. Validate Bill Health algorithm with data science team
4. Collect sample bills for testing
5. Begin Phase 1 Task 1.1: Health screen wireframes
