//
//  SwapHubView.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Main hub for the Trust Ladder swap system
//

import SwiftUI

// MARK: - Theme

private enum Theme {
    static let background = Color(hex: "#FAFBFA")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#1A2B23")
    static let secondaryText = Color(hex: "#6B7C74")
    static let tertiaryText = Color(hex: "#9AA89F")
    static let accent = Color(hex: "#3D7A5A")
    static let accentLight = Color(hex: "#E8F2EC")
    static let accentMedium = Color(hex: "#D1E6DA")
    static let border = Color(hex: "#E5EAE7")
    static let divider = Color(hex: "#F0F3F1")
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20
}

// MARK: - Swap Hub View

struct SwapHubView: View {
    @StateObject private var viewModel = SwapHubViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showFindMatch = false
    @State private var selectedSwapForExecution: Swap?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.trustStatus == nil {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Swap Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPortfolioSetup) {
                PortfolioSetupView(onComplete: viewModel.onPortfolioSetupComplete)
            }
            .sheet(isPresented: $showFindMatch) {
                FindMatchView()
            }
            .fullScreenCover(item: $selectedSwapForExecution) { swap in
                SwapExecutionView(swap: swap)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadSwapHub()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your swap hub...")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryText)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Tier Progress Card
                tierProgressCard

                // Tab selector
                tabSelector

                // Tab content
                tabContent

                Spacer().frame(height: 100)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Tier Progress Card

    private var tierProgressCard: some View {
        VStack(spacing: 0) {
            // Top section - Tier info
            HStack(spacing: 14) {
                // Tier badge - clean flat design
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.tier.color.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: viewModel.tier.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(viewModel.tier.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.tier.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.primaryText)

                    Text("Up to \(String(format: "$%.0f", viewModel.tier.maxAmount)) per swap")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                if let swapsNeeded = viewModel.swapsToNextTier {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(swapsNeeded)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accent)
                        Text("to level up")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.tertiaryText)
                    }
                }
            }
            .padding(Theme.padding)

            // Progress bar section
            if viewModel.tier.nextTier != nil {
                VStack(spacing: 8) {
                    // Progress bar - clean minimal style
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.divider)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.accent)
                                .frame(width: max(geo.size.width * viewModel.tierProgress, 6), height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text(viewModel.tier.shortName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.secondaryText)

                        Spacer()

                        if let next = viewModel.tier.nextTier {
                            Text(next.shortName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 16)
            }

            // Divider
            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)

