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
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.1)
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
        VStack(spacing: 16) {
            // Tier badge and name
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: viewModel.tier.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: viewModel.tier.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.tier.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.primaryText)

                    Text("Max swap: \(String(format: "$%.0f", viewModel.tier.maxAmount))")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                if let swapsNeeded = viewModel.swapsToNextTier {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(swapsNeeded)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Text("swaps to next tier")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }

            // Progress bar
            if viewModel.tier.nextTier != nil {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: viewModel.tier.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * viewModel.tierProgress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(viewModel.tier.shortName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(viewModel.tier.color)

                        Spacer()

                        if let next = viewModel.tier.nextTier {
                            Text(next.shortName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(next.color)
                        }
                    }
                }
            }

            // Trust stats
            HStack(spacing: 20) {
                StatPill(
                    icon: "star.fill",
                    value: viewModel.trustStatus?.formattedRating ?? "5.0",
                    label: "Rating",
                    color: .yellow
                )

                StatPill(
                    icon: "checkmark.seal.fill",
                    value: "\(viewModel.trustStatus?.totalSuccessfulSwaps ?? 0)",
                    label: "Swaps",
                    color: Theme.accent
                )

                StatPill(
                    icon: "shield.fill",
                    value: "\(viewModel.trustStatus?.trustPoints ?? 0)",
                    label: "Points",
                    color: .blue
                )
            }
        }
        .padding(Theme.padding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal, Theme.padding)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SwapHubViewModel.SwapHubTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                    haptic()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(viewModel.selectedTab == tab ? Theme.accent : Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.selectedTab == tab ? Theme.accentLight : Color.clear
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4)
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
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 48))
                .foregroundColor(Theme.secondaryText.opacity(0.5))

            Text("No active swaps")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.primaryText)

            Text("Start your first swap by finding a match partner")
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showFindMatch = true
                haptic()
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("Find a Match")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .cornerRadius(10)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.03), radius: 4)
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
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search for Mirror Partners")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal, Theme.padding)

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
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.secondaryText.opacity(0.5))

            Text("No matches found yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.primaryText)

            Text("We're searching for partners with matching schedules. Check back soon!")
                .font(.system(size: 13))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }

    private var noBillsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Theme.secondaryText.opacity(0.5))

            Text("Add bills to start swapping")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.primaryText)

            Button {
                viewModel.openPortfolioSetup()
            } label: {
                Text("Add Bills")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - History Tab

    private var historyContent: some View {
        VStack(spacing: 16) {
            if viewModel.completedSwaps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.secondaryText.opacity(0.5))

                    Text("No swap history yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.primaryText)

                    Text("Completed swaps will appear here")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
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
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.primaryText)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.secondaryText)
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
                Image(systemName: bill.category?.icon ?? "doc")
                    .font(.system(size: 24))
                    .foregroundColor(bill.category?.color ?? Theme.accent)

                Text(bill.providerName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(1)

                Text(bill.formattedAmount)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
    }
}

private struct ActiveSwapCard: View {
    let swap: Swap
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(swap.swapStatus.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
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
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.accent)

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.secondaryText)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: .black.opacity(0.03), radius: 4)
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
                        .frame(width: 48, height: 48)

                    Text(match.partnerInitials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("@\(match.partnerHandle)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.primaryText)

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(match.formattedRating)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }

                    Text("\(match.partnerSuccessfulSwaps) successful swaps")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.formattedAmount)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.primaryText)

                    Text("\(match.formattedMatchScore) match")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: .black.opacity(0.03), radius: 4)
        }
    }
}

private struct CompletedSwapCard: View {
    let swap: Swap

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
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

            VStack(alignment: .trailing, spacing: 4) {
                Text(swap.formattedTotalValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.primaryText)

                if let points = swap.trustPointsAwarded {
                    Text("+\(points) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: .black.opacity(0.03), radius: 4)
    }
}

// MARK: - Preview

#Preview {
    SwapHubView()
}
