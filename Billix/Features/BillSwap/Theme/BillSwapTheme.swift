//
//  BillSwapTheme.swift
//  Billix
//
//  Centralized theme constants for Bill Swap feature
//  Matches Home page calm aesthetic
//

import SwiftUI

// MARK: - Bill Swap Theme

enum BillSwapTheme {

    // MARK: - Backgrounds

    static let background = Color(hex: "F7F9F8")
    static let cardBackground = Color.white
    static let secondaryBackground = Color(hex: "F0F4F2")

    // MARK: - Text Colors

    static let primaryText = Color(hex: "2D3B35")
    static let secondaryText = Color(hex: "8B9A94")
    static let accentText = Color(hex: "5B8A6B")
    static let mutedText = Color(hex: "A8B5AF")

    // MARK: - Accent Colors

    static let accent = Color(hex: "5B8A6B")
    static let accentLight = Color(hex: "5B8A6B").opacity(0.12)
    static let accentBackground = Color(hex: "5B8A6B").opacity(0.08)

    // MARK: - Status Colors

    static let statusPending = Color(hex: "E8A54B")      // Orange - awaiting action
    static let statusActive = Color(hex: "5B8A6B")       // Green - in progress
    static let statusComplete = Color(hex: "4CAF7A")     // Bright green - done
    static let statusDispute = Color(hex: "E07A6B")      // Coral red - issues
    static let statusCancelled = Color(hex: "9CA3AF")    // Gray - cancelled
    static let statusLocked = Color(hex: "3B82F6")       // Blue - locked in

    // MARK: - Category Colors

    static let categoryElectric = Color(hex: "F59E0B")   // Amber
    static let categoryGas = Color(hex: "EF4444")        // Red
    static let categoryWater = Color(hex: "3B82F6")      // Blue
    static let categoryInternet = Color(hex: "8B5CF6")   // Purple
    static let categoryPhone = Color(hex: "06B6D4")      // Cyan
    static let categoryOther = Color(hex: "6B7280")      // Gray

    // MARK: - Card Styling

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardShadow = Color.black.opacity(0.03)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2

    // MARK: - Spacing

    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 12
    static let tightSpacing: CGFloat = 8
    static let microSpacing: CGFloat = 4

    // MARK: - Typography

    static let headerFont = Font.system(size: 15, weight: .semibold)
    static let titleFont = Font.system(size: 17, weight: .semibold)
    static let bodyFont = Font.system(size: 14, weight: .regular)
    static let captionFont = Font.system(size: 11, weight: .medium)
    static let microFont = Font.system(size: 10, weight: .semibold)

    // MARK: - Icons

    static let iconSizeSmall: CGFloat = 14
    static let iconSizeMedium: CGFloat = 18
    static let iconSizeLarge: CGFloat = 24
    static let iconSizeXL: CGFloat = 32

    // MARK: - Avatar/Circle Sizes

    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 44
    static let avatarLarge: CGFloat = 56

    // MARK: - Animation Durations

    static let animationFast: Double = 0.2
    static let animationNormal: Double = 0.3
    static let animationSlow: Double = 0.5

    // MARK: - Button Builders

    /// Create a primary button with icon and title
    @ViewBuilder
    static func PrimaryButton(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                }
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accent)
            .cornerRadius(12)
        }
    }

    /// Create a secondary (outline) button with icon and title
    @ViewBuilder
    static func SecondaryButton(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(statusDispute)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(statusDispute.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Helper Functions

    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "electric", "electricity":
            return categoryElectric
        case "gas", "natural gas":
            return categoryGas
        case "water":
            return categoryWater
        case "internet", "wifi":
            return categoryInternet
        case "phone", "mobile":
            return categoryPhone
        default:
            return categoryOther
        }
    }

    static func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "electric", "electricity":
            return "bolt.fill"
        case "gas", "natural gas":
            return "flame.fill"
        case "water":
            return "drop.fill"
        case "internet", "wifi":
            return "wifi"
        case "phone", "mobile":
            return "iphone"
        default:
            return "doc.text.fill"
        }
    }

    static func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "offered", "pending", "awaiting":
            return statusPending
        case "locked", "accepted":
            return statusLocked
        case "active", "in_progress", "paying", "proving":
            return statusActive
        case "completed", "done", "verified":
            return statusComplete
        case "disputed", "failed":
            return statusDispute
        case "cancelled", "expired":
            return statusCancelled
        default:
            return secondaryText
        }
    }
}