            // Stats section - horizontal layout
            HStack(spacing: 0) {
                StatPill(
                    icon: "star.fill",
                    value: viewModel.trustStatus?.formattedRating ?? "5.0",
                    label: "Rating",
                    iconColor: Color(hex: "#F5A623")
                )

                // Vertical divider
                Rectangle()
                    .fill(Theme.divider)
                    .frame(width: 1, height: 36)

                StatPill(
                    icon: "arrow.left.arrow.right",
                    value: "\(viewModel.trustStatus?.totalSuccessfulSwaps ?? 0)",
                    label: "Swaps",
                    iconColor: Theme.accent
                )

                // Vertical divider
                Rectangle()
                    .fill(Theme.divider)
                    .frame(width: 1, height: 36)

                StatPill(
                    icon: "diamond.fill",
                    value: "\(viewModel.trustStatus?.trustPoints ?? 0)",
                    label: "Points",
                    iconColor: Color(hex: "#5B9BD5")
                )
            }
            .padding(.vertical, 14)
        }
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, Theme.padding)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(SwapHubViewModel.SwapHubTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTab = tab
                    }
                    haptic()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(viewModel.selectedTab == tab ? Theme.accent : Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.selectedTab == tab ? Theme.accentLight : Color.clear
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.selectedTab == tab ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(6)
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, Theme.padding)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .mySwaps:
            mySwapsContent
        case .findMatch:
            findMatchContent
        case .history:
            historyContent
        }
    }

    // MARK: - My Swaps Tab

    private var mySwapsContent: some View {
        VStack(spacing: 16) {
            if viewModel.activeSwaps.isEmpty {
                emptySwapsCard
            } else {
                ForEach(viewModel.activeSwaps) { swap in
                    ActiveSwapCard(swap: swap) {
                        selectedSwapForExecution = swap
                    }
                }
            }
        }
        .padding(.horizontal, Theme.padding)
    }

    private var emptySwapsCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentLight)
                    .frame(width: 72, height: 72)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Theme.accent)
            }

            VStack(spacing: 6) {
                Text("No active swaps")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                Text("Start your first swap by finding a match partner")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button {
                showFindMatch = true
                haptic()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                    Text("Find a Match")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.accent)
                .cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Find Match Tab

    private var findMatchContent: some View {
        VStack(spacing: 16) {
            // Available bills to swap
            if !viewModel.availableBillsForSwap.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your bills available for swapping")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                        .padding(.horizontal, Theme.padding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.availableBillsForSwap) { bill in
                                BillSwapChip(bill: bill) {
                                    showFindMatch = true
                                }
                            }
                        }
                        .padding(.horizontal, Theme.padding)
                    }
                }

                // Find match button
                Button {
                    showFindMatch = true
                    haptic()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                        Text("Search for Mirror Partners")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal, Theme.padding)
                .padding(.top, 4)

                // Pending matches
                if !viewModel.pendingMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available matches")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.primaryText)

                        ForEach(viewModel.pendingMatches) { match in
                            SwapPartnerMatchCard(match: match) {
                                // Would open match detail
                            }
                        }
                    }
                    .padding(.horizontal, Theme.padding)
                }
            } else {
                // No bills available
                noBillsCard
                    .padding(.horizontal, Theme.padding)
            }
        }
    }

    private var noMatchesCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.divider)
                    .frame(width: 56, height: 56)

                Image(systemName: "person.2")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Theme.tertiaryText)
            }

            VStack(spacing: 4) {
                Text("No matches found yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                Text("We're searching for partners with matching schedules. Check back soon!")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private var noBillsCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.accentLight)
                    .frame(width: 56, height: 56)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Theme.accent)
            }

            VStack(spacing: 4) {
                Text("Add bills to start swapping")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                Text("Once you add your bills, you can find swap partners")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.openPortfolioSetup()
            } label: {
                Text("Add Bills")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(10)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - History Tab

    private var historyContent: some View {
        VStack(spacing: 16) {
            if viewModel.completedSwaps.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.divider)
                            .frame(width: 64, height: 64)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(Theme.tertiaryText)
                    }

                    VStack(spacing: 4) {
                        Text("No swap history yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.primaryText)

                        Text("Completed swaps will appear here")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.border, lineWidth: 1)
                )
            } else {
                ForEach(viewModel.completedSwaps) { swap in
                    CompletedSwapCard(swap: swap)
                }
            }
        }
        .padding(.horizontal, Theme.padding)
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Supporting Views

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BillSwapChip: View {
    let bill: UserBill
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill((bill.category?.color ?? Theme.accent).opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: bill.category?.icon ?? "doc")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(bill.category?.color ?? Theme.accent)
                }

                Text(bill.providerName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(1)

                Text(bill.formattedAmount)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 100)
            .padding(.vertical, 14)
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
}

private struct ActiveSwapCard: View {
    let swap: Swap
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Status indicator with background
                ZStack {
                    Circle()
                        .fill(swap.swapStatus.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Circle()
                        .fill(swap.swapStatus.color)
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(swap.swapStatus.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText)

                    if let timeRemaining = swap.formattedTimeRemaining {
                        Text("\(timeRemaining) remaining")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.secondaryText)
                    }
                }

                Spacer()

                Text(swap.formattedTotalValue)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.tertiaryText)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
}

private struct SwapPartnerMatchCard: View {
    let match: MatchedPartner
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.accentLight)
                        .frame(width: 44, height: 44)

                    Text(match.partnerInitials)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("@\(match.partnerHandle)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.primaryText)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#F5A623"))
                            Text(match.formattedRating)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.secondaryText)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#F5A623").opacity(0.1))
                        .cornerRadius(4)
                    }

                    Text("\(match.partnerSuccessfulSwaps) successful swaps")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(match.formattedAmount)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text("\(match.formattedMatchScore) match")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accentLight)
                        .cornerRadius(4)
                }
            }
            .padding(14)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
}

private struct CompletedSwapCard: View {
    let swap: Swap

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5E9"))
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#4CAF50"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Completed")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                if let date = swap.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(swap.formattedTotalValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText)

                if let points = swap.trustPointsAwarded {
                    Text("+\(points) pts")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accentLight)
                        .cornerRadius(4)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    SwapHubView()
}
