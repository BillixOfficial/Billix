# Billix Marketplace v1.5 - Implementation Plan

## Vision
**StockX x FB Marketplace x Fidelity for bills.**

The Marketplace is where users discover, compare, and acquire bill-saving strategies from real people in their area.

---

## Phase 1: Core Architecture

### 1.1 Marketplace Screen Structure

```
MarketplaceView
├── Header Bar
│   ├── Logo (left)
│   ├── "Marketplace" title (center)
│   └── Icons: Search, Filter, Profile (right)
│
├── Tab Bar (Segmented Control)
│   ├── Deals (default) - Bill cards, blueprints, VS ME
│   ├── Clusters & Rallies - Group buys, syndicates, reverse auctions
│   ├── Experts & Gigs - Bill roast, audits, scripts, sherpas
│   └── Signals & Bets - Prediction markets, bounties
│
└── Content Area (ScrollView per tab)
    └── Cards (BillCard, ClusterCard, BountyCard, etc.)
```

### 1.2 Files to Create

```
Billix/Features/Marketplace/
├── MarketplaceView.swift           # Main container
├── MarketplaceTabBar.swift         # Segmented tabs
├── Models/
│   ├── BillListing.swift           # Bill card data model
│   ├── Blueprint.swift             # Strategy/script model
│   ├── Cluster.swift               # Group buy model
│   ├── Bounty.swift                # Data request model
│   └── MarketplaceUser.swift       # Seller/buyer profile
├── Components/
│   ├── Cards/
│   │   ├── BillCard/
│   │   │   ├── BillCardView.swift          # Main card container
│   │   │   ├── BillCardSideA.swift         # Asset view
│   │   │   ├── BillCardSideB.swift         # Analyst view
│   │   │   ├── Zones/
│   │   │   │   ├── TickerHeaderZone.swift  # Zone 1
│   │   │   │   ├── FinancialSpreadZone.swift # Zone 2
│   │   │   │   ├── DynamicSpecsZone.swift  # Zone 3
│   │   │   │   ├── BlueprintTeaseZone.swift # Zone 4
│   │   │   │   └── SellerFooterZone.swift  # Zone 5
│   │   │   └── VSMeToggle.swift
│   │   ├── ClusterCard.swift
│   │   ├── BountyCard.swift
│   │   ├── ScriptCard.swift
│   │   ├── ServiceCard.swift
│   │   └── PredictionCard.swift
│   ├── Sheets/
│   │   ├── AskOwnerSheet.swift
│   │   ├── PlaceBidSheet.swift
│   │   ├── UnlockBlueprintSheet.swift
│   │   └── FilterSheet.swift
│   └── Common/
│       ├── GradePill.swift
│       ├── MatchScoreRing.swift
│       ├── FrictionMeter.swift
│       ├── LivePulse.swift
│       └── VerifiedBadge.swift
├── ViewModels/
│   ├── MarketplaceViewModel.swift
│   ├── BillCardViewModel.swift
│   └── ClusterViewModel.swift
└── Services/
    └── MarketplaceService.swift
```

---

## Phase 2: The Bill Card (Core Component)

### Zone 1: Ticker Header (Identity & Trust)

**Purpose:** Answer "What is this?" and "Can I trust it?"

```
┌─────────────────────────────────────────────────────┐
│ [Logo]  Verizon Fios                    [New Cust]  │
│         🟢 Verified • 42m ago • 07030    ╭───╮     │
│         Reliability 4.8/5               │95%│      │
│                                          ╰───╯     │
└─────────────────────────────────────────────────────┘
```

**Components:**
- Provider logo (40px circle)
- Provider name (bold)
- Trust badges: Verified, timestamp, ZIP
- Eligibility pill (New Cust / Existing)
- Match Score ring (circular progress)

### Zone 2: Financial Spread (Scoreboard)

**Purpose:** Show the deal at a glance - "How much? How good?"

```
┌─────────────────────────────────────────────────────┐
│           $39.99          [S-Tier]                  │
│     vs $89.99 Market Avg   Save $50/mo              │
│                                                     │
│  Advertised $39.99 + $12 fees = $51.99 total       │
│  🔒 Locked 24 months                                │
└─────────────────────────────────────────────────────┘
```

**Components:**
- Ask Price (large, bold, green)
- Grade pill (S-Tier, A+, B, etc.)
- Market comparison (strikethrough)
- Savings pill (animates on VS ME toggle)
- True Cost microline
- Promo Cliff indicator

