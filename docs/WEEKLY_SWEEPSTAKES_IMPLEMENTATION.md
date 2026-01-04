# Weekly Sweepstakes Feature - Implementation Plan

## Current Status (What's Actually Implemented)

### ✅ Completed Components
1. **UI Design** - Premium WeeklyGiveawayCard with dark gradient, animations, shimmer effects
2. **Official Rules** - SweepstakesOfficialRulesView.swift with legal compliance
3. **Timer Logic** - Countdown to Sunday 8PM ET working correctly
4. **Info Button** - Links to official rules sheet

### ❌ NOT Implemented (Needs Work)
1. **Backend Service** - SweepstakesService.swift doesn't exist
2. **Database Tables** - No sweepstakes_draws or sweepstakes_entries tables
3. **Entry Submission** - Button click does nothing (placeholder code)
4. **Entry Tracking** - userEntries hardcoded to 5, not fetched from database
5. **Total Entries** - totalEntries hardcoded to 1247, not real-time count
6. **Points Deduction** - No actual point spending logic
7. **Entry Limits** - No enforcement of 10 ticket max per user per week

## User's New Requirements

1. **Add "+" Symbol to User Circles**
   - Currently shows 4 circles representing users
   - Need to add "+" somewhere to indicate "4+ users" not just exactly 4 users
   - Location: WeeklyGiveawayCard.swift lines 277-298 (SOCIAL PROOF section)

2. **Fix "You: X" Badge**
   - Currently hardcoded: `userEntries: 5` in RewardMarketplace.swift:54
   - Should fetch actual user entries for current weekly draw from database
   - Should show 0 if user hasn't entered yet

3. **Make "ENTER DRAW" Button Work**
   - Currently: Just tries to redeem a giveaway reward item (broken)
   - Should: Deduct points (ticketCount * 100), create sweepstakes entry, update UI

## Implementation Plan

### Phase 1: Database Setup (Supabase Migration)

**Create new migration file:** `supabase/migrations/[timestamp]_create_sweepstakes_system.sql`

**Table 1: sweepstakes_draws**
- Tracks weekly draw schedules and winners
- Fields: id, draw_date (Sunday 8PM ET), status, winner_user_id, total_entries, created_at

**Table 2: sweepstakes_entries**
- Tracks individual user entries
- Fields: id, draw_id, user_id, user_email, tickets_purchased (1-10), points_spent, entry_method ('points' or 'amoe'), created_at
- Constraint: UNIQUE(draw_id, user_id) - one entry per user per draw

**RPC Function: enter_sweepstakes(p_user_id, p_tickets)**
- Validate ticket count (1-10)
- Check user hasn't already entered this draw
- Verify user has enough points (tickets * 100)
- Deduct points from user_points table
- Create sweepstakes entry record
- Update draw total_entries counter
- Add point_transactions record
- Return success JSON with tickets and points_spent

**RPC Function: get_user_sweepstakes_entries(p_user_id)**
- Find active draw (status='active', draw_date > NOW())
- Return user's ticket count for current draw (or 0 if not entered)

**RPC Function: get_current_draw_info()**
- Return active draw ID, total_entries, draw_date

### Phase 2: Create SweepstakesService

**New file:** `/Users/jg_2030/Billix/Billix/Services/SweepstakesService.swift`

**Service methods:**
```swift
class SweepstakesService {
    static let shared = SweepstakesService()
    private let client: SupabaseClient

    // Enter sweepstakes (deducts points, creates entry)
    func enterSweepstakes(userId: UUID, tickets: Int) async throws -> EnterSweepstakesResult

    // Get user's entries for current draw
    func getUserEntries(userId: UUID) async throws -> Int

    // Get current draw info (total entries, draw date)
    func getCurrentDrawInfo() async throws -> DrawInfo?
}
```

**Models to create:**
```swift
struct EnterSweepstakesResult: Codable {
    let success: Bool
    let tickets: Int
    let pointsSpent: Int
}

struct DrawInfo: Codable {
    let id: UUID
    let totalEntries: Int
    let drawDate: Date
}
```

### Phase 3: Update RewardsViewModel

**File:** `/Users/jg_2030/Billix/Billix/Features/Rewards/ViewModels/RewardsViewModel.swift`

**Add properties:**
```swift
@Published var userSweepstakesEntries: Int = 0
@Published var totalSweepstakesEntries: Int = 0
@Published var isEnteringSweepstakes: Bool = false
```

**Add methods:**
```swift
func loadSweepstakesData() async {
    // Fetch user entries and total entries
    // Update @Published properties
}

func enterSweepstakes(tickets: Int) async throws {
    // Call SweepstakesService.enterSweepstakes()
    // Reload sweepstakes data
    // Refresh user points
}
```

### Phase 4: UI Updates

#### 4.1 Fix "+" Symbol for User Circles

**File:** `/Users/jg_2030/Billix/Billix/Features/Rewards/Views/Components/WeeklyGiveawayCard.swift`

**Location:** Lines 276-324 (SOCIAL PROOF section)

**Change:** Add a small "+" badge overlaid on the last circle

