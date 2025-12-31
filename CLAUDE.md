# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Billix is a SwiftUI iOS app for bill management, comparison marketplace, and financial insights. The app uses Supabase for authentication and backend services, SwiftData for local persistence, and follows MVVM architecture with protocol-oriented design.

## Build & Run Commands

```bash
# Build the project
xcodebuild -project Billix.xcodeproj -scheme Billix -configuration Debug build

# Run tests
xcodebuild -project Billix.xcodeproj -scheme Billix test -destination 'platform=iOS Simulator,name=iPhone 16'

# Open in Xcode
open Billix.xcodeproj

# Clean build folder
xcodebuild -project Billix.xcodeproj -scheme Billix clean
```

## Architecture

### App Entry & Navigation
- `BillixApp.swift` - App entry point with SwiftData ModelContainer setup and `RootView`
- `RootView` handles auth state routing: Loading → Login → EmailVerification → Onboarding → MainTabView
- `MainTabView` - 5 tabs: Home, Explore, Upload, Rewards, Profile

### Feature-Based Organization
```
Billix/
├── App/                    # Entry point, ContentView, MainTabView
├── Core/                   # Shared infrastructure
│   ├── Cache/             # Memory and disk caching
│   ├── Extensions/        # Color+Hex, Date extensions
│   └── Network/           # NetworkError
├── Features/              # Feature modules (each with Views/Components/Models/ViewModels)
│   ├── Auth/              # Login, signup, onboarding, email verification
│   ├── Home/              # Dashboard, bill health, savings opportunities
│   ├── Explore/           # Bill comparison, marketplace data
│   ├── Upload/            # Bill upload (scan, quick add, document picker)
│   ├── Marketplace/       # Bill trading, listings, bidding
│   ├── Rewards/           # Points, tiers, seasonal campaigns
│   ├── Profile/           # User settings, privacy, locations
│   ├── TrustLadder/       # Peer swaps, portfolio matching
│   └── BillCoach/         # AI-powered bill advice
├── Models/                # Shared data models (BillAnalysis, StoredBill, etc.)
├── Services/              # App-wide services
│   ├── AuthService.swift  # Supabase auth singleton
│   ├── SupabaseService.swift
│   └── Upload/            # Protocol-based upload service (mock/real)
└── Utilities/             # Colors, styles, reusable components
```

### Key Patterns

**Authentication Flow:**
- `AuthService.shared` singleton manages Supabase auth state
- Publishes `isAuthenticated`, `needsOnboarding`, `awaitingEmailVerification`
- Supports email/password and Sign in with Apple

**Service Layer:**
- Protocol-oriented design (`BillUploadServiceProtocol`)
- Factory pattern for environment-based service selection (mock/staging/production)
- See `BillUploadServiceFactory.swift` for environment switching

**ViewModels:**
- All ViewModels are `@MainActor` ObservableObject classes
- Use Combine's `@Published` for reactive UI updates
- Pattern: ViewModel depends on service protocol for testability

**SwiftData:**
- `StoredBill` model for local bill persistence
- ModelContainer configured in `BillixApp.swift`

### Color System
Use the Billix color palette defined in `Utilities/ColorPalette.swift`:
- `Color.billixDarkTeal` - Primary teal
- `Color.billixMoneyGreen` - Success/money green
- `Color.billixGoldenAmber` - Gold/amber accent
- `Color.billixCreamBeige` - Background cream
- `Color.billixPurple` - Purple accent
- Login colors: `Color.billixLoginTeal`, `Color.billixLoginGreen`

Custom view modifiers in `Utilities/CustomStyles.swift`:
- `.glassMorphic()` - Frosted glass card effect
- `.neumorphic()` - Soft shadow 3D effect
- `.shimmer()` - Loading shimmer animation

## Configuration

Backend configuration in `Services/Config.swift`:
- `Config.supabaseURL` - Supabase project URL
- `Config.supabaseAnonKey` - Supabase anon key
- `Config.apiBaseURL` - Backend API base URL (billixapp.com)

## Dependencies (Swift Package Manager)
- `supabase-swift` - Authentication and database

## Testing
Tests are in `BillixTests/` and `BillixUITests/`. Run via Xcode or:
```bash
xcodebuild test -project Billix.xcodeproj -scheme Billix -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Important Notes

- When adding new Swift files, ensure they're added to the Xcode project target (file operations should be done in Xcode, not just filesystem)
- The Upload feature uses mock data by default in DEBUG mode (`AppEnvironment.development`)
- Auth state changes are observed via `supabase.auth.authStateChanges` async stream
- All UI work must happen on `@MainActor`