### Zone 3: Dynamic Specs

**Purpose:** Like sneaker size/condition - the shape of this deal

```
┌─────────────────────────────────────────────────────┐
│  ⚡ 1 Gig Fiber  │  📝 No Contract  │  📟 Own Modem │
│                                                     │
│  Difficulty: 🟢 Low – Digital chat only            │
│  Requires: Autopay + Mobile Bundle                  │
└─────────────────────────────────────────────────────┘
```

**Spec types by category:**
- Internet: Speed, Contract, Equipment
- Energy: Plan type, Rate, Renewable %
- Credit Card: Limit, APR, Rewards
- Rent: Beds, SqFt, Floor
- Fallback: Frequency, Due date, Autopay

**Friction Meter levels:**
- 🟢 Low: Digital chat only
- 🟡 Medium: Phone call (~15 min)
- 🔴 High: Cancel threat + escalation

### Zone 4: Blueprint Tease (Hidden Asset)

**Purpose:** Show there's a strategy, but keep it locked

```
┌─────────────────────────────────────────────────────┐
│  Strategy: RETENTION_CALL   🔗 AT&T Mobile Bundle  │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ │ Script: "I'm considering switching to T-Mo..." 🔒│ │
│ │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│  🛡️ Verified or Points Back  [Unlock Blueprint 50pts]│
│                                                     │
│  3 users asked questions                            │
│  "Does this stack with student discount?" → Yes     │
└─────────────────────────────────────────────────────┘
```

**Components:**
- Strategy tag chip
- Dependency icons
- Blurred/frosted content preview
- Lock icon overlay
- Points-back guarantee badge
- Unlock CTA button
- Community Q&A preview

### Zone 5: Seller Footer

**Purpose:** FB Marketplace vibe - "Who's behind this?"

```
┌─────────────────────────────────────────────────────┐
│  [👤] @SavingsKing_NJ              ❤️  💬  ⚠️     │
│       Saved others $4,000                           │
│       142 used • 88% success                        │
└─────────────────────────────────────────────────────┘
```

**Components:**
- Avatar (anonymous memoji or silhouette)
- Handle
- Stats: Total saved, uses, success rate
- Action icons: Watchlist, Ask Owner, Report
- Optional Sherpa badge

### VS ME Toggle & Live Pulse (Overlay)

```
┌──────────────────────┐
│  [Market│Vs Me]      │
│  🔥 14 viewing       │
│  ⚡ 3 unlocks/hr     │
└──────────────────────┘
```

**Behavior:**
- Toggle animates savings pill
- Market mode: "Save $50/mo vs Market"
- Vs Me mode: "You'd save $82.50/mo"

### Side B: Analyst View (Swipe Left)

```
┌─────────────────────────────────────────────────────┐
│  [Header persists]                    [Market│Vs Me]│
├─────────────────────────────────────────────────────┤
│  PERFORMANCE CHART                                  │
│  ═══════════════════════●═══                        │
│  "38% below typical for 07030"                      │
├─────────────────────────────────────────────────────┤
│  RADAR CHART           │  PEERS STAT               │
│       Price            │  Better than 94%          │
│      /     \           │  of 07030 residents       │
│   Risk ─── Speed       │  422 pay more             │
│      \     /           │                           │
│     Difficulty         │                           │
├─────────────────────────────────────────────────────┤
│  SUCCESS TREND                                      │
│  ▁▂▃▅▆▇ "Hot: working right now"                   │
├─────────────────────────────────────────────────────┤
│  DATA FRESHNESS: 🟢 21 days ago                     │
└─────────────────────────────────────────────────────┘
```

---

## Phase 3: Anonymous Inquiry System

### Flow: Asker Side

1. Tap 💬 on card → Bottom sheet opens
2. Pre-set questions (no free text):
   - "Did you have to threaten to cancel?"
   - "Are you a new customer?"
   - "Is this a student discount?"
   - "Did you bundle mobile?"
   - "Did you switch providers first?"
3. Tap "Send Question" → Toast confirmation
4. Notification when answered

### Flow: Owner Side

1. Push: "Someone asked about your deal"
2. Open Answer Center
3. See question + one-tap answers: [Yes] [No] [Not sure]
4. Earn +10 points per answer

### Data Flow

- Answers roll up into card's Dependencies
- Q&A visible in Zone 4 preview
- Training data for AI recommendations

---

## Phase 4: Cluster/Bid System

### Cluster Card Layout

