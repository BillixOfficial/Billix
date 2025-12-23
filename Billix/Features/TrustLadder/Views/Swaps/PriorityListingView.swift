//
//  PriorityListingView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for managing priority listings (swap boosting)
//

import SwiftUI

struct PriorityListingView: View {
    let swap: MultiPartySwap
    let onBoostApplied: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var swapService = MultiPartySwapService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var selectedBoost: BoostOption = .standard
    @State private var isBoosting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        boostHeader

                        // Boost options
                        boostOptionsSection

                        // Benefits
                        benefitsSection

                        // Error
                        if let error = errorMessage {
                            errorBanner(error)
                        }

                        // Boost button
                        boostButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Priority Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
            }
            .alert("Boost Applied!", isPresented: $showSuccess) {
                Button("Great") {
                    onBoostApplied()
                    dismiss()
                }
            } message: {
                Text("Your swap is now boosted and will appear at the top of search results for \(selectedBoost.durationHours) hours.")
            }
        }
    }

    // MARK: - Boost Header

    private var boostHeader: some View {
        VStack(spacing: 16) {
            // Rocket icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("Boost Your Swap")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(primaryText)

                Text("Get up to \(selectedBoost.formattedMultiplier) more visibility")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }

            // Current swap info
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(swap.formattedTargetAmount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryText)
                    Text("Target")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                VStack(spacing: 2) {
                    Text("\(Int(swap.fillPercentage * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryText)
                    Text("Filled")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                VStack(spacing: 2) {
                    Text(swap.type?.displayName ?? "Swap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryText)
                    Text("Type")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Boost Options

    private var boostOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Boost Level")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            VStack(spacing: 10) {
                ForEach(BoostOption.allCases) { option in
                    boostOptionCard(option)
                }
            }
        }
    }

    private func boostOptionCard(_ option: BoostOption) -> some View {
        let isSelected = selectedBoost == option
        let hasAccess = option.requiredTier == nil ||
                        subscriptionService.currentTier.tierLevel >= (option.requiredTier?.tierLevel ?? 0)

        return Button {
            if hasAccess {
                selectedBoost = option
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? option.color : option.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : option.color)
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(option.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryText)

                        if option == .turbo {
                            Text("POPULAR")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(3)
                        }
                    }

                    Text("\(option.formattedMultiplier) visibility • \(option.durationHours)h")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }

                Spacer()

                // Lock or checkmark
                if !hasAccess {
                    VStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(secondaryText)
                        if let tier = option.requiredTier {
                            Text(tier.displayName)
                                .font(.system(size: 9))
                                .foregroundColor(tier.color)
                        }
                    }
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(option.color)
                }
            }
            .padding()
            .background(isSelected ? option.color.opacity(0.15) : cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? option.color : Color.clear, lineWidth: 2)
            )
            .opacity(hasAccess ? 1 : 0.6)
        }
        .disabled(!hasAccess)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You Get")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            VStack(spacing: 8) {
                benefitRow(
                    icon: "arrow.up.circle.fill",
                    title: "Top Placement",
                    description: "Your swap appears first in search results"
                )

                benefitRow(
                    icon: "flame.fill",
                    title: "Hot Badge",
                    description: "Eye-catching badge that attracts attention"
                )

                benefitRow(
                    icon: "bell.badge.fill",
                    title: "Priority Notifications",
                    description: "Matching users get notified immediately"
                )

                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "\(selectedBoost.formattedMultiplier) More Views",
                    description: "Increased visibility to potential partners"
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(selectedBoost.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.red)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - Boost Button

    private var boostButton: some View {
        VStack(spacing: 8) {
            Button {
                applyBoost()
            } label: {
                HStack {
                    if isBoosting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "flame.fill")
                        Text("Apply \(selectedBoost.name) Boost")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [selectedBoost.color, selectedBoost.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .disabled(isBoosting)

            Text("Boost lasts for \(selectedBoost.durationHours) hours")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
    }

    // MARK: - Actions

    private func applyBoost() {
        isBoosting = true
        errorMessage = nil

        Task {
            do {
                try await swapService.createPriorityListing(
                    swapId: swap.id,
                    boostMultiplier: selectedBoost.multiplier,
                    durationHours: selectedBoost.durationHours
                )
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isBoosting = false
        }
    }
}

// MARK: - Boost Option

enum BoostOption: String, CaseIterable, Identifiable {
    case standard
    case turbo
    case rocket

    var id: String { rawValue }

    var name: String {
        switch self {
        case .standard: return "Standard"
        case .turbo: return "Turbo"
        case .rocket: return "Rocket"
        }
    }

    var multiplier: Double {
        switch self {
        case .standard: return 1.5
        case .turbo: return 2.0
        case .rocket: return 3.0
        }
    }

    var formattedMultiplier: String {
        "\(String(format: "%.1f", multiplier))x"
    }

    var durationHours: Int {
        switch self {
        case .standard: return 12
        case .turbo: return 24
        case .rocket: return 48
        }
    }

    var icon: String {
        switch self {
        case .standard: return "bolt.fill"
        case .turbo: return "flame.fill"
        case .rocket: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .standard: return .blue
        case .turbo: return .orange
        case .rocket: return .purple
        }
    }

    var requiredTier: BillixSubscriptionTier? {
        switch self {
        case .standard: return .basic
        case .turbo: return .pro
        case .rocket: return .premium
        }
    }
}

// MARK: - Compact Priority Badge

struct PriorityBadge: View {
    let listing: PriorityListing

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))

            Text(listing.formattedRemainingTime)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(6)
    }
}

// MARK: - My Priority Listings View

struct MyPriorityListingsView: View {
    @StateObject private var swapService = MultiPartySwapService.shared

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if swapService.priorityListings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(swapService.priorityListings, id: \.swapId) { listing in
                            priorityListingCard(listing)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Boosts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 48))
                .foregroundColor(secondaryText)

            Text("No Active Boosts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Boost your swaps to get more visibility")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private func priorityListingCard(_ listing: PriorityListing) -> some View {
        HStack(spacing: 12) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(listing.boostMultiplier, specifier: "%.1f")x Boost")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(listing.formattedRemainingTime)
                    .font(.system(size: 12))
                    .foregroundColor(listing.isExpired ? .red : secondaryText)
            }

            Spacer()

            if listing.isActive && !listing.isExpired {
                Text("ACTIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(4)
            } else {
                Text("EXPIRED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    let mockSwap = MultiPartySwap(
        id: UUID(),
        swapType: "fractional",
        status: "recruiting",
        organizerId: UUID(),
        targetBillId: nil,
        targetAmount: 150,
        filledAmount: 50,
        minContribution: 25,
        maxParticipants: 5,
        groupId: nil,
        executionDeadline: nil,
        tierRequired: 1,
        createdAt: Date(),
        updatedAt: Date()
    )

    return PriorityListingView(swap: mockSwap) {}
        .preferredColorScheme(.dark)
}
