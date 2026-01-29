//
//  GiftCardAmountSheet.swift
//  Billix
//
//  Created by Claude Code on 12/22/24.
//  Bottom sheet for selecting gift card amounts ($5, $10, $15, Custom)
//

import SwiftUI

// MARK: - Gift Card Amount Selection Sheet

struct GiftCardAmountSheet: View {
    // MARK: - Properties
    let brandGroup: String
    let brandName: String
    let availableAmounts: [Reward]  // Pre-filtered by brand
    let userPoints: Int
    let onSelectAmount: (Reward) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReward: Reward?
    @State private var showingCustomAmount: Bool = false
    @State private var customAmountText: String = ""
    @State private var customAmount: Int = 5
    @FocusState private var isCustomFieldFocused: Bool

    // MARK: - Computed Properties
    private var sortedAmounts: [Reward] {
        availableAmounts.sorted { ($0.dollarValue ?? 0) < ($1.dollarValue ?? 0) }
    }

    private var brandColor: Color {
        guard let firstReward = availableAmounts.first else {
            return .billixDarkGreen
        }
        return Color(hex: firstReward.accentColor)
    }

    private var canAfford: Bool {
        if showingCustomAmount {
            return userPoints >= customPointsCost
        }
        guard let reward = selectedReward else { return false }
        return userPoints >= reward.pointsCost
    }

    private var customPointsCost: Int {
        customAmount * 2000  // 2,000 points = $1
    }

    private var isCustomAmountValid: Bool {
        customAmount >= 5 && customAmount <= 50
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                // Header: Brand Icon + Name
                headerSection

                // Amount Chips (Preset: $5, $10, $15, Custom)
                amountChipsSection

                // Custom Amount Input (if selected)
                if showingCustomAmount {
                    customAmountSection
                }

                Spacer()

                // Continue Button (shows points needed/ready state)
                continueButton
            }
            .padding(20)
            .background(Color.white)

