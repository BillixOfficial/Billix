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

    // MARK: - Icons (Professional SF Symbols)

    enum Icons {
        // Status
        static let verified = "checkmark.seal.fill"
        static let pending = "clock.badge"
        static let active = "arrow.triangle.2.circlepath"
        static let completed = "checkmark.circle.fill"
        static let disputed = "exclamationmark.triangle.fill"
        static let expired = "clock.badge.xmark"

        // Actions
        static let chat = "bubble.left.and.bubble.right"
        static let upload = "arrow.up.doc"
        static let camera = "camera.fill"
        static let proof = "doc.text.image"
        static let timeline = "list.bullet.clipboard"
        static let info = "info.circle"
        static let settings = "gearshape"

        // Trust & Security
        static let trust = "shield.checkmark"
        static let lock = "lock.shield"
        static let unlock = "lock.open"
        static let warning = "exclamationmark.triangle"
        static let safe = "checkmark.shield"

        // User & Profile
        static let user = "person.circle"
        static let partner = "person.2"
        static let yourTurn = "hand.point.right.fill"
        static let waiting = "hourglass"

        // Swap Flow
        static let handshake = "hand.raised.fingers.spread"
        static let exchange = "arrow.left.arrow.right"
        static let pay = "creditcard"
        static let receive = "arrow.down.circle"

        // Bills
        static let bill = "doc.text"
        static let amount = "dollarsign.circle"
        static let dueDate = "calendar"
        static let provider = "building.2"

        // Progress
        static let step1 = "1.circle.fill"
        static let step2 = "2.circle.fill"
        static let step3 = "3.circle.fill"
        static let step4 = "4.circle.fill"
        static let step5 = "5.circle.fill"
        static let stepIncomplete = "circle"
        static let stepCurrent = "circle.dotted"

        // Tier badges
        static let tier1 = "star"
        static let tier2 = "star.leadinghalf.filled"
        static let tier3 = "star.fill"
        static let tier4 = "star.circle.fill"
    }

    // MARK: - Tier Configuration

    enum Tiers {
        /// Conservative tier limits (user-approved)
        static func maxAmount(for tier: Int) -> Decimal {
            switch tier {
            case 1: return 25    // New users - max $25
            case 2: return 50    // Established - max $50
            case 3: return 100   // Trusted - max $100
            case 4: return 150   // Veteran - max $150
            default: return 25
            }
        }

        /// Required swaps to reach each tier (harder progression: 5→15→35→50)
        static func requiredSwaps(for tier: Int) -> Int {
            switch tier {
            case 1: return 0    // Starting tier
            case 2: return 5    // Need 5 successful swaps for Tier 2
            case 3: return 15   // Need 15 successful swaps for Tier 3
            case 4: return 35   // Need 35 successful swaps for Tier 4
            default: return 0
            }
        }

        /// Swaps needed to reach next tier from current tier
        static func swapsToNextTier(currentTier: Int, completedSwaps: Int) -> Int {
            let nextTierRequirement: Int
            switch currentTier {
            case 1: nextTierRequirement = 5
            case 2: nextTierRequirement = 15
            case 3: nextTierRequirement = 35
            case 4: return 0 // Already max tier
            default: nextTierRequirement = 5
            }
            return max(0, nextTierRequirement - completedSwaps)
        }

        static func tierName(_ tier: Int) -> String {
            switch tier {
            case 1: return "New"
            case 2: return "Established"
            case 3: return "Trusted"
            case 4: return "Veteran"
            default: return "New"
            }
        }

        static func tierDescription(_ tier: Int) -> String {
            switch tier {
            case 1: return "Build trust with your first 5 swaps"
            case 2: return "You've proven yourself! Keep building."
            case 3: return "A trusted member of the community"
            case 4: return "A role model in the BillSwap community"
            default: return "Build trust with your first 5 swaps"
            }
        }

        static func tierIcon(_ tier: Int) -> String {
            switch tier {
            case 1: return Icons.tier1
            case 2: return Icons.tier2
            case 3: return Icons.tier3
            case 4: return Icons.tier4
            default: return Icons.tier1
            }
        }

        static func tierColor(_ tier: Int) -> Color {
            switch tier {
            case 1: return Colors.warning
            case 2: return Colors.matched
            case 3: return Colors.success
            case 4: return Colors.gold
            default: return Colors.warning
            }
        }

        /// Tier-specific tips shown in advancement modal
        static func tierTip(_ tier: Int) -> String {
            switch tier {
            case 2: return "You can now swap bills up to $50. Keep building trust!"
            case 3: return "You're trusted! $100 limit unlocked. Consider verifying your ID for even higher limits."
            case 4: return "Veteran status! Max $150 swaps. You're a role model in the community."
            default: return "Complete swaps successfully to unlock higher limits."
            }
        }
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
