//
//  BillSwapView.swift
//  Billix
//
//  Bill Swap feature matching homepage design system
//

import SwiftUI

// MARK: - Theme (matching HomeView)

private enum SwapThemeColors {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let danger = Color(hex: "#E07A6B")
    static let info = Color(hex: "#5BA4D4")
    static let purple = Color(hex: "#9B7EB8")

    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8
}

// MARK: - Main View

struct BillSwapView: View {
    @StateObject private var viewModel = SwapHomeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SwapTab = .home
    @State private var showUploadSheet = false
    @State private var showInfoSheet = false
    @State private var selectedSwap: BillSwapTransaction?
    @State private var selectedBillForDetail: SwapBillWithUser?

    enum SwapTab: String, CaseIterable {
        case home = "Home"
        case matches = "Matches"
        case active = "Active"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .matches: return "person.2.fill"
            case .active: return "arrow.triangle.2.circlepath"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SwapThemeColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    swapHeader

                    // Tab selector
                    swapTabBar
                        .padding(.top, 12)

                    // Content
                    TabView(selection: $selectedTab) {
                        SwapHomeContent(viewModel: viewModel, showUploadSheet: $showUploadSheet, selectedBillForDetail: $selectedBillForDetail)
                            .tag(SwapTab.home)

                        SwapMatchesContent(viewModel: viewModel, selectedBillForDetail: $selectedBillForDetail)
                            .tag(SwapTab.matches)

                        SwapActiveContent(viewModel: viewModel, selectedSwap: $selectedSwap)
                            .tag(SwapTab.active)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showUploadSheet) {
                UploadBillView {
                    showUploadSheet = false
                    Task { await viewModel.loadData() }
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                SwapInfoSheet()
            }
            .sheet(item: $selectedBillForDetail) { billWithUser in
                BillDetailSheet(billWithUser: billWithUser)
            }
            .navigationDestination(item: $selectedSwap) { swap in
                MatchDetailView(swapId: swap.id)
            }
            .task { await viewModel.loadData() }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Header

    private var swapHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Home")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(SwapThemeColors.accent)
            }

            Spacer()

            Text("Bill Swap")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(SwapThemeColors.primaryText)

            Spacer()

            HStack(spacing: 12) {
                Button { showInfoSheet = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(SwapThemeColors.accent)
                }

                Button { showUploadSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SwapThemeColors.accent)
                }
            }
        }
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Tab Bar

    private var swapTabBar: some View {
        HStack(spacing: 0) {
            ForEach(SwapTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? SwapThemeColors.accent : SwapThemeColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab ? SwapThemeColors.accentLight : Color.clear
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }
}

// MARK: - Home Content

private struct SwapHomeContent: View {
    @ObservedObject var viewModel: SwapHomeViewModel
    @Binding var showUploadSheet: Bool
    @Binding var selectedBillForDetail: SwapBillWithUser?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // My Bills Section
                myBillsSection

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }

    private var myBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundColor(SwapThemeColors.accent)
                    Text("MY BILLS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SwapThemeColors.secondaryText)
                        .tracking(0.5)
                }

                Spacer()

                if !viewModel.myBillsWithUsers.isEmpty {
                    Text("\(viewModel.myBillsWithUsers.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SwapThemeColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SwapThemeColors.accentLight)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, SwapThemeColors.horizontalPadding)

            if viewModel.myBillsWithUsers.isEmpty && viewModel.myBills.isEmpty {
                // Empty state
                emptyBillsCard
            } else {
                // Bills list
                VStack(spacing: 12) {
                    ForEach(viewModel.myBillsWithUsers) { billWithUser in
                        Button {
                            selectedBillForDetail = billWithUser
                        } label: {
                            EnhancedBillCard(billWithUser: billWithUser)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, SwapThemeColors.horizontalPadding)
            }
        }
    }

    private var emptyBillsCard: some View {
        Button { showUploadSheet = true } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SwapThemeColors.accentLight)
                        .frame(width: 64, height: 64)

                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(SwapThemeColors.accent)
                }

                VStack(spacing: 6) {
                    Text("Upload your first bill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(SwapThemeColors.primaryText)

                    Text("Add a bill to start finding\nswap partners")
                        .font(.system(size: 13))
                        .foregroundColor(SwapThemeColors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Text("Upload Bill")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(SwapThemeColors.accent)
                .cornerRadius(12)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(SwapThemeColors.cardBackground)
            .cornerRadius(SwapThemeColors.cornerRadius)
            .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }
}

// MARK: - Enhanced Bill Card

private struct EnhancedBillCard: View {
    let billWithUser: SwapBillWithUser

    private var bill: SwapBill { billWithUser.bill }

    private var iconName: String {
        bill.category?.icon ?? "doc.text.fill"
    }

    private var iconColor: Color {
        switch bill.category {
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phonePlan: return .green
        default: return SwapThemeColors.accent
        }
    }

    private var dueInfo: (text: String, color: Color) {
        guard let dueDate = bill.dueDate else {
            return ("No due date", SwapThemeColors.secondaryText)
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        if days < 0 {
            return ("Overdue", SwapThemeColors.danger)
        } else if days == 0 {
            return ("Due today", SwapThemeColors.warning)
        } else if days <= 3 {
            return ("Due in \(days)d", SwapThemeColors.warning)
        } else {
            return ("Due in \(days)d", SwapThemeColors.secondaryText)
        }
    }

    private var statusColor: Color {
        switch bill.status {
        case .unmatched: return SwapThemeColors.warning
        case .matched: return SwapThemeColors.info
        case .paid: return SwapThemeColors.success
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: User info
            HStack(spacing: 8) {
                // Avatar
                userAvatar

                // Handle
                Text("@\(billWithUser.userHandle)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SwapThemeColors.secondaryText)

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(bill.status.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 14)

            // Main content row
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }

                // Bill info
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.category?.displayName ?? "Bill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SwapThemeColors.primaryText)

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.system(size: 13))
                            .foregroundColor(SwapThemeColors.secondaryText)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(dueInfo.text)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(dueInfo.color)
                }

                Spacer()

                // Amount and chevron
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.formattedAmount)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(SwapThemeColors.primaryText)

                    if let zipCode = bill.zipCode {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9))
                            Text(zipCode)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(SwapThemeColors.secondaryText)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SwapThemeColors.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(SwapThemeColors.accent.opacity(0.15))
                .frame(width: 28, height: 28)

            if let avatarUrl = billWithUser.userAvatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(billWithUser.userInitials)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SwapThemeColors.accent)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            } else {
                Text(billWithUser.userInitials)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SwapThemeColors.accent)
            }
        }
    }
}