// MARK: - View Modifiers

extension View {

    /// Apply standard card styling
    func billSwapCard() -> some View {
        self
            .padding(BillSwapTheme.cardPadding)
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
    }

    /// Apply accent-tinted card styling
    func billSwapAccentCard() -> some View {
        self
            .padding(BillSwapTheme.cardPadding)
            .background(BillSwapTheme.accentBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
    }

    /// Apply section header styling
    func billSwapSectionHeader() -> some View {
        self
            .font(BillSwapTheme.captionFont)
            .foregroundColor(BillSwapTheme.secondaryText)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    /// Staggered appear animation
    func staggeredAppear(index: Int, isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8)
                    .delay(Double(index) * 0.08),
                value: isVisible
            )
    }
}

// MARK: - Button Styles

struct BillSwapPrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? BillSwapTheme.secondaryText : BillSwapTheme.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BillSwapSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(BillSwapTheme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(BillSwapTheme.accentLight)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Status Badge View

struct SwapStatusBadge: View {
    let status: String
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: statusIcon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(displayText)
                .font(BillSwapTheme.captionFont)
        }
        .foregroundColor(BillSwapTheme.statusColor(for: status))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(BillSwapTheme.statusColor(for: status).opacity(0.12))
        )
    }

    private var statusIcon: String {
        switch status.lowercased() {
        case "offered", "pending":
            return "clock.fill"
        case "locked", "accepted":
            return "lock.fill"
        case "active", "in_progress":
            return "arrow.triangle.2.circlepath"
        case "completed", "done", "verified":
            return "checkmark.circle.fill"
        case "disputed":
            return "exclamationmark.triangle.fill"
        case "cancelled", "expired":
            return "xmark.circle.fill"
        default:
            return "circle.fill"
        }
    }

    private var displayText: String {
        switch status.lowercased() {
        case "in_progress":
            return "In Progress"
        default:
            return status.capitalized
        }
    }
}

// MARK: - Category Icon View

struct CategoryIcon: View {
    let category: String
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(BillSwapTheme.categoryColor(for: category).opacity(0.12))
                .frame(width: size, height: size)

            Image(systemName: BillSwapTheme.categoryIcon(for: category))
                .font(.system(size: size * 0.4))
                .foregroundColor(BillSwapTheme.categoryColor(for: category))
        }
    }
}

// MARK: - Empty State View (Redesigned)

struct BillSwapEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Decorative icon with gradient background
            ZStack {
                // Outer ring animation hint
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                BillSwapTheme.accent.opacity(0.3),
                                BillSwapTheme.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)

                // Inner circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                BillSwapTheme.accent.opacity(0.15),
                                BillSwapTheme.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BillSwapTheme.accent, BillSwapTheme.accent.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BillSwapTheme.primaryText)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(BillSwapTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text(actionTitle)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [BillSwapTheme.accent, BillSwapTheme.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SwapStatusBadge(status: "pending")
        SwapStatusBadge(status: "locked")
        SwapStatusBadge(status: "completed")
        SwapStatusBadge(status: "disputed")

        CategoryIcon(category: "electric")
        CategoryIcon(category: "water")
        CategoryIcon(category: "gas")

        BillSwapEmptyState(
            icon: "rectangle.stack",
            title: "No Bills Yet",
            message: "Add your first bill to start swapping with other users.",
            actionTitle: "Add Bill"
        ) {}
    }
    .padding()
    .background(BillSwapTheme.background)
}
