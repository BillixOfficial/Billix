//
//  BillSwapView.swift
//  Billix
//
//  Main Bill Swap Hub View - Complete Redesign
//  With Marketplace, Matches, Activity Feed, and Import
//

import SwiftUI

// MARK: - Bill Swap View

struct BillSwapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BillSwapViewModel()
    @State private var selectedSwap: BillSwap?
    @State private var selectedBill: SwapBill?
    @State private var selectedMatch: SwapMatch?
    @State private var showInfoSheet = false
    @State private var cardsVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BillSwapTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Trust Tier Header
                        if let tierInfo = viewModel.tierInfo {
                            TierHeaderCard(
                                tierName: tierInfo.name,
                                maxBill: tierInfo.maxBill,
                                activeSwaps: viewModel.activeSwaps.count,
                                maxSwaps: tierInfo.maxSwaps,
                                pointsBalance: viewModel.pointsBalance,
                                showInfoSheet: $showInfoSheet
                            )
                            .padding(.horizontal, BillSwapTheme.screenPadding)
                            .padding(.top, 8)
                        }

                        // Tab Selector
                        SegmentedTabSelector(selectedTab: $viewModel.selectedTab)
                            .padding(.horizontal, BillSwapTheme.screenPadding)
                            .padding(.top, 16)

                        // Content based on selected tab
                        tabContent
                            .padding(.horizontal, BillSwapTheme.screenPadding)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Bill Swap")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(BillSwapTheme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(BillSwapTheme.primaryText)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // Create new bill (opens walkthrough)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.showCreateBillSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(BillSwapTheme.accent)
                    }
                    .disabled(!viewModel.canCreateBill)
                }
            }
            .task {
                await viewModel.loadInitialData()
                withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                    cardsVisible = true
                }
            }
            .sheet(isPresented: $viewModel.showCreateBillSheet) {
                CreateBillSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showInfoSheet) {
                BillSwapInfoSheet()
            }
            .navigationDestination(item: $selectedSwap) { swap in
                SwapDetailView(swap: swap)
            }
            .overlay {
                if viewModel.isLoading && !cardsVisible {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .marketplace:
            marketplaceContent
        case .matches:
            matchesContent
        case .myBills:
            myBillsContent
        case .active:
            activeSwapsContent
        case .history:
            historyContent
        }
    }

    // MARK: - Marketplace Content (Activity Feed + Available Bills)

    @ViewBuilder
    private var marketplaceContent: some View {
        VStack(spacing: 16) {
            // Activity Feed Section
            ActivityFeedList(
                items: Array(viewModel.activityFeed.prefix(5)),
                stats: viewModel.activityStats
            )
            .staggeredAppear(index: 0, isVisible: cardsVisible)

            // Available Bills Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Bills")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BillSwapTheme.primaryText)

                    Spacer()

                    Text("\(viewModel.filteredAvailableBills.count) bills")
                        .font(.system(size: 12))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }

                if viewModel.filteredAvailableBills.isEmpty {
                    BillSwapEmptyState(
                        icon: "rectangle.stack",
                        title: "No Bills Available",
                        message: "Check back later or add your own bill!"
                    )
                } else {
                    LazyVStack(spacing: BillSwapTheme.cardSpacing) {
                        ForEach(Array(viewModel.filteredAvailableBills.enumerated()), id: \.element.id) { index, bill in
                            BillCard(
                                bill: bill,
                                showOwner: true,
                                ownerHandle: "user"
                            ) {
                                selectedBill = bill
                            }
                            .staggeredAppear(index: index + 1, isVisible: cardsVisible)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Matches Content

    @ViewBuilder
    private var matchesContent: some View {
        VStack(spacing: 16) {
            // Matching status
            if viewModel.isMatching {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(BillSwapTheme.accent)
                    Text("Finding matches...")
                        .font(.system(size: 13))
                        .foregroundColor(BillSwapTheme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(BillSwapTheme.accentLight)
                .cornerRadius(12)
            }

            if viewModel.proposedMatches.isEmpty && !viewModel.isMatching {
                VStack(spacing: 16) {
                    BillSwapEmptyState(
                        icon: "person.2.badge.gearshape",
                        title: "No Matches Yet",
                        message: "Add a bill to start finding swap partners with similar bills."
                    )

                    if !viewModel.myBills.isEmpty {
                        Button {
                            Task {
                                if let profile = viewModel.trustProfile {
                                    await viewModel.findMatchesForMyBills(profile: profile)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Find Matches")
                            }
                        }
                        .buttonStyle(BillSwapPrimaryButtonStyle())
                    }
                }
                .staggeredAppear(index: 0, isVisible: cardsVisible)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.proposedMatches.enumerated()), id: \.element.id) { index, match in
                        MatchCardView(
                            match: match,
                            onAccept: {
                                Task {
                                    do {
                                        let swap = try await viewModel.acceptMatch(match)
                                        selectedSwap = swap
                                    } catch {
                                        viewModel.error = error
                                    }
                                }
                            },
                            onDismiss: {
                                withAnimation {
                                    viewModel.proposedMatches.removeAll { $0.id == match.id }
                                }
                            }
                        )
                        .staggeredAppear(index: index, isVisible: cardsVisible)
                    }
                }
            }
        }
    }

    // MARK: - My Bills Content

    @ViewBuilder
    private var myBillsContent: some View {
        if viewModel.myBills.isEmpty {
            VStack(spacing: 24) {
                BillSwapEmptyState(
                    icon: "doc.text",
                    title: "No Bills Yet",
                    message: "Add a bill to start swapping with other users and save money together."
                )

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.showCreateBillSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Your First Bill")
                    }
                }
                .buttonStyle(BillSwapPrimaryButtonStyle())
                .frame(width: 200)
            }
            .staggeredAppear(index: 0, isVisible: cardsVisible)
        } else {
            LazyVStack(spacing: BillSwapTheme.cardSpacing) {
                ForEach(Array(viewModel.myBills.enumerated()), id: \.element.id) { index, bill in
                    BillCard(bill: bill) { action in
                        switch action {
                        case .edit:
                            // TODO: Edit bill
                            break
                        case .delete:
                            Task { try? await viewModel.deleteBill(bill) }
                        case .offer:
                            break
                        }
                    }
                    .staggeredAppear(index: index, isVisible: cardsVisible)
                }
            }
        }
    }

    // MARK: - Active Swaps Content

    @ViewBuilder
    private var activeSwapsContent: some View {
        if viewModel.activeSwaps.isEmpty {
            BillSwapEmptyState(
                icon: "arrow.triangle.2.circlepath",
                title: "No Active Swaps",
                message: "Start by browsing available bills or adding your own to find a swap partner."
            )
            .staggeredAppear(index: 0, isVisible: cardsVisible)
        } else {
            LazyVStack(spacing: BillSwapTheme.cardSpacing) {
                ForEach(Array(viewModel.activeSwaps.enumerated()), id: \.element.id) { index, swap in
                    SwapCard(
                        swap: swap,
                        currentUserId: viewModel.currentUserId ?? UUID()
                    ) {
                        selectedSwap = swap
                    }
                    .staggeredAppear(index: index, isVisible: cardsVisible)
                }
            }
        }
    }

    // MARK: - History Content

    @ViewBuilder
    private var historyContent: some View {
        if viewModel.swapHistory.isEmpty {
            BillSwapEmptyState(
                icon: "clock",
                title: "No Swap History",
                message: "Your completed and past swaps will appear here."
            )
            .staggeredAppear(index: 0, isVisible: cardsVisible)
        } else {
            LazyVStack(spacing: BillSwapTheme.cardSpacing) {
                ForEach(Array(viewModel.swapHistory.enumerated()), id: \.element.id) { index, swap in
                    SwapCard(
                        swap: swap,
                        currentUserId: viewModel.currentUserId ?? UUID()
                    ) {
                        selectedSwap = swap
                    }
                    .staggeredAppear(index: index, isVisible: cardsVisible)
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(BillSwapTheme.accent)

            Text("Loading...")
                .font(.system(size: 14))
                .foregroundColor(BillSwapTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Tier Header Card (Redesigned with Gradient)

private struct TierHeaderCard: View {
    let tierName: String
    let maxBill: String
    let activeSwaps: Int
    let maxSwaps: Int
    let pointsBalance: Int
    @Binding var showInfoSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header with tier info
            HStack(spacing: 14) {
                // Tier badge
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)

                    Image(systemName: tierIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tierIconGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(tierName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Button {
                            showInfoSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Text("Max Bill: \(maxBill)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Points badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.billixGoldenAmber)
                        Text("\(pointsBalance)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("points")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: tierGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Bottom stats bar
            HStack(spacing: 0) {
                // Active swaps stat
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: maxSwaps > 0 ? CGFloat(activeSwaps) / CGFloat(maxSwaps) : 0)
                            .stroke(BillSwapTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))

                        Text("\(activeSwaps)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(BillSwapTheme.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Active Swaps")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BillSwapTheme.secondaryText)
                        Text("\(activeSwaps) of \(maxSwaps)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BillSwapTheme.primaryText)
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 1, height: 36)

                // Quick action
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showInfoSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Level Up")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(BillSwapTheme.accent)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }

    private var tierGradientColors: [Color] {
        switch tierName.lowercased() {
        case "streamer", "provisional":
            return [Color(hex: "667eea"), Color(hex: "764ba2")]
        case "utility", "established":
            return [Color(hex: "11998e"), Color(hex: "38ef7d")]
        case "guardian", "power":
            return [Color(hex: "f093fb"), Color(hex: "f5576c")]
        case "champion", "elite":
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        default:
            return [BillSwapTheme.accent, BillSwapTheme.accent.opacity(0.7)]
        }
    }

    private var tierIconGradient: LinearGradient {
        LinearGradient(
            colors: tierGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var tierIcon: String {
        switch tierName.lowercased() {
        case "streamer", "provisional": return "play.circle.fill"
        case "utility", "established": return "bolt.fill"
        case "guardian", "power": return "shield.fill"
        case "champion", "elite": return "crown.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Scrollable Icon Tab Selector (Redesigned)

private struct SegmentedTabSelector: View {
    @Binding var selectedTab: SwapHubTab
    @Namespace private var animation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SwapHubTab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        animation: animation
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Individual Tab Button

private struct TabButton: View {
    let tab: SwapHubTab
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon in circle
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [BillSwapTheme.accent, BillSwapTheme.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                            .matchedGeometryEffect(id: "TAB_BG", in: animation)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                            .frame(width: 42, height: 42)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : BillSwapTheme.secondaryText)
                }

                // Short label
                Text(tab.shortName)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? BillSwapTheme.accent : BillSwapTheme.secondaryText)
                    .lineLimit(1)
            }
            .frame(width: 60)
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SwapHubTab Short Names Extension

extension SwapHubTab {
    var shortName: String {
        switch self {
        case .marketplace: return "Market"
        case .matches: return "Matches"
        case .myBills: return "My Bills"
        case .active: return "Active"
        case .history: return "History"
        }
    }
}

// MARK: - Info Sheet

private struct BillSwapInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Bill Swap Works")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(BillSwapTheme.primaryText)

                        Text("A safe way to help each other pay bills")
                            .font(.system(size: 15))
                            .foregroundColor(BillSwapTheme.secondaryText)
                    }

                    // Steps
                    VStack(spacing: 16) {
                        InfoStep(
                            number: 1,
                            title: "Add Your Bill",
                            description: "Upload a bill you need help paying. Include the amount, due date, and payment details."
                        )

                        InfoStep(
                            number: 2,
                            title: "Find a Match",
                            description: "Browse available bills from other users or wait for someone to offer on yours."
                        )

                        InfoStep(
                            number: 3,
                            title: "Lock & Pay",
                            description: "Once matched, both parties pay a small fee to lock the swap. Then pay each other's bills."
                        )

                        InfoStep(
                            number: 4,
                            title: "Submit Proof",
                            description: "Take a screenshot showing payment confirmation and submit it for verification."
                        )

                        InfoStep(
                            number: 5,
                            title: "Complete",
                            description: "Once both proofs are verified, the swap is complete and you both earn trust points!"
                        )
                    }

                    // Trust Tiers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trust Tiers")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(BillSwapTheme.primaryText)

                        Text("Complete swaps to level up your tier and unlock higher bill limits.")
                            .font(.system(size: 14))
                            .foregroundColor(BillSwapTheme.secondaryText)

                        VStack(spacing: 8) {
                            TierRow(name: "Streamer", limit: "$25", icon: "play.circle.fill")
                            TierRow(name: "Utility", limit: "$150", icon: "bolt.fill")
                            TierRow(name: "Guardian", limit: "$500", icon: "shield.fill")
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(BillSwapTheme.screenPadding)
            }
            .background(BillSwapTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BillSwapTheme.accent)
                }
            }
        }
    }
}

private struct InfoStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(BillSwapTheme.accentLight)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BillSwapTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BillSwapTheme.primaryText)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(BillSwapTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct TierRow: View {
    let name: String
    let limit: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(BillSwapTheme.accent)
                .frame(width: 24)

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BillSwapTheme.primaryText)

            Spacer()

            Text("Up to \(limit)")
                .font(.system(size: 13))
                .foregroundColor(BillSwapTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(BillSwapTheme.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    BillSwapView()
}
