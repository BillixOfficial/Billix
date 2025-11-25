# Billix iOS - Figma Design System Integration Rules

> **Purpose**: This document provides comprehensive guidelines for translating Figma designs into SwiftUI code for the Billix iOS app. Use this as a reference when implementing new screens or components from Figma designs.

---

## Table of Contents

1. [Design Tokens](#1-design-tokens)
2. [Typography System](#2-typography-system)
3. [Component Library](#3-component-library)
4. [Styling Patterns](#4-styling-patterns)
5. [Project Architecture](#5-project-architecture)
6. [Asset Management](#6-asset-management)
7. [Animation Guidelines](#7-animation-guidelines)
8. [Figma-to-SwiftUI Mapping](#8-figma-to-swiftui-mapping)

---

## 1. Design Tokens

### Color Palette

**Location**: `Billix/Utilities/ColorPalette.swift`

All colors are defined as static properties on `Color` extension with HEX values.

#### Brand Colors (Logo-Inspired)

```swift
// Primary Brand Colors
Color.billixPurple          // #9b7b9f - Piggy bank purple
Color.billixGoldenAmber     // #e8b54d - Golden amber (accent)
Color.billixDarkTeal        // #2d5a5e - Dark teal base
Color.billixMoneyGreen      // #5b8a6b - Money green (success)
Color.billixCreamBeige      // #dcc9a8 - Cream beige (neutral)
Color.billixDarkGray        // #282525 - Dark gray/black (text)
```

#### UI Semantic Colors

```swift
// Backgrounds
Color.billixLightGreen      // #f0f8ec - Main app background
Color.billixLoginGreen      // #b8e6b8 - Login screen background

// Text Colors
Color.billixDarkGreen       // #234d34 - Primary text
Color.billixMediumGreen     // #5e7a5f - Secondary text
Color.billixLoginTeal       // #00796b - Login primary text

// Status Colors
Color.billixPendingOrange        // #fcf3e8 - Pending background
Color.billixPendingOrangeText    // #d88237 - Pending text
Color.billixCompletedGreen       // #f0f8ec - Completed background
Color.billixActiveBlue           // #e8f4fc - Active background

// Interactive Elements
Color.billixStarGold        // #f19e38 - Star ratings
Color.billixSavingsYellow   // #f7bc56 - Savings progress
Color.billixChartBlue       // #52b8df - Chart elements
Color.billixChartOrange     // #ed9455 - Chart elements (alt)
Color.billixChartPurple     // #a58fb7 - Chart elements (alt)
```

#### Gradient Colors

```swift
// For gradient effects
Color.billixLightPurple     // #e8dfe9 - Light gradient
Color.billixMintGreen       // #d4f4dd - Mint gradient
Color.billixLavender        // #d9d3e8 - Lavender gradient
Color.billixPeach           // #f9e6d5 - Peach gradient
```

#### Navigation Colors

```swift
// Bottom tab colors
.billixLoginTeal    // Home tab (teal)
.blue               // Explore tab
.billixMoneyGreen   // Upload tab (green)
.red                // Health tab
.billixDarkGreen    // Profile tab
```

### Figma Color Mapping

When implementing Figma designs:

1. **Primary Actions**: Use `billixMoneyGreen` or `billixLoginTeal`
2. **Accent/Highlights**: Use `billixGoldenAmber`
3. **Backgrounds**: Use `billixLightGreen` for main, `Color.white` for cards
4. **Text Hierarchy**:
   - Headlines: `billixDarkGreen`
   - Body: `.primary` or `billixMediumGreen`
   - Captions: `.gray` or `.secondary`
5. **Status Indicators**:
   - Success/Completed: `billixMoneyGreen` or `billixCompletedGreen`
   - Pending/Warning: `billixPendingOrange`
   - Error: `.red`

### Spacing System

```swift
// Standard spacing values (use these consistently)
4pt   // Micro spacing (between related items)
8pt   // Small spacing
12pt  // Medium spacing
16pt  // Standard spacing (most common)
20pt  // Large spacing
24pt  // Extra large spacing
32pt  // Section spacing
```

### Border Radius

```swift
8pt   // Small elements (badges, pills)
12pt  // Medium elements (buttons)
16pt  // Cards, containers (most common)
20pt  // Large cards (glass morphic)
50%   // Circular (profile images, icons)
```

---

## 2. Typography System

### Font Patterns

**Location**: Observed across `Features/*/Components/` and main views

#### Hierarchy

```swift
// Display / Large Numbers
.font(.system(size: 40, weight: .bold))
.foregroundColor(.billixMoneyGreen)

// Page Titles
.font(.system(size: 28, weight: .bold))
.foregroundColor(.billixDarkGreen)

// Navigation Titles
.font(.system(size: 20, weight: .semibold))
.foregroundColor(.billixDarkGreen)

// Section Headers
.font(.system(size: 18, weight: .semibold))
.foregroundColor(.billixDarkGreen)

// Card Titles
.font(.system(size: 16, weight: .semibold))
.foregroundColor(.primary)

// Body Text
.font(.system(size: 14))
.foregroundColor(.primary)

// Body Text (Medium)
.font(.system(size: 14, weight: .medium))
.foregroundColor(.billixDarkGreen)

// Captions / Labels
.font(.system(size: 13))
.foregroundColor(.gray)

// Small Text / Metadata
.font(.system(size: 12))
.foregroundColor(.secondary)

// Tiny Text (badges, footnotes)
.font(.system(size: 11, weight: .medium))
.foregroundColor(.billixDarkGreen)
```

#### Font Weights

- `.bold` - Headlines, emphasis, large numbers
- `.semibold` - Titles, section headers, buttons
- `.medium` - Body text with emphasis, labels
- `.regular` (default) - Standard body text

### Text Styling Patterns

```swift
// Amount/Currency Display
Text("$\(amount, specifier: "%.2f")")
    .font(.system(size: 40, weight: .bold))
    .foregroundColor(.billixMoneyGreen)

// Percentage Display
Text("\(percentage, specifier: "%.1f")%")
    .font(.system(size: 16, weight: .semibold))
    .foregroundColor(.billixSavingsYellow)

// Section Header with Icon
HStack {
    Image(systemName: "icon.name")
        .font(.system(size: 16))
    Text("Section Title")
        .font(.system(size: 18, weight: .semibold))
}
.foregroundColor(.billixDarkGreen)

// Multi-line Text with Line Limit
Text("Description text...")
    .font(.system(size: 14))
    .foregroundColor(.gray)
    .lineLimit(2)
    .multilineTextAlignment(.leading)
```

---

## 3. Component Library

### Shared Utility Components

**Location**: `Billix/Utilities/Components/`

#### AnimatedBackground

Floating coins animation with gradient background.

```swift
AnimatedBackground()
    .ignoresSafeArea()
```

**Use for**: Login screen, splash screens, empty states

#### ProgressBar

Animated progress bar with customizable colors.

```swift
ProgressBar(
    progress: 0.65,
    height: 8,
    backgroundColor: Color.gray.opacity(0.2),
    foregroundColor: .billixMoneyGreen
)
```

**Use for**: Savings goals, completion indicators, loading states

#### Sparkline

Minimal line chart for trend visualization.

```swift
Sparkline(
    data: [120, 145, 130, 160, 155],
    lineColor: .billixChartBlue,
    fillGradient: LinearGradient(...)
)
.frame(height: 60)
```

**Use for**: Spending trends, bill history, market data

#### CountUp

Animated number counting effect.

```swift
CountUp(value: 1250.50, duration: 1.5)
    .font(.system(size: 40, weight: .bold))
    .foregroundColor(.billixMoneyGreen)
```

**Use for**: Savings amounts, totals, achievement displays

### Profile Components

**Location**: `Billix/Features/Profile/Components/`

#### ProfileSectionCard

Standard white card container with shadow.

```swift
ProfileSectionCard {
    VStack(alignment: .leading, spacing: 12) {
        // Your content
    }
}
```

**Properties**:
- White background
- 16pt corner radius
- Subtle shadow
- Standard padding

#### ProfileSectionHeader

Consistent section header with icon.

```swift
ProfileSectionHeader("Settings", icon: "gearshape.fill")
```

#### SettingsRow

Interactive settings row with arrow indicator.

```swift
SettingsRow(
    title: "Account Details",
    subtitle: "Manage your account",
    icon: "person.circle.fill",
    action: { /* navigate */ }
)
```

#### SettingsToggleRow

Settings row with toggle switch.

```swift
SettingsToggleRow(
    title: "Push Notifications",
    icon: "bell.fill",
    iconColor: .billixMoneyGreen,
    isOn: $notificationsEnabled
)
```

### Home Components

**Location**: `Billix/Features/Home/Components/`

Key reusable components:

- **CompactProfileCard** - Profile preview with avatar
- **AIInsightsCard** - AI-generated insights display
- **ConsolidatedSavingsCard** - Savings summary with progress
- **BillCardView** - Individual bill display with due date badge
- **SavingsOpportunityCard** - Actionable savings suggestion
- **AlertCard** - Alert/notification display
- **QuickActionCard** - Action button with icon

### Upload Components

**Location**: `Billix/Features/Upload/Views/Components/`

- **RecentUploadRow** - Upload history item with thumbnail and status

### Card Pattern Template

Standard card styling used throughout the app:

```swift
VStack(alignment: .leading, spacing: 12) {
    // Card content
}
.padding(16)
.background(Color.white)
.cornerRadius(16)
.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
```

---

## 4. Styling Patterns

### Custom View Modifiers

**Location**: `Billix/Utilities/CustomStyles.swift`

#### Glass Morphic Effect

Creates a frosted glass appearance with gradient borders.

```swift
.modifier(GlassMorphicCard(cornerRadius: 20))
// Or shorthand:
.glassMorphic(cornerRadius: 20)
```

**Properties**:
- Ultra-thin material blur
- Cream beige background with opacity
- Gradient border (golden amber + light purple)
- Layered shadows for depth

**Use for**: Premium features, highlighted cards, decorative elements

#### Neumorphic Style

Raised/pressed button effect with dual shadows.

```swift
.modifier(NeumorphicStyle(isPressed: false, cornerRadius: 16))
// Or shorthand:
.neumorphic(isPressed: isPressed, cornerRadius: 16)
```

**Use for**: Interactive buttons, toggle states, 3D effects

#### Shimmer Effect

Gold/amber shimmer overlay animation.

```swift
.shimmer()
```

**Use for**: Loading states, featured items, new content indicators

#### Pulsing Glow

Animated shadow pulsing effect.

```swift
.pulsingGlow(color: .billixGoldenAmber)
```

**Use for**: Attention grabbers, notifications, CTAs

#### Floating Animation

Gentle vertical floating motion.

```swift
.floating(delay: 0)
```

**Use for**: Decorative elements, empty states, floating buttons

#### Scale on Tap

Interactive press animation for buttons.

```swift
.scaleOnTap {
    // Action
}
```

**Use for**: All tappable elements, buttons, cards

### Common Patterns

#### Standard Button

```swift
Button(action: action) {
    Text("Button Text")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.billixMoneyGreen)
        .cornerRadius(12)
}
.buttonStyle(ScaleButtonStyle())
```

#### Icon Button

```swift
Button(action: action) {
    Image(systemName: "icon.name")
        .font(.system(size: 20))
        .foregroundColor(.billixDarkGreen)
        .frame(width: 44, height: 44)
        .background(Color.billixLightGreen)
        .cornerRadius(12)
}
```

#### Badge

```swift
Text("NEW")
    .font(.system(size: 11, weight: .medium))
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.billixMoneyGreen)
    .cornerRadius(8)
```

#### Divider

```swift
// Horizontal divider
Rectangle()
    .fill(Color.gray.opacity(0.2))
    .frame(height: 1)

// Profile divider (from ProfileSectionCard)
ProfileDivider()
```

#### Gradient Background

```swift
// Standard card gradient
LinearGradient(
    colors: [
        Color.billixMoneyGreen.opacity(0.08),
        Color.billixMoneyGreen.opacity(0.05)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Login screen gradient
LinearGradient(
    gradient: Gradient(colors: [
        Color.billixLoginGreen,
        Color.billixLoginTeal.opacity(0.3)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## 5. Project Architecture

### MVVM Pattern

All features follow the MVVM architecture pattern.

#### File Structure

```
Features/{FeatureName}/
├── {FeatureName}View.swift           # UI Layer
├── {FeatureName}ViewModel.swift      # Business Logic
├── Models/                           # Feature-specific models
├── Services/                         # Data/API services
├── Components/                       # Reusable UI components
└── Views/                           # Sub-views (optional)
```

#### View Template

```swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    @State private var showSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // UI components
                }
                .padding()
            }
            .background(Color.billixLightGreen.ignoresSafeArea())
            .navigationTitle("Title")
            .task {
                await viewModel.loadData()
            }
        }
    }
}
```

#### ViewModel Template

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var data: [Model] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let service: ServiceProtocol

    // MARK: - Init
    init(service: ServiceProtocol = RealService()) {
        self.service = service
    }

    // MARK: - Public Methods
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            data = try await service.fetchData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Service Layer Pattern

**Location**: `Billix/Services/`

#### Protocol-Based Services

```swift
// 1. Define protocol
protocol FeatureServiceProtocol {
    func fetchData() async throws -> [Model]
}

// 2. Real implementation
class RealFeatureService: FeatureServiceProtocol {
    func fetchData() async throws -> [Model] {
        // API call
    }
}

// 3. Mock implementation
class MockFeatureService: FeatureServiceProtocol {
    func fetchData() async throws -> [Model] {
        // Return mock data
    }
}

// 4. Factory
class FeatureServiceFactory {
    static func create() -> FeatureServiceProtocol {
        #if DEBUG
        return MockFeatureService()
        #else
        return RealFeatureService()
        #endif
    }
}
```

### Model Patterns

#### SwiftData Model

```swift
import SwiftData

@Model
final class StoredBill {
    var id: UUID
    var fileName: String
    var uploadDate: Date
    var analysisData: Data?

    init(id: UUID = UUID(), fileName: String, uploadDate: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.uploadDate = uploadDate
    }
}
```

#### API Response Model

```swift
struct BillAnalysis: Codable, Identifiable {
    let id: String
    let provider: BillProvider
    let totalAmount: Double
    let billDate: Date
    let lineItems: [LineItem]

    // Computed properties
    var formattedAmount: String {
        String(format: "$%.2f", totalAmount)
    }
}
```

#### Enum with Associated Values

```swift
enum UploadStatus: String, Codable {
    case processing
    case analyzed
    case needsConfirmation
    case failed

    var displayText: String {
        switch self {
        case .processing: return "Processing..."
        case .analyzed: return "Completed"
        case .needsConfirmation: return "Needs Review"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .processing: return .billixPendingOrangeText
        case .analyzed: return .billixMoneyGreen
        case .needsConfirmation: return .billixChartBlue
        case .failed: return .red
        }
    }
}
```

### Navigation Patterns

#### Tab Navigation

**Location**: `Billix/App/MainTabView.swift`

5-tab structure with custom bottom bar:

```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tag(0)

    ExploreTabView()
        .tag(1)

    UploadHubView()
        .tag(2)

    HealthView()
        .tag(3)

    ProfileView()
        .tag(4)
}
.overlay(alignment: .bottom) {
    CustomBottomNavBar(selectedTab: $selectedTab)
}
```

#### Sheet Presentation

```swift
// In View
@State private var showSheet = false

Button("Show Details") {
    showSheet = true
}
.sheet(isPresented: $showSheet) {
    DetailView()
}
```

#### Navigation Link

```swift
NavigationLink(destination: DetailView(item: item)) {
    ItemRowView(item: item)
}
```

---

## 6. Asset Management

### Logo Assets

**Primary Logo**: `billix_logo_new`

```swift
Image("billix_logo_new")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 160, height: 160)
```

### SF Symbols (System Icons)

The app uses SF Symbols extensively. Common categories:

#### Navigation & UI

```swift
"house.fill"                    // Home
"chart.bar.xaxis"               // Explore/Analytics
"arrow.up.doc.fill"             // Upload
"heart.text.square.fill"        // Health
"person.crop.circle.fill"       // Profile
"chevron.right"                 // Navigation arrow
"xmark"                         // Close/dismiss
"line.3.horizontal"             // Menu
```

#### Bill Categories

```swift
"bolt.fill"                     // Electric
"phone.fill"                    // Phone/Mobile
"wifi"                          // Internet
"flame.fill"                    // Gas
"drop.fill"                     // Water
"car.fill"                      // Auto/Transportation
"house.fill"                    // Rent/Housing
"tv.fill"                       // Streaming/Cable
"cross.fill"                    // Healthcare
"creditcard.fill"               // Credit Card
```

#### Status & Actions

```swift
"checkmark.circle.fill"         // Success/Completed
"clock.fill"                    // Pending/Scheduled
"exclamationmark.triangle.fill" // Warning
"xmark.circle.fill"             // Error/Failed
"star.fill"                     // Favorites/Rating
"plus.circle.fill"              // Add
"trash.fill"                    // Delete
"pencil"                        // Edit
"arrow.clockwise"               // Refresh
```

#### Upload Sources

```swift
"camera.fill"                   // Camera capture
"photo.fill"                    // Photo library
"doc.fill"                      // Documents
"doc.text.viewfinder"           // Document scanner
```

### Icon Usage Pattern

```swift
// Colored icon with background
Image(systemName: "bolt.fill")
    .font(.system(size: 20))
    .foregroundColor(.billixGoldenAmber)
    .frame(width: 40, height: 40)
    .background(
        Circle()
            .fill(Color.billixGoldenAmber.opacity(0.1))
    )

// Tab bar icon
Image(systemName: isSelected ? "house.fill" : "house")
    .font(.system(size: 22))
    .foregroundColor(isSelected ? activeColor : .gray)
```

### Provider Logos

Provider logos are referenced by name and loaded from asset catalog:

```swift
struct BillProvider: Codable {
    let id: String
    let name: String
    let logoName: String  // Asset catalog name
}

// Usage
Image(provider.logoName)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 40, height: 40)
```

---

## 7. Animation Guidelines

### Animation Timing

```swift
// Quick interactions
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)

