//
//  SwapTheme.swift
//  Billix
//
//  Theme colors, fonts, and styling for the BillSwap feature
//

import SwiftUI

// MARK: - SwapTheme Namespace

enum SwapTheme {

    // MARK: - Colors

    enum Colors {
        /// Primary action color
        static let primary = Color.billixDarkTeal

        /// Success/money green
        static let success = Color.billixMoneyGreen

        /// Warning/pending color
        static let warning = Color.orange

        /// Danger/error color
        static let danger = Color.red

        /// Gold/premium color
        static let gold = Color.billixGoldenAmber

        /// Background colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.systemGray6)
        static let tertiaryBackground = Color(.systemGray5)

        /// Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)

        /// Status colors
        static let unmatched = Color.orange
        static let matched = Color.blue
        static let active = Color.billixDarkTeal
        static let completed = Color.billixMoneyGreen
        static let disputed = Color.red

        /// Trust score gradient
        static func trustGradient(for score: Int) -> LinearGradient {
            let color = trustColor(for: score)
            return LinearGradient(
                colors: [color.opacity(0.8), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func trustColor(for score: Int) -> Color {
            if score >= 80 {
                return .green
            } else if score >= 60 {
                return success
            } else if score >= 40 {
                return .yellow
            } else if score >= 20 {
                return .orange
            } else {
                return .red
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17)
        static let callout = Font.system(size: 16)
        static let subheadline = Font.system(size: 15)
        static let footnote = Font.system(size: 13)
        static let caption = Font.system(size: 12)
        static let caption2 = Font.system(size: 11)

        /// Monospaced font for amounts
        static let amount = Font.system(size: 24, weight: .bold, design: .monospaced)
        static let amountSmall = Font.system(size: 18, weight: .semibold, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let extraLarge: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }

    // MARK: - Animations

    enum Animations {
        static let quick = Animation.easeOut(duration: 0.15)
        static let standard = Animation.easeInOut(duration: 0.25)
        static let slow = Animation.easeInOut(duration: 0.4)
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply swap card styling
    func swapCardStyle() -> some View {
        self
            .padding(SwapTheme.Spacing.lg)
            .background(SwapTheme.Colors.background)
            .cornerRadius(SwapTheme.CornerRadius.large)
            .shadow(
                color: SwapTheme.Shadows.medium.color,
                radius: SwapTheme.Shadows.medium.radius,
                x: SwapTheme.Shadows.medium.x,
                y: SwapTheme.Shadows.medium.y
            )
    }

    /// Apply swap section styling
    func swapSectionStyle() -> some View {
        self
            .padding(SwapTheme.Spacing.lg)
            .background(SwapTheme.Colors.secondaryBackground)
            .cornerRadius(SwapTheme.CornerRadius.large)
    }

    /// Apply primary button styling
    func swapPrimaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, SwapTheme.Spacing.md)
            .background(SwapTheme.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    /// Apply secondary button styling
    func swapSecondaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, SwapTheme.Spacing.md)
            .background(SwapTheme.Colors.secondaryBackground)
            .foregroundColor(SwapTheme.Colors.primary)
            .cornerRadius(SwapTheme.CornerRadius.medium)
    }
}

// MARK: - Preview

#Preview("Swap Theme") {
    ScrollView {
        VStack(spacing: 24) {
            // Colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(SwapTheme.Typography.headline)

                HStack(spacing: 8) {
                    Circle().fill(SwapTheme.Colors.primary).frame(width: 40, height: 40)
                    Circle().fill(SwapTheme.Colors.success).frame(width: 40, height: 40)
                    Circle().fill(SwapTheme.Colors.warning).frame(width: 40, height: 40)
                    Circle().fill(SwapTheme.Colors.danger).frame(width: 40, height: 40)
                    Circle().fill(SwapTheme.Colors.gold).frame(width: 40, height: 40)
                }
            }
            .swapSectionStyle()

            // Typography
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography")
                    .font(SwapTheme.Typography.headline)

                Text("Large Title").font(SwapTheme.Typography.largeTitle)
                Text("Title").font(SwapTheme.Typography.title)
                Text("Headline").font(SwapTheme.Typography.headline)
                Text("Body").font(SwapTheme.Typography.body)
                Text("$125.50").font(SwapTheme.Typography.amount)
            }
            .swapSectionStyle()

            // Cards
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Style")
                    .font(SwapTheme.Typography.headline)

                Text("This is a swap card")
                    .swapCardStyle()
            }
            .swapSectionStyle()

            // Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Buttons")
                    .font(SwapTheme.Typography.headline)

                Text("Primary Button")
                    .fontWeight(.semibold)
                    .swapPrimaryButtonStyle()

                Text("Secondary Button")
                    .fontWeight(.semibold)
                    .swapSecondaryButtonStyle()
            }
            .swapSectionStyle()
        }
        .padding()
    }
}