            // X Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.billixMediumGreen.opacity(0.1))
                    )
            }
            .padding(16)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Brand Icon Circle
            ZStack {
                Circle()
                    .fill(brandColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: availableAmounts.first?.iconName ?? "gift.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(brandColor)
            }

            Text("Select Amount")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            Text(brandName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.billixMediumGreen)
        }
    }

    private var amountChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHOOSE VALUE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.billixMediumGreen)
                .textCase(.uppercase)
                .tracking(0.5)

            // 2x2 Grid Layout - Uses vertical space properly
            VStack(spacing: 12) {
                // Row 1: $5 and $10
                HStack(spacing: 12) {
                    if sortedAmounts.count > 0 {
                        GridAmountCard(
                            reward: sortedAmounts[0],
                            isSelected: selectedReward?.id == sortedAmounts[0].id && !showingCustomAmount,
                            canAfford: userPoints >= sortedAmounts[0].pointsCost,
                            brandColor: brandColor,
                            showBadge: false,
                            onTap: {
                                selectedReward = sortedAmounts[0]
                                showingCustomAmount = false
                                isCustomFieldFocused = false
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        )
                    }

                    if sortedAmounts.count > 1 {
                        GridAmountCard(
                            reward: sortedAmounts[1],
                            isSelected: selectedReward?.id == sortedAmounts[1].id && !showingCustomAmount,
                            canAfford: userPoints >= sortedAmounts[1].pointsCost,
                            brandColor: brandColor,
                            showBadge: true, // Most popular
                            onTap: {
                                selectedReward = sortedAmounts[1]
                                showingCustomAmount = false
                                isCustomFieldFocused = false
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        )
                    }
                }

                // Row 2: $15 and Custom
                HStack(spacing: 12) {
                    if sortedAmounts.count > 2 {
                        GridAmountCard(
                            reward: sortedAmounts[2],
                            isSelected: selectedReward?.id == sortedAmounts[2].id && !showingCustomAmount,
                            canAfford: userPoints >= sortedAmounts[2].pointsCost,
                            brandColor: brandColor,
                            showBadge: false,
                            onTap: {
                                selectedReward = sortedAmounts[2]
                                showingCustomAmount = false
                                isCustomFieldFocused = false
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        )
                    }

                    // Custom amount card (dashed border style)
                    GridCustomCard(
                        isSelected: showingCustomAmount,
                        brandColor: brandColor,
                        onTap: {
                            showingCustomAmount = true
                            selectedReward = nil
                            isCustomFieldFocused = true
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    )
                }
            }
        }
    }

    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENTER AMOUNT ($5-$50)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.billixMediumGreen)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 12) {
                // Dollar sign
                Text("$")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                // Amount input
                TextField("5", value: $customAmount, format: .number)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
                    .keyboardType(.numberPad)
                    .focused($isCustomFieldFocused)
                    .frame(maxWidth: 100)
                    .onChange(of: customAmount) { oldValue, newValue in
                        // Clamp between 5 and 50
                        if newValue < 5 {
                            customAmount = 5
                        } else if newValue > 50 {
                            customAmount = 50
                        }
                    }

                Spacer()

                // Points display
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.billixMediumGreen)

                        Text("\(customPointsCost)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                    }

                    Text("points")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen.opacity(0.7))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(brandColor.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCustomAmountValid ? brandColor : Color.red, lineWidth: 2)
            )

            if !isCustomAmountValid {
                Text("Amount must be between $5 and $50")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }

    private var continueButton: some View {
        VStack(spacing: 12) {
            // Affordability indicator
            if let reward = selectedReward {
                AffordabilityIndicator(
                    reward: reward,
                    userPoints: userPoints,
                    brandColor: brandColor
                )
            } else if showingCustomAmount {
                CustomAffordabilityIndicator(
                    amount: customAmount,
                    pointsCost: customPointsCost,
                    userPoints: userPoints,
                    brandColor: brandColor
                )
            }

            // Primary CTA
            Button {
                if showingCustomAmount {
                    // Create a custom reward object for the flow
                    let customReward = Reward(
                        id: UUID(),
                        type: .giftCard,
                        category: .giftCard,
                        title: "$\(customAmount) \(brandName) Gift Card",
                        description: "Shop at \(brandName)",
                        pointsCost: customPointsCost,
                        brand: brandName,
                        brandGroup: brandGroup,
                        dollarValue: Double(customAmount),
                        iconName: availableAmounts.first?.iconName ?? "gift.fill",
                        accentColor: availableAmounts.first?.accentColor ?? "#5b8a6b"
                    )
                    onSelectAmount(customReward)
                } else if let reward = selectedReward {
                    onSelectAmount(reward)
                }
                dismiss()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isSelectionMade ?
                                [brandColor, brandColor.opacity(0.8)] :
                                [.gray.opacity(0.3), .gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .disabled(!isSelectionMade || (showingCustomAmount && !isCustomAmountValid))
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
        }
    }

    private var buttonTitle: String {
        if !isSelectionMade {
            return "Select an Amount"
        }

        if showingCustomAmount {
            return "Confirm: $\(customAmount)"
        } else if let reward = selectedReward, let value = reward.dollarValue {
            return "Confirm: $\(Int(value))"
        }

        return "Continue"
    }

    private var isSelectionMade: Bool {
        selectedReward != nil || (showingCustomAmount && isCustomAmountValid)
    }
}

// MARK: - Grid Amount Card (2x2 Layout)

struct GridAmountCard: View {
    let reward: Reward
    let isSelected: Bool
    let canAfford: Bool
    let brandColor: Color
    let showBadge: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // "MOST POPULAR" badge (top)
                if showBadge {
                    Text("MOST POPULAR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.billixMoneyGreen)
                        )
                } else {
                    Spacer()
                        .frame(height: 17) // Balance spacing
                }

                Spacer()

                // Price (large, bold)
                Text(reward.formattedValue ?? "$0")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(cardForegroundColor)

                // Points cost (small, grey)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))

                    Text("\(reward.pointsCost) pts")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(cardSecondaryColor)

                Spacer()

                // Affordability hint
                if !canAfford {
                    Text("Need more")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackgroundColor)
                    .shadow(color: shadowColor, radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(cardBorderColor, lineWidth: isSelected ? 3 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }

    private var cardBackgroundColor: Color {
        if isSelected {
            return brandColor.opacity(0.08)
        } else {
            return Color.white
        }
    }

    private var cardForegroundColor: Color {
        if isSelected {
            return brandColor
        } else if canAfford {
            return .billixDarkGreen
        } else {
            return .billixMediumGreen.opacity(0.5)
        }
    }

    private var cardSecondaryColor: Color {
        if isSelected {
            return brandColor.opacity(0.8)
        } else {
            return .billixMediumGreen
        }
    }

    private var cardBorderColor: Color {
        isSelected ? brandColor : Color.clear
    }

    private var shadowColor: Color {
        if isSelected {
            return brandColor.opacity(0.3)
        } else {
            return Color.black.opacity(0.08)
        }
    }
}

// MARK: - Grid Custom Card (Dashed Border)

struct GridCustomCard: View {
    let isSelected: Bool
    let brandColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Spacer()
                    .frame(height: 17) // Balance spacing with badge

                Spacer()

                // Keyboard icon
                Image(systemName: "keyboard")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(cardForegroundColor)

                // "Custom" label
                Text("Custom")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(cardForegroundColor)

                // Range hint
                Text("$5 - $50")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(cardSecondaryColor)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                // Dashed border effect
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: isSelected ? 3 : 2,
                            dash: isSelected ? [] : [8, 4]
                        )
                    )
                    .foregroundColor(cardBorderColor)
            )
            .shadow(color: shadowColor, radius: isSelected ? 8 : 0, x: 0, y: isSelected ? 4 : 0)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }

    private var cardBackgroundColor: Color {
        if isSelected {
            return brandColor.opacity(0.08)
        } else {
            return Color.white
        }
    }

    private var cardForegroundColor: Color {
        isSelected ? brandColor : .billixDarkGreen
    }

    private var cardSecondaryColor: Color {
        if isSelected {
            return brandColor.opacity(0.8)
        } else {
            return .billixMediumGreen
        }
    }

    private var cardBorderColor: Color {
        if isSelected {
            return brandColor
        } else {
            return .billixMediumGreen.opacity(0.4)
        }
    }

    private var shadowColor: Color {
        if isSelected {
            return brandColor.opacity(0.3)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Amount Chip Component (Deprecated - keeping for compatibility)

struct AmountChip: View {
    let reward: Reward
    let isSelected: Bool
    let canAfford: Bool
    let brandColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Dollar value (large)
                Text(reward.formattedValue ?? "$0")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(chipForegroundColor)

                // Points cost (small)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))

                    Text("\(reward.pointsCost)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(chipForegroundColor.opacity(0.8))
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(chipBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(chipBorderColor, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }

    private var chipBackgroundColor: Color {
        if isSelected {
            return brandColor.opacity(0.15)
        } else if canAfford {
            return Color.white
        } else {
            return Color.gray.opacity(0.05)
        }
    }

    private var chipForegroundColor: Color {
        if isSelected {
            return brandColor
        } else if canAfford {
            return .billixDarkGreen
        } else {
            return .billixMediumGreen.opacity(0.5)
        }
    }

    private var chipBorderColor: Color {
        if isSelected {
            return brandColor
        } else if canAfford {
            return .billixBorderGreen
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Affordability Indicator

struct AffordabilityIndicator: View {
    let reward: Reward
    let userPoints: Int
    let brandColor: Color

    private var canAfford: Bool {
        userPoints >= reward.pointsCost
    }

    private var pointsNeeded: Int {
        max(reward.pointsCost - userPoints, 0)
    }

    var body: some View {
        HStack(spacing: 8) {
            if canAfford {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.billixMoneyGreen)

                Text("You can afford this!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixMoneyGreen)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("Need \(pointsNeeded) more points")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(canAfford ? Color.billixMoneyGreen.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Custom Amount Chip

struct CustomAmountChip: View {
    let isSelected: Bool
    let brandColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Custom icon
                Image(systemName: "keyboard")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(chipForegroundColor)

                // Label
                Text("Custom")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(chipForegroundColor)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(chipBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(chipBorderColor, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }

    private var chipBackgroundColor: Color {
        if isSelected {
            return brandColor.opacity(0.15)
        } else {
            return Color.white
        }
    }

    private var chipForegroundColor: Color {
        if isSelected {
            return brandColor
        } else {
            return .billixDarkGreen
        }
    }

    private var chipBorderColor: Color {
        if isSelected {
            return brandColor
        } else {
            return .billixBorderGreen
        }
    }
}

// MARK: - Custom Affordability Indicator

struct CustomAffordabilityIndicator: View {
    let amount: Int
    let pointsCost: Int
    let userPoints: Int
    let brandColor: Color

    private var canAfford: Bool {
        userPoints >= pointsCost
    }

    private var pointsNeeded: Int {
        max(pointsCost - userPoints, 0)
    }

    var body: some View {
        HStack(spacing: 8) {
            if canAfford {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.billixMoneyGreen)

                Text("You can afford this!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixMoneyGreen)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("Need \(pointsNeeded) more points")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(canAfford ? Color.billixMoneyGreen.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    GiftCardAmountSheet(
        brandGroup: "target",
        brandName: "Target",
        availableAmounts: [
            Reward(
                id: UUID(),
                type: .giftCard,
                category: .giftCard,
                title: "$5 Target Gift Card",
                description: "Shop at Target stores or online",
                pointsCost: 10000,
                brand: "Target",
                brandGroup: "target",
                dollarValue: 5,
                iconName: "target",
                accentColor: "#CC0000"
            ),
            Reward(
                id: UUID(),
                type: .giftCard,
                category: .giftCard,
                title: "$10 Target Gift Card",
                description: "Shop at Target stores or online",
                pointsCost: 20000,
                brand: "Target",
                brandGroup: "target",
                dollarValue: 10,
                iconName: "target",
                accentColor: "#CC0000"
            ),
            Reward(
                id: UUID(),
                type: .giftCard,
                category: .giftCard,
                title: "$15 Target Gift Card",
                description: "Shop at Target stores or online",
                pointsCost: 30000,
                brand: "Target",
                brandGroup: "target",
                dollarValue: 15,
                iconName: "target",
                accentColor: "#CC0000"
            )
        ],
        userPoints: 25000,
        onSelectAmount: { reward in
        }
    )
}