// Smooth transitions
.animation(.easeInOut(duration: 0.3), value: state)

// Bouncy effects
.animation(.spring(response: 0.4, dampingFraction: 0.6), value: state)

// Delays (for sequential animations)
.animation(.spring(response: 0.3).delay(0.1 * index), value: state)
```

### Common Animations

#### Scale on Tap

```swift
@State private var isPressed = false

// Method 1: Manual
.scaleEffect(isPressed ? 0.92 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

// Method 2: Custom modifier
.scaleOnTap { /* action */ }
```

#### Slide In

```swift
@State private var show = false

.offset(y: show ? 0 : 50)
.opacity(show ? 1 : 0)
.animation(.spring(response: 0.5), value: show)
.onAppear { show = true }
```

#### Fade In

```swift
@State private var opacity = 0.0

.opacity(opacity)
.onAppear {
    withAnimation(.easeIn(duration: 0.5)) {
        opacity = 1.0
    }
}
```

#### Rotation (Loading)

```swift
@State private var isRotating = false

Image(systemName: "arrow.clockwise")
    .rotationEffect(.degrees(isRotating ? 360 : 0))
    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
    .onAppear { isRotating = true }
```

### Haptic Feedback

```swift
// Light tap feedback
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred()

// Medium impact
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()

// Success notification
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)