// MARK: - Matches Content

private struct SwapMatchesContent: View {
    @ObservedObject var viewModel: SwapHomeViewModel
    @Binding var selectedBillForDetail: SwapBillWithUser?
    @State private var selectedMatch: SwapBillWithUser?
    @State private var showConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if viewModel.matchesWithUsers.isEmpty && viewModel.potentialMatches.isEmpty {
                    emptyMatchesView
                } else {
                    // Header
                    HStack {
                        Text("\(viewModel.matchesWithUsers.count) potential match\(viewModel.matchesWithUsers.count == 1 ? "" : "es")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SwapThemeColors.secondaryText)
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.horizontal, SwapThemeColors.horizontalPadding)

                    // Matches list using enhanced cards
                    VStack(spacing: 12) {
                        ForEach(viewModel.matchesWithUsers) { matchWithUser in
                            MatchCardWithActions(
                                billWithUser: matchWithUser,
                                onTap: {
                                    selectedBillForDetail = matchWithUser
                                },
                                onStartSwap: {
                                    selectedMatch = matchWithUser
                                    showConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, SwapThemeColors.horizontalPadding)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .alert("Start Swap?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start Swap") {
                if let match = selectedMatch,
                   let myBill = viewModel.unmatchedBills.first {
                    Task {
                        await viewModel.createSwap(myBill: myBill, partnerBill: match.bill)
                    }
                }
            }
        } message: {
            if let match = selectedMatch {
                Text("Start a swap with @\(match.userHandle)'s \(match.bill.formattedAmount) bill?")
            }
        }
    }

    private var emptyMatchesView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SwapThemeColors.purple.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "person.2.slash")
                    .font(.system(size: 28))
                    .foregroundColor(SwapThemeColors.purple)
            }

            VStack(spacing: 6) {
                Text("No matches yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(SwapThemeColors.primaryText)

                Text("Upload bills or wait for\nother users to add similar bills")
                    .font(.system(size: 13))
                    .foregroundColor(SwapThemeColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(SwapThemeColors.accent)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }
}

// MARK: - Match Card With Actions

private struct MatchCardWithActions: View {
    let billWithUser: SwapBillWithUser
    let onTap: () -> Void
    let onStartSwap: () -> Void

    private var bill: SwapBill { billWithUser.bill }

    private var iconName: String {
        bill.category?.icon ?? "doc.text.fill"
    }

    private var iconColor: Color {
        switch bill.category {
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phonePlan: return .green
        default: return SwapThemeColors.accent
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: User info with match indicator
            HStack(spacing: 8) {
                // Avatar
                userAvatar

                // Handle
                Text("@\(billWithUser.userHandle)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SwapThemeColors.secondaryText)

                Spacer()

                // Match badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                    Text("Match")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(SwapThemeColors.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SwapThemeColors.success.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 14)

            // Main content (tappable)
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor)
                    }

                    // Bill info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bill.category?.displayName ?? "Bill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(SwapThemeColors.primaryText)

                        if let provider = bill.providerName {
                            Text(provider)
                                .font(.system(size: 13))
                                .foregroundColor(SwapThemeColors.secondaryText)
                        }

                        if let zipCode = bill.zipCode {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 9))
                                Text(zipCode)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(SwapThemeColors.secondaryText)
                        }
                    }

                    Spacer()

                    // Amount
                    Text(bill.formattedAmount)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(SwapThemeColors.primaryText)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SwapThemeColors.secondaryText.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.horizontal, 14)

            // Action button
            Button(action: onStartSwap) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Start Swap")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(SwapThemeColors.accent)
                .cornerRadius(10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(SwapThemeColors.accent.opacity(0.15))
                .frame(width: 28, height: 28)

            if let avatarUrl = billWithUser.userAvatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(billWithUser.userInitials)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SwapThemeColors.accent)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            } else {
                Text(billWithUser.userInitials)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SwapThemeColors.accent)
            }
        }
    }
}