```
┌─────────────────────────────────────────────────────┐
│  CLUSTER: Solar Deals in Jersey City                │
│  Help unlock a group rate by pledging your budget   │
├─────────────────────────────────────────────────────┤
│  [██████████░░░░░░░░░░] 150 / 500 bids             │
│                                                     │
│  📅 Median contract ends: Aug 2026                  │
│  💵 Median willing to pay: $92/mo                   │
│  🏘️ ZIPs: 07302, 07304, 07305                       │
├─────────────────────────────────────────────────────┤
│              [Place Bid to Join]                    │
└─────────────────────────────────────────────────────┘
```

### Place Bid Sheet

- Max price slider: "I'll pay up to $___/mo"
- Contract end date picker
- Toggles: Willing to switch, Need install
- Privacy note: "Data anonymized"

### Flash Drop (When Goal Hit)

- Push notification to cluster members
- Special offer card with provider terms
- "Claim within 48 hours"

---

## Phase 5: Supporting Card Types

### Script Card
```
┌─────────────────────────────────────────────────────┐
│  "I'm moving to Canada" bluff                       │
│  Provider: Comcast    Success: 82% (234 wins)       │
│  @ScriptMaster        Uses: 500                     │
│              [Unlock Script (X pts)]                │
└─────────────────────────────────────────────────────┘
```

### Bounty Card
```
┌─────────────────────────────────────────────────────┐
│  BOUNTY: PSEG bill under $0.12/kWh in 07030        │
│  Reward: 500 points                                 │
│  Requirements: PSEG • 07030 • < $0.12/kWh          │
│              [Submit Bill to Bounty]                │
└─────────────────────────────────────────────────────┘
```

### Service Card (Bill Audit)
```
┌─────────────────────────────────────────────────────┐
│  I can find errors in PSEG bills                    │
│  [👤] @EnergyNerd   [Verified High Saver]          │
│  "I know tariff rates; I'll check your fees"       │
│  Comp: Tips (recommended 500 pts)                   │
│              [Request Audit]                        │
└─────────────────────────────────────────────────────┘
```

### Prediction Market Card
```
┌─────────────────────────────────────────────────────┐
│  Will PSEG rates rise >5% by July?                 │
│  Current: $0.14/kWh                                 │
│  YES: 62%  •  NO: 38%                              │
│  Your position: No stake                            │
│        [Stake YES]    [Stake NO]                   │
└─────────────────────────────────────────────────────┘
```

### Contract Takeover Card
```
┌─────────────────────────────────────────────────────┐
│  1GB Internet Contract – 6 months left              │
│  Verizon Fios • $50/mo (locked) • ETF avoided: $200│
│  Seller offers $50 incentive to taker               │
│              [Request Transfer]                     │
└─────────────────────────────────────────────────────┘
```

---

## Implementation Order

### Sprint 1: Foundation
1. MarketplaceView container with tab bar
2. Theme/design system for Marketplace
3. Basic BillCard shell (Side A only)
4. Mock data models

### Sprint 2: Bill Card Complete
1. All 5 zones implemented
2. VS ME toggle with animation
3. Side B (Analyst view) with swipe
4. Live Pulse component

### Sprint 3: Interactions
1. Anonymous Inquiry bottom sheet
2. Unlock Blueprint flow
3. Watchlist functionality
4. Report flow

### Sprint 4: Clusters
1. Cluster card component
2. Place Bid sheet
3. Flash Drop notification
4. Syndicate variant

### Sprint 5: Supporting Features
1. Script cards
2. Bounty cards
3. Service/Gig cards
4. Prediction market cards
5. Contract takeover cards

### Sprint 6: Polish
1. Animations and transitions
2. Loading states
3. Empty states
4. Error handling
5. Accessibility

---

## Design Tokens

### Colors
- Primary: #3D7A5A (Money Green)
- Secondary: #9B7B9F (Billix Purple)
- Accent: #E8B54D (Gold)
- Success: #34A853
- Warning: #E8B54D
- Danger: #EA4335
- Info: #4285F4

### Grade Colors
- S-Tier: Gold gradient
- A+: Green
- A: Light green
- B: Yellow
- C: Orange
- D: Red

### Card Styling
- Corner radius: 20px
- Shadow: Layered (low/medium/high elevation)
- Glassmorphism for premium elements

---

## Questions Before Starting

1. **Scope for v1?** All tabs or just Deals + Clusters?
2. **Data source?** Mock data or Supabase integration?
3. **Points system?** Already implemented?
4. **Navigation?** New tab bar item or within existing app?