// Error notification
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.error)
```

**Use haptic feedback for**:
- Button taps
- Toggle switches
- Success/error states
- Sheet dismissals
- Tab switches

---

## 8. Figma-to-SwiftUI Mapping

### Translation Guidelines

#### Step 1: Identify Design Tokens

| Figma Element | SwiftUI Mapping |
|--------------|-----------------|
| Fill color | `.background(Color.billixColorName)` |
| Stroke | `.border()` or `.overlay(RoundedRectangle().stroke())` |
| Corner radius | `.cornerRadius()` or `.clipShape(RoundedRectangle())` |
| Shadow | `.shadow(color:radius:x:y:)` |
| Opacity | `.opacity()` |
| Blur | `.blur(radius:)` |

#### Step 2: Match Colors

1. Extract HEX color from Figma
2. Check if it matches existing `ColorPalette.swift` colors
3. If new color needed, add to `ColorPalette.swift`:

```swift
static let billixNewColor = Color(hex: "#HEXCODE")
```

#### Step 3: Component Hierarchy

Figma → SwiftUI structure mapping:

```
Frame (Auto Layout Vertical)    → VStack(spacing:)
Frame (Auto Layout Horizontal)  → HStack(spacing:)
Frame (Fixed)                   → ZStack or specific .frame()
Text                           → Text().font().foregroundColor()
Rectangle                      → Rectangle() or RoundedRectangle()
Image                          → Image() or AsyncImage()
Button                         → Button { } label: { }
```

#### Step 4: Layout Properties

| Figma Property | SwiftUI Equivalent |
|---------------|-------------------|
| Padding | `.padding()` or `.padding(.edges, value)` |
| Gap (spacing) | `VStack(spacing:)` or `HStack(spacing:)` |
| Alignment | `.frame(alignment:)` or container alignment |
| Width/Height | `.frame(width:height:)` |
| Max width | `.frame(maxWidth:)` |
| Hug contents | No explicit frame needed |
| Fill container | `.frame(maxWidth: .infinity)` |

### Example: Figma Card → SwiftUI

**Figma Design**:
- Frame: 360×120
- Fill: #FFFFFF
- Corner radius: 16
- Shadow: 0px 2px 8px rgba(0,0,0,0.04)
- Padding: 16
- Auto layout vertical, gap 12

**SwiftUI Implementation**:

```swift
VStack(alignment: .leading, spacing: 12) {
    // Content here
}
.padding(16)
.frame(maxWidth: .infinity)
.frame(height: 120)
.background(Color.white)
.cornerRadius(16)
.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
```

### Common Figma Patterns

#### Card with Icon Header

```swift
HStack(spacing: 12) {
    // Icon
    Image(systemName: "icon.name")
        .font(.system(size: 20))
        .foregroundColor(.billixGoldenAmber)
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(Color.billixGoldenAmber.opacity(0.1))
        )

    // Text content
    VStack(alignment: .leading, spacing: 4) {
        Text("Title")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.billixDarkGreen)

        Text("Subtitle")
            .font(.system(size: 13))
            .foregroundColor(.gray)
    }

    Spacer()

    // Trailing element
    Image(systemName: "chevron.right")
        .font(.system(size: 14))
        .foregroundColor(.gray)
}
.padding(16)
.background(Color.white)
.cornerRadius(16)
.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
```

#### Stat Display Card

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Total Savings")
        .font(.system(size: 13))
        .foregroundColor(.gray)

    Text("$1,250.50")
        .font(.system(size: 32, weight: .bold))
        .foregroundColor(.billixMoneyGreen)

    HStack(spacing: 4) {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 12))
        Text("12.5% vs last month")
            .font(.system(size: 12))
    }
    .foregroundColor(.billixMoneyGreen)
}
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(
    LinearGradient(
        colors: [
            Color.billixMoneyGreen.opacity(0.08),
            Color.billixMoneyGreen.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
.cornerRadius(16)
```

