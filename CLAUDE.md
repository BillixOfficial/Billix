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

# Run a single test file
xcodebuild test -project Billix.xcodeproj -scheme Billix -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BillixTests/YourTestClass

# Open in Xcode
open Billix.xcodeproj

# Clean build folder
xcodebuild -project Billix.xcodeproj -scheme Billix clean
```

## Architecture

### App Entry & Navigation
- `BillixApp.swift` - App entry point with SwiftData ModelContainer setup and `RootView`
- `RootView` handles auth state routing via `ViewState` enum: `.loading` → `.login` → `.emailVerification` → `.onboarding` → `.main`
- `MainTabView` - 5 tabs: Home, Explore, Upload, Rewards, Profile

### Feature-Based Organization
Each feature module follows the pattern: `Views/`, `Components/`, `Models/`, `ViewModels/`

Key features:
- **Auth** - Login, signup, onboarding, email verification
- **Home** - Dashboard, bill health, savings opportunities, task tracking
- **Explore** - Bill comparison, housing search, market trends, economy feed
- **Upload** - Bill upload (scan, quick add, document picker)
- **Rewards** - Points, tiers, seasonal campaigns, geo games

### Key Patterns

**Authentication Flow:**
- `AuthService.shared` singleton manages Supabase auth state
- Publishes `isAuthenticated`, `needsOnboarding`, `awaitingEmailVerification`, `isGuestMode`
- Auth state observed via `supabase.auth.authStateChanges` async stream
- Supports email/password and Sign in with Apple

**Service Layer:**
- Protocol-oriented design (e.g., `BillUploadServiceProtocol`)
- Factory pattern via `BillUploadServiceFactory.create()` - all environments now use real API
- Rate limiting: `RateLimitService` with configs in `RateLimitConfig.swift`
- External APIs: RentCast via `RentCastEdgeFunctionService`, Weather via `WeatherService`

**ViewModels:**
- All ViewModels are `@MainActor` ObservableObject classes
- Use Combine's `@Published` for reactive UI updates
- Shared singletons: `AuthService.shared`, `StreakService.shared`, `TasksViewModel.shared`
- Pattern: ViewModel depends on service protocol for testability

**SwiftData:**
- `StoredBill` model for local bill persistence
- ModelContainer configured in `BillixApp.swift`

### Color System
Billix color palette in `Utilities/ColorPalette.swift`:
- `Color.billixDarkTeal` - Primary teal (#2d5a5e)
- `Color.billixMoneyGreen` - Success/money green (#5b8a6b)
- `Color.billixGoldenAmber` - Gold/amber accent (#e8b54d)
- `Color.billixCreamBeige` - Background cream (#dcc9a8)
- `Color.billixPurple` - Purple accent (#9b7b9f)
- Login: `Color.billixLoginTeal`, `Color.billixLoginGreen`
- Tiers: `Color.billixBronzeTier`, `Color.billixSilverTier`, `Color.billixGoldTier`

Custom view modifiers in `Utilities/CustomStyles.swift`:
- `.glassMorphic()` - Frosted glass card effect
- `.neumorphic()` - Soft shadow 3D effect
- `.shimmer()` - Loading shimmer animation
- `.pulsingGlow()` - Animated glow effect
- `.floating()` - Floating animation

## Configuration

Backend configuration in `Services/Config.swift`:
- `Config.supabaseURL` - Supabase project URL
- `Config.supabaseAnonKey` - Supabase anon key
- `Config.apiBaseURL` - Backend API base URL (billixapp.com)
- API endpoints: `Config.billUploadEndpoint`, `Config.marketplaceEndpoint`, `Config.housingMarketEndpoint`

## Dependencies (Swift Package Manager)
- `supabase-swift` - Authentication and database

## Important Notes

- **Adding Swift files**: Files must be added to the Xcode project target, not just the filesystem. Use Xcode or update project.pbxproj.
- **Environment switching**: `AppEnvironment.current` returns `.development` in DEBUG, `.production` otherwise. All environments now use real API.
- **MainActor**: All ViewModels and UI-related code must run on `@MainActor`
- **Guest mode**: `AuthService.isGuestMode` allows users to skip onboarding and access the main app without full authentication