```swift
HStack(spacing: -8) {
    ForEach(0..<4, id: \.self) { index in
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(gradients[index])
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#1e3a8a"), lineWidth: 2)
                )

            // Add "+" badge to last circle
            if index == 3 {
                Circle()
                    .fill(Color.billixArcadeGold)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Text("+")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                    )
                    .offset(x: 4, y: -4)
            }
        }
    }
}
```

#### 4.2 Fix User Entries Display

**File:** `/Users/jg_2030/Billix/Billix/Features/Rewards/Views/Components/RewardMarketplace.swift`

**Current (Line 53-66):**
```swift
WeeklyGiveawayCard(
    userEntries: 5,  // TODO: Get from user data
    totalEntries: 1247,  // TODO: Get from backend
    currentTier: currentTier,
    onBuyEntries: { ... }
)
```

**Change to:**
```swift
WeeklyGiveawayCard(
    userEntries: viewModel.userSweepstakesEntries,  // Real data
    totalEntries: viewModel.totalSweepstakesEntries,  // Real data
    currentTier: currentTier,
    onBuyEntries: { ticketCount in
        Task {
            await viewModel.enterSweepstakes(tickets: ticketCount)
        }
    }
)
```

**Problem:** WeeklyGiveawayCard needs to accept `ticketCount` parameter in the callback!

#### 4.3 Update WeeklyGiveawayCard Callback Signature

**File:** `/Users/jg_2030/Billix/Billix/Features/Rewards/Views/Components/WeeklyGiveawayCard.swift`

**Current (Lines 11-16):**
```swift
struct WeeklyGiveawayCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let onBuyEntries: () -> Void  // ❌ Doesn't pass ticket count
    let onHowToEarn: () -> Void
```

**Change to:**
```swift
struct WeeklyGiveawayCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let onBuyEntries: (Int) -> Void  // ✅ Passes ticketCount
    let onHowToEarn: () -> Void
```

**Update button call (Line 234):**
```swift
Button {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.impactOccurred()
    onBuyEntries(ticketCount)  // ✅ Pass the current ticket count
} label: {
    // ... button UI
}
```

### Phase 5: Add Loading States and Error Handling

**Add to WeeklyGiveawayCard:**
```swift
@State private var isSubmitting: Bool = false
@State private var errorMessage: String?
@State private var showError: Bool = false
```

**Update button:**
```swift
Button {
    Task {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            onBuyEntries(ticketCount)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
} label: {
    if isSubmitting {
        ProgressView()
            .tint(.white)
    } else {
        // Existing button content
    }
}
.disabled(isSubmitting)
.alert("Entry Failed", isPresented: $showError) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage ?? "Unknown error")
}
```

## Success Criteria

When implementation is complete, the following should work:

1. ✅ **User clicks "ENTER DRAW"** → Points deducted, entry recorded in database
2. ✅ **"You: X" badge** → Shows actual tickets purchased for current weekly draw (not hardcoded)
3. ✅ **Total entries count** → Shows real count from database (not hardcoded 1247)
4. ✅ **User circles** → Show "4+" to indicate more than 4 users
5. ✅ **Entry limits** → Can't enter twice in same week, max 10 tickets
6. ✅ **Error handling** → Clear error messages for insufficient points, already entered, etc.
7. ✅ **Loading states** → Button shows spinner while submitting

## Files to Modify/Create

### New Files
1. `/Users/jg_2030/Billix/Billix/Services/SweepstakesService.swift` - Backend service
2. `supabase/migrations/[timestamp]_create_sweepstakes_system.sql` - Database schema

### Files to Modify
1. `/Users/jg_2030/Billix/Billix/Features/Rewards/Views/Components/WeeklyGiveawayCard.swift`
   - Add "+" badge to user circles (line ~277-298)
   - Change callback signature from `() -> Void` to `(Int) -> Void` (line ~15)
   - Pass ticketCount to callback (line ~234)
   - Add loading/error states

2. `/Users/jg_2030/Billix/Billix/Features/Rewards/Views/Components/RewardMarketplace.swift`
   - Replace hardcoded values with ViewModel properties (line ~54-55)
   - Update onBuyEntries callback to call ViewModel method (line ~57-62)

3. `/Users/jg_2030/Billix/Billix/Features/Rewards/ViewModels/RewardsViewModel.swift`
   - Add @Published properties for sweepstakes data
   - Add loadSweepstakesData() method
   - Add enterSweepstakes(tickets:) method

## Implementation Order

**Phase 1: Database (Required First)**
- Create Supabase migration with tables and RPC functions
- Manually create first active draw via Supabase dashboard:
  ```sql
  INSERT INTO sweepstakes_draws (draw_date, status, total_entries)
  VALUES ('2026-01-05 20:00:00-05', 'active', 0);
  ```
- Test RPC functions manually via Supabase SQL editor

**Phase 2: Backend Service**
- Create SweepstakesService.swift with enterSweepstakes(), getUserEntries(), getCurrentDrawInfo()
- Test service methods with sample data

