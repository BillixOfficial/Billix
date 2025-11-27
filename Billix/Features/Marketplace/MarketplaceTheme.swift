//
//  MarketplaceTheme.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Design system for the Marketplace feature
/// Inspired by StockX x FB Marketplace x Fidelity
enum MarketplaceTheme {

    // MARK: - Colors

    enum Colors {
        // Primary palette
        static let primary = Color.billixMoneyGreen // #3D7A5A equivalent
        static let secondary = Color.billixPurple   // #9B7B9F
        static let accent = Color.billixGoldenAmber // #E8B54D

        // Semantic colors
        static let success = Color(hex: "#34A853")
        static let warning = Color(hex: "#E8B54D")
        static let danger = Color(hex: "#EA4335")
        static let info = Color(hex: "#4285F4")

        // Background hierarchy
        static let backgroundPrimary = Color.billixLightGreen
        static let backgroundSecondary = Color(hex: "#F5F9F5")
        static let backgroundCard = Color.white
        static let backgroundElevated = Color.white

        // Text hierarchy
        static let textPrimary = Color.billixDarkGreen
        static let textSecondary = Color.billixMediumGreen
        static let textTertiary = Color.billixLightGreenText
        static let textInverse = Color.white

        // Grade colors
        static func gradeColor(for grade: DealGrade) -> Color {
            switch grade {
            case .sTier: return Color(hex: "#FFD700") // Gold
            case .aPlus: return Color(hex: "#34A853") // Green
            case .a: return Color(hex: "#66BB6A")     // Light green
            case .b: return Color(hex: "#E8B54D")     // Yellow
            case .c: return Color(hex: "#FF9800")     // Orange
            case .d: return Color(hex: "#EA4335")     // Red
            }
        }

        // Match score ring colors
        static func matchScoreColor(for score: Int) -> Color {
            switch score {
            case 90...100: return success
            case 70..<90: return Color(hex: "#66BB6A")
            case 50..<70: return warning
            default: return danger
            }
        }
    }

    // MARK: - Gradients

    enum Gradients {
        static let sTierGold = LinearGradient(
            colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500"), Color(hex: "#FFD700")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardShine = LinearGradient(
            colors: [Color.white.opacity(0.3), Color.clear, Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let frostedOverlay = LinearGradient(
            colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography

    enum Typography {
        // Sizes
        static let hero: CGFloat = 32
        static let title: CGFloat = 24
        static let headline: CGFloat = 20
        static let body: CGFloat = 16
        static let callout: CGFloat = 14
        static let caption: CGFloat = 12
        static let micro: CGFloat = 10

        // Weights
        static let bold = Font.Weight.bold
        static let semibold = Font.Weight.semibold
        static let medium = Font.Weight.medium
        static let regular = Font.Weight.regular
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadows {
        static let low = Shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let high = Shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        static let glow = Shadow(color: Colors.primary.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
    }

    // MARK: - Card Dimensions

    enum CardSize {
        static let billCardWidth: CGFloat = UIScreen.main.bounds.width - 32
        static let billCardHeight: CGFloat = 420
        static let clusterCardHeight: CGFloat = 200
        static let compactCardHeight: CGFloat = 120
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies marketplace card styling with layered shadows
    func marketplaceCard(elevation: MarketplaceCardElevation = .medium) -> some View {
        self
            .background(MarketplaceTheme.Colors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl))
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }

    /// Applies frosted glass effect for premium elements
    func marketplaceGlass() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg))
    }

    /// Applies grade pill styling
    func gradePill(for grade: DealGrade) -> some View {
        self
            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
            .foregroundStyle(grade == .sTier ? Color.black : .white)
            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
            .padding(.vertical, MarketplaceTheme.Spacing.xxs)
            .background(
                grade == .sTier
                    ? AnyShapeStyle(MarketplaceTheme.Gradients.sTierGold)
                    : AnyShapeStyle(MarketplaceTheme.Colors.gradeColor(for: grade))
            )
            .clipShape(Capsule())
    }

    /// Applies marketplace section header styling
    func marketplaceSectionHeader() -> some View {
        self
            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
    }
}

enum MarketplaceCardElevation {
    case low, medium, high

    var shadow: MarketplaceTheme.Shadow {
        switch self {
        case .low: return MarketplaceTheme.Shadows.low
        case .medium: return MarketplaceTheme.Shadows.medium
        case .high: return MarketplaceTheme.Shadows.high
        }
    }
}

// MARK: - Reusable Components

/// Circular progress ring for match scores
struct MatchScoreRing: View {
    let score: Int
    let size: CGFloat

    private var progress: Double {
        Double(score) / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    MarketplaceTheme.Colors.matchScoreColor(for: score).opacity(0.2),
                    lineWidth: 4
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    MarketplaceTheme.Colors.matchScoreColor(for: score),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(score)%")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

/// Grade pill badge
struct GradePill: View {
    let grade: DealGrade

    var body: some View {
        Text(grade.rawValue)
            .gradePill(for: grade)
    }
}

/// Friction level indicator
struct FrictionMeter: View {
    let level: FrictionLevel

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Text(level.emoji)
            Text(level.rawValue)
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            Text("–")
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            Text(level.description)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }
}

/// Live activity pulse indicator
struct LivePulse: View {
    let viewingCount: Int
    let unlocksPerHour: Int

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.md) {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Circle()
                    .fill(MarketplaceTheme.Colors.danger)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                Text("\(viewingCount) viewing")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            }

            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(MarketplaceTheme.Colors.warning)
                Text("\(unlocksPerHour) unlocks/hr")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            }
        }
        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        .onAppear { isPulsing = true }
    }
}

/// Verified badge
struct VerifiedBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(MarketplaceTheme.Colors.info)
            Text("Verified")
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }
}

/// Eligibility pill
struct EligibilityPill: View {
    let type: EligibilityType

    private var backgroundColor: Color {
        switch type {
        case .newCustomer: return MarketplaceTheme.Colors.info.opacity(0.15)
        case .existing: return MarketplaceTheme.Colors.success.opacity(0.15)
        case .anyCustomer: return MarketplaceTheme.Colors.secondary.opacity(0.15)
        case .switchOnly: return MarketplaceTheme.Colors.warning.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch type {
        case .newCustomer: return MarketplaceTheme.Colors.info
        case .existing: return MarketplaceTheme.Colors.success
        case .anyCustomer: return MarketplaceTheme.Colors.secondary
        case .switchOnly: return MarketplaceTheme.Colors.warning
        }
    }

    var body: some View {
        Text(type.rawValue)
            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, MarketplaceTheme.Spacing.xs)
            .padding(.vertical, MarketplaceTheme.Spacing.xxxs)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}