// MARK: - Active Swaps Content

private struct SwapActiveContent: View {
    @ObservedObject var viewModel: SwapHomeViewModel
    @Binding var selectedSwap: BillSwapTransaction?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if viewModel.activeSwaps.isEmpty {
                    emptyActiveView
                } else {
                    // Header
                    HStack {
                        Text("\(viewModel.activeSwaps.count) active swap\(viewModel.activeSwaps.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SwapThemeColors.secondaryText)
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.horizontal, SwapThemeColors.horizontalPadding)

                    // Swaps list
                    VStack(spacing: 12) {
                        ForEach(viewModel.activeSwaps) { swap in
                            ActiveSwapCard(swap: swap) {
                                selectedSwap = swap
                            }
                        }
                    }
                    .padding(.horizontal, SwapThemeColors.horizontalPadding)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }

    private var emptyActiveView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SwapThemeColors.info.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "arrow.left.arrow.right.circle")
                    .font(.system(size: 28))
                    .foregroundColor(SwapThemeColors.info)
            }

            VStack(spacing: 6) {
                Text("No active swaps")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(SwapThemeColors.primaryText)

                Text("Start a swap from the\nMatches tab")
                    .font(.system(size: 13))
                    .foregroundColor(SwapThemeColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }
}

private struct ActiveSwapCard: View {
    let swap: BillSwapTransaction
    let onTap: () -> Void