**Phase 3: ViewModel Integration**
- Update RewardsViewModel with sweepstakes properties and methods
- Call loadSweepstakesData() in init/onAppear
- Implement enterSweepstakes() with success toast

**Phase 4: UI Updates**
- Add "+" badge to last user circle
- Change callback signature to pass ticketCount
- Update RewardMarketplace to use ViewModel data
- Add loading/error states with simple toast on success

**Phase 5: Testing**
- Test entry submission (verify points deducted, entry created)
- Test duplicate entry prevention
- Test insufficient points error
- Verify "You: X" updates after submission
- Check total entries count updates

## User Preferences

- ✅ **Draw Creation:** Manual via Supabase dashboard (you'll create new draws each week)
- ✅ **AMOE System:** Legal rules only (no email processing system needed)
- ✅ **Success UX:** Simple toast + badge update (no confetti animation)

## Winner Announcement Workflow

### Weekly Cycle (7 Days)

**Days 1-6 (Monday 12:00 AM - Sunday 8:00 PM ET):**
- Users can enter the sweepstakes
- "ENTER DRAW" button is active
- Timer shows countdown to Sunday 8:00 PM ET
- Card displays: current entries, ticket stepper, enter button

**Day 7 (Sunday 8:01 PM - Monday 12:00 AM ET):**
- Draw is closed, winner selected (manual or automated)
- Card transitions to "Winner Announcement" mode
- Display winner's username (from auth.users.username or display_name)
- Show congratulations message: "🎉 Winner: @username"
- "ENTER DRAW" button replaced with "Next Draw Starts Monday" (disabled)
- Timer shows countdown to next week's draw

**Day 8 (Monday 12:00 AM ET):**
- Automatic refresh to new sweepstakes period
- Previous draw status changes from 'active' to 'completed'
- New draw becomes active (if created manually beforehand)
- Card resets: timer restarts, entry counts reset to 0, enter button enabled
- Cycle repeats

### Database Changes for Winner Announcement

**Update sweepstakes_draws table:**
Add winner display name field:
```sql
ALTER TABLE sweepstakes_draws
ADD COLUMN winner_username TEXT;
```

**After selecting winner:**
Update the draw record with winner info:
```sql
UPDATE sweepstakes_draws
SET winner_user_id = '[winner_uuid]',
    winner_username = (SELECT username FROM auth.users WHERE id = '[winner_uuid]'),
    status = 'completed'
WHERE id = '[draw_id]';
```

### UI Changes for Winner Display

**WeeklyGiveawayCard.swift - Add Winner State**

Add new properties:
```swift
struct WeeklyGiveawayCard: View {
    let userEntries: Int
    let totalEntries: Int
    let currentTier: RewardsTier
    let winnerUsername: String?  // NEW: nil if no winner yet
    let drawStatus: DrawStatus   // NEW: .active, .awaitingWinner, .completed
    let onBuyEntries: (Int) -> Void
    let onHowToEarn: () -> Void
}

enum DrawStatus {
    case active           // Days 1-6, can enter
    case awaitingWinner   // Sunday after 8PM, waiting for winner selection
    case completed        // Winner announced
}
```

**Conditional UI based on status:**
```swift
var body: some View {
    VStack(spacing: 0) {
        if drawStatus == .completed, let winner = winnerUsername {
            // Winner announcement card
            winnerAnnouncementView(winner: winner)
        } else if drawStatus == .awaitingWinner {
            // Draw closed, waiting for winner
            drawClosedView
        } else {
            // Normal active sweepstakes card
            eligibleCard
        }
    }
}

// Winner announcement view
private func winnerAnnouncementView(winner: String) -> some View {
    VStack(spacing: 20) {
        Text("🎉 WINNER ANNOUNCEMENT 🎉")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(.billixArcadeGold)

        Text("Congratulations")
            .font(.title3.bold())
            .foregroundColor(.white)

        Text("@\(winner)")
            .font(.system(size: 32, weight: .black, design: .rounded))
            .foregroundColor(.billixMoneyGreen)

        Text("Won $50 off their bill!")
            .font(.headline)
            .foregroundColor(.white.opacity(0.9))

        // Next draw countdown
        Text("Next draw starts in \(formatTimeToMonday())")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
    }
    .padding(24)
    .background(
        LinearGradient(
            colors: [Color.billixDarkGreen, Color.billixMoneyGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .cornerRadius(20)
}
```

### Service Updates

**SweepstakesService.swift - Add winner methods:**
```swift
func getCurrentDrawInfo() async throws -> DrawInfo? {
    // Returns draw with status, winner_username, draw_date
}

struct DrawInfo: Codable {
    let id: UUID
    let totalEntries: Int
    let drawDate: Date
    let status: String  // 'active', 'awaitingWinner', 'completed'
    let winnerUsername: String?
}
```

### Automatic Weekly Transition

**Option 1: Manual (Your Preference)**
- Every Monday morning, manually insert new draw record
- Every Sunday night after 8PM, manually select winner and update draw

**Option 2: Automated (Future Enhancement)**
- Supabase Edge Function runs Sunday 8:01 PM ET
- Selects random winner from entries
- Updates draw with winner info
- Creates next week's draw automatically
