//
//  TrustLadderHubView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Central hub for all Trust Ladder features - score, swaps, protection, credits
//

import SwiftUI

struct TrustLadderHubView: View {
    @ObservedObject private var trustService = TrustLadderService.shared
    @ObservedObject private var scoreService = BillixScoreService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var creditsService = UnlockCreditsService.shared
    @ObservedObject private var protectionService = SwapBackProtectionService.shared
    @ObservedObject private var swapService = MultiPartySwapService.shared

    @State private var showCreateSwap = false
    @State private var showPaywall = false

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
                        // Score & subscription header
                        headerSection

                        // Quick actions
                        quickActionsGrid

                        // Active swaps
                        if !swapService.activeSwaps.isEmpty {
                            activeSwapsSection
                        }

                        // Feature cards
                        featureCardsSection

                        // Live feed preview
                        CompactMarketplaceFeed(maxItems: 3)

                        // Legal disclaimer
                        DisclaimerBanner()
                    }
                    .padding()
                }
            }
            .navigationTitle("Trust Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(primaryText)
                    }
                }
            }
            .sheet(isPresented: $showCreateSwap) {
                FractionalSwapSetupView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .tierUpgrade)
            }
            .refreshable {
                await refreshAll()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Billix Score
                NavigationLink {
                    BillixScoreView()
                } label: {
                    VStack(spacing: 8) {
                        ScoreProgressRing(
                            score: scoreService.currentScore?.overallScore ?? 0,
                            badgeLevel: scoreService.currentScore?.badgeLevel ?? .newcomer,
                            size: 70
                        )

                        Text("Billix Score")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                // Subscription tier
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: subscriptionService.currentTier.icon)
                            .foregroundColor(subscriptionService.currentTier.color)
                        Text(subscriptionService.currentTier.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(primaryText)
                    }

                    if subscriptionService.currentTier == .free {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Upgrade")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(accent)
                                .cornerRadius(6)
                        }
                    }
                }
            }

            // Stats row
            HStack(spacing: 0) {
                statItem(
                    value: "\(trustService.userTrustStatus?.trustPoints ?? 0)",
                    label: "Trust Points",
                    icon: "shield.checkered"
                )

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                statItem(
                    value: "\(creditsService.balance)",
                    label: "Credits",
                    icon: "star.circle.fill"
                )

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                statItem(
                    value: "\(trustService.userTrustStatus?.totalSuccessfulSwaps ?? 0)",
                    label: "Swaps",
                    icon: "arrow.left.arrow.right"
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(accent)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryText)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickActionCard(
                title: "Create Swap",
                subtitle: "Start a new swap",
                icon: "plus.circle.fill",
                color: accent
            ) {
                showCreateSwap = true
            }

            NavigationLink {
                AvailableSwapsView()
            } label: {
                quickActionContent(
                    title: "Browse Swaps",
                    subtitle: "Find opportunities",
                    icon: "magnifyingglass.circle.fill",
                    color: .blue
                )
            }

            NavigationLink {
                BillReceiptUploadView()
            } label: {
                quickActionContent(
                    title: "Upload Receipt",
                    subtitle: "Earn credits",
                    icon: "doc.text.image",
                    color: .purple
                )
            }

            NavigationLink {
                CreditsWalletView()
            } label: {
                quickActionContent(
                    title: "Credits",
                    subtitle: "\(creditsService.balance) available",
                    icon: "star.circle.fill",
                    color: .yellow
                )
            }
        }
    }

    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionContent(title: title, subtitle: subtitle, icon: icon, color: color)
        }
    }

    private func quickActionContent(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Active Swaps Section

    private var activeSwapsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Swaps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                NavigationLink {
                    MySwapsView()
                } label: {
                    Text("See All")
                        .font(.system(size: 12))
                        .foregroundColor(accent)
                }
            }

            VStack(spacing: 10) {
                ForEach(swapService.activeSwaps.prefix(3)) { swap in
                    NavigationLink {
                        MultiPartySwapDetailView(swapId: swap.id)
                    } label: {
                        activeSwapCard(swap)
                    }
                }
            }
        }
    }

    private func activeSwapCard(_ swap: MultiPartySwap) -> some View {
        HStack(spacing: 12) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(secondaryText.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: swap.fillPercentage)
                    .stroke(swap.type?.color ?? accent, lineWidth: 4)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(swap.fillPercentage * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(primaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(swap.type?.displayName ?? "Swap")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)

                    if let status = swap.swapStatus {
                        Text(status.displayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(status.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(status.color.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text("\(swap.formattedFilledAmount) of \(swap.formattedTargetAmount)")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Feature Cards Section

    private var featureCardsSection: some View {
        VStack(spacing: 12) {
            // Protection widget
            CompactProtectionWidget()

            // Trust badge card
            NavigationLink {
                BillixScoreView()
            } label: {
                HStack(spacing: 12) {
                    TrustBadgeView(badgeLevel: scoreService.currentScore?.badgeLevel ?? .newcomer, size: .medium)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Trust Badge")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryText)

                        Text((scoreService.currentScore?.badgeLevel ?? .newcomer).displayName)
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryText)
                }
                .padding()
                .background(cardBg)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Refresh

    private func refreshAll() async {
        await scoreService.loadScore()
        await creditsService.loadCredits()
        await protectionService.loadProtectionStatus()
        await swapService.loadMySwaps()
    }
}

// MARK: - My Swaps View

struct MySwapsView: View {
    @StateObject private var swapService = MultiPartySwapService.shared

    @State private var selectedTab = 0

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Organized").tag(0)
                    Text("Participating").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedTab == 0 {
                    organizedSwapsList
                } else {
                    participatingSwapsList
                }
            }
        }
        .navigationTitle("My Swaps")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await swapService.loadMySwaps()
        }
    }

    private var organizedSwapsList: some View {
        Group {
            if swapService.myOrganizedSwaps.isEmpty {
                emptyState(message: "You haven't organized any swaps yet")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(swapService.myOrganizedSwaps) { swap in
                            NavigationLink {
                                MultiPartySwapDetailView(swapId: swap.id)
                            } label: {
                                swapCard(swap, isOrganizer: true)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var participatingSwapsList: some View {
        Group {
            if swapService.myParticipations.isEmpty {
                emptyState(message: "You haven't joined any swaps yet")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(swapService.myParticipations) { participation in
                            participationCard(participation)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(secondaryText)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func swapCard(_ swap: MultiPartySwap, isOrganizer: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: swap.type?.icon ?? "arrow.left.arrow.right")
                    .font(.system(size: 18))
                    .foregroundColor(swap.type?.color ?? accent)

                Text(swap.type?.displayName ?? "Swap")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                if let status = swap.swapStatus {
                    Text(status.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: swap.fillPercentage)
                    .tint(swap.type?.color ?? accent)

                HStack {
                    Text(swap.formattedFilledAmount)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryText)

                    Spacer()

                    Text("of \(swap.formattedTargetAmount)")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }
            }

            // Footer
            HStack {
                Text(swap.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    private func participationCard(_ participation: SwapParticipant) -> some View {
        HStack(spacing: 12) {
            Image(systemName: participation.participantStatus?.color == .green ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(participation.participantStatus?.color ?? secondaryText)

            VStack(alignment: .leading, spacing: 4) {
                Text(participation.formattedContribution)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(participation.participantStatus?.displayName ?? "Pending")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Text(participation.createdAt, style: .relative)
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }
}

// MARK: - Settings View Placeholder

struct SettingsView: View {
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            Text("Settings")
                .foregroundColor(.white)
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Preview
// Note: CompactMarketplaceFeed is defined in MarketplaceFeedView.swift
// Note: DisclaimerBanner is defined in LegalDisclaimerComponents.swift

#Preview {
    TrustLadderHubView()
        .preferredColorScheme(.dark)
}