### Responsive Design

#### Screen Size Considerations

```swift
// Use GeometryReader for responsive layouts
GeometryReader { geometry in
    let width = geometry.size.width
    let isCompact = width < 375

    VStack(spacing: isCompact ? 12 : 16) {
        // Adjust spacing based on screen size
    }
}

// Use size classes
@Environment(\.horizontalSizeClass) var sizeClass

if sizeClass == .compact {
    // Compact layout
} else {
    // Regular layout
}
```

#### Safe Area Handling

```swift
// Extend background into safe area
.background(Color.billixLightGreen.ignoresSafeArea())

// Respect safe area for content
.padding(.horizontal)
.safeAreaInset(edge: .bottom) {
    // Bottom content
}
```

---

## Quick Reference Checklist

When implementing a new screen from Figma:

- [ ] Extract all unique colors and map to existing `ColorPalette` colors
- [ ] Identify reusable components from the component library
- [ ] Create feature folder following MVVM structure
- [ ] Define models with `Codable` conformance
- [ ] Create protocol-based service layer
- [ ] Use standard spacing values (4, 8, 12, 16, 20, 24, 32pt)
- [ ] Apply consistent card styling (white bg, 16pt radius, subtle shadow)
- [ ] Use SF Symbols for all icons
- [ ] Add haptic feedback to interactive elements
- [ ] Use `.animation(.spring())` for smooth transitions
- [ ] Follow established typography hierarchy
- [ ] Test on multiple screen sizes
- [ ] Add loading and error states
- [ ] Use `.task { await viewModel.loadData() }` for data loading

---

## Additional Resources

### File Locations

- **Colors**: `Billix/Utilities/ColorPalette.swift`
- **Styles**: `Billix/Utilities/CustomStyles.swift`
- **Shared Components**: `Billix/Utilities/Components/`
- **Models**: `Billix/Models/`
- **Services**: `Billix/Services/`
- **Features**: `Billix/Features/{FeatureName}/`

### Example Features

Study these well-implemented features as references:

- **Upload Feature**: `Billix/Features/Upload/` - Complete MVVM with dual flow architecture
- **Profile Feature**: `Billix/Features/Profile/` - Comprehensive component library
- **Home Feature**: `Billix/Features/Home/` - Complex multi-component layout

---

**Last Updated**: November 24, 2025
**Version**: 1.0
**For**: Billix iOS App (SwiftUI)