    private var statusConfig: (color: Color, icon: String) {
        switch swap.status {
        case .pending: return (SwapThemeColors.warning, "clock.fill")
        case .active: return (SwapThemeColors.info, "arrow.triangle.2.circlepath")
        case .expired: return (SwapThemeColors.danger, "clock.badge.xmark.fill")
        case .completed: return (SwapThemeColors.success, "checkmark.circle.fill")
        case .dispute: return (SwapThemeColors.danger, "exclamationmark.triangle.fill")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    // Swap icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(statusConfig.color.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: statusConfig.icon)
                            .font(.system(size: 14))
                            .foregroundColor(statusConfig.color)
                    }

                    Text("Swap #\(swap.id.uuidString.prefix(8))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SwapThemeColors.primaryText)

                    Spacer()

                    // Status badge
                    Text(swap.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(statusConfig.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusConfig.color.opacity(0.12))
                        .cornerRadius(6)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SwapThemeColors.accent.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(SwapThemeColors.accent)
                            .frame(width: geo.size.width * swap.progressPercentage, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(Int(swap.progressPercentage * 100))% complete")
                        .font(.system(size: 12))
                        .foregroundColor(SwapThemeColors.secondaryText)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(SwapThemeColors.accent)
                }
            }
            .padding(14)
            .background(SwapThemeColors.cardBackground)
            .cornerRadius(SwapThemeColors.cornerRadius)
            .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Bill Detail Sheet

private struct BillDetailSheet: View {
    let billWithUser: SwapBillWithUser
    @Environment(\.dismiss) private var dismiss

    private var bill: SwapBill { billWithUser.bill }

    private var iconName: String {
        bill.category?.icon ?? "doc.text.fill"
    }

    private var iconColor: Color {
        switch bill.category {
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phonePlan: return .green
        default: return SwapThemeColors.accent
        }
    }

    private var statusColor: Color {
        switch bill.status {
        case .unmatched: return SwapThemeColors.warning
        case .matched: return SwapThemeColors.info
        case .paid: return SwapThemeColors.success
        }
    }

    private var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: bill.createdAt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with category icon
                    headerSection

                    // User info card
                    userInfoCard

                    // Bill details card
                    billDetailsCard

                    // Additional info card
                    additionalInfoCard

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(SwapThemeColors.background)
            .navigationTitle("Bill Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(SwapThemeColors.accent)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
            }

            // Category name
            Text(bill.category?.displayName ?? "Bill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(SwapThemeColors.primaryText)

            // Amount
            Text(bill.formattedAmount)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(SwapThemeColors.accent)

            // Status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(bill.status.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPLOADED BY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(SwapThemeColors.secondaryText)
                .tracking(0.5)

            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(SwapThemeColors.accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if let avatarUrl = billWithUser.userAvatarUrl, !avatarUrl.isEmpty {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(billWithUser.userInitials)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SwapThemeColors.accent)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        Text(billWithUser.userInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SwapThemeColors.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let displayName = billWithUser.userDisplayName {
                        Text(displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SwapThemeColors.primaryText)
                    }
                    Text("@\(billWithUser.userHandle)")
                        .font(.system(size: 14))
                        .foregroundColor(SwapThemeColors.secondaryText)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }

    private var billDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BILL DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(SwapThemeColors.secondaryText)
                .tracking(0.5)

            VStack(spacing: 0) {
                // Provider
                if let provider = bill.providerName {
                    detailRow(label: "Provider", value: provider, icon: "building.2.fill")
                    Divider().padding(.leading, 44)
                }

                // Category
                detailRow(label: "Category", value: bill.category?.displayName ?? "Unknown", icon: iconName)
                Divider().padding(.leading, 44)

                // Due Date
                if let dueDate = bill.formattedDueDate {
                    detailRow(label: "Due Date", value: dueDate, icon: "calendar")
                    Divider().padding(.leading, 44)
                }

                // Location
                if let zipCode = bill.zipCode {
                    detailRow(label: "Location", value: zipCode, icon: "location.fill")
                }
            }
        }
        .padding(16)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }

    private var additionalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADDITIONAL INFO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(SwapThemeColors.secondaryText)
                .tracking(0.5)

            VStack(spacing: 0) {
                // Upload Date
                detailRow(label: "Uploaded", value: formattedCreatedDate, icon: "clock.fill")

                // Days until due
                if let days = bill.daysUntilDue {
                    Divider().padding(.leading, 44)
                    if days < 0 {
                        detailRow(label: "Status", value: "Overdue by \(abs(days)) day\(abs(days) == 1 ? "" : "s")", icon: "exclamationmark.triangle.fill", valueColor: SwapThemeColors.danger)
                    } else if days == 0 {
                        detailRow(label: "Status", value: "Due today", icon: "exclamationmark.triangle.fill", valueColor: SwapThemeColors.warning)
                    } else {
                        detailRow(label: "Status", value: "Due in \(days) day\(days == 1 ? "" : "s")", icon: "clock.badge.checkmark.fill", valueColor: SwapThemeColors.success)
                    }
                }
            }
        }
        .padding(16)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(SwapThemeColors.cornerRadius)
        .shadow(color: SwapThemeColors.shadowColor, radius: SwapThemeColors.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, SwapThemeColors.horizontalPadding)
    }

    private func detailRow(label: String, value: String, icon: String, valueColor: Color = SwapThemeColors.primaryText) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SwapThemeColors.secondaryText)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(SwapThemeColors.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Info Sheet

private struct SwapInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SwapThemeColors.accent.opacity(0.12))
                                .frame(width: 72, height: 72)

                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(SwapThemeColors.accent)
                        }

                        Text("How Bill Swap Works")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(SwapThemeColors.primaryText)

                        Text("Exchange bills with other users")
                            .font(.system(size: 14))
                            .foregroundColor(SwapThemeColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Steps
                    VStack(spacing: 12) {
                        InfoStep(number: 1, title: "Upload Your Bill", description: "Take a photo or upload your bill")
                        InfoStep(number: 2, title: "Find a Match", description: "We match bills within 10% of your amount")
                        InfoStep(number: 3, title: "Confirm & Swap", description: "Both parties agree and pay each other's bills")
                        InfoStep(number: 4, title: "Verify", description: "Upload proof and complete the swap")
                    }
                    .padding(.horizontal, SwapThemeColors.horizontalPadding)

                    Spacer(minLength: 40)
                }
            }
            .background(SwapThemeColors.background)
            .navigationTitle("About Bill Swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(SwapThemeColors.accent)
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
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(SwapThemeColors.accent)
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SwapThemeColors.primaryText)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(SwapThemeColors.secondaryText)
            }

            Spacer()
        }
        .padding(14)
        .background(SwapThemeColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: SwapThemeColors.shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews

#Preview("Bill Swap View") {
    BillSwapView()
}

#Preview("Info Sheet") {
    SwapInfoSheet()
}
