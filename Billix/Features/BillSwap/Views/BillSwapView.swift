//
//  BillSwapView.swift
//  Billix
//
//  Main Bill Swap Hub View - Redesigned to match Home page styling
//

import SwiftUI

struct BillSwapView: View {
    @StateObject private var viewModel = BillSwapViewModel()
    @State private var selectedSwap: BillSwap?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Info banner
                    BillSwapInfoBanner()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Trust tier header
                    if let tierInfo = viewModel.tierInfo {
                        TierHeaderView(
                            tierName: tierInfo.name,
                            maxBill: tierInfo.maxBill,
                            activeSwaps: viewModel.activeSwaps.count,
                            maxSwaps: tierInfo.maxSwaps,
                            pointsBalance: viewModel.pointsBalance
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }

                    // Tab selector
                    SwapTabSelector(selectedTab: $viewModel.selectedTab)
                        .padding(.top, 16)

                    // Content based on selected tab
                    Group {
                        switch viewModel.selectedTab {
                        case .available:
                            AvailableBillsTab(
                                bills: viewModel.filteredAvailableBills,
                                onSelect: { _ in }
                            )
                        case .myBills:
                            MyBillsTab(
                                bills: viewModel.myBills,
                                onCreateBill: { viewModel.showCreateBillSheet = true },
                                onDeleteBill: { bill in
                                    Task { try? await viewModel.deleteBill(bill) }
                                }
                            )
                        case .active:
                            ActiveSwapsTab(
                                swaps: viewModel.activeSwaps,
                                onSelect: { swap in selectedSwap = swap }
                            )
                        case .history:
                            SwapHistoryTab(
                                swaps: viewModel.swapHistory,
                                onSelect: { swap in selectedSwap = swap }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .padding(.bottom, 20)
            }
            .background(Color(hex: "F7F9F8"))
            .navigationTitle("Bill Swap")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCreateBillSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.billixMoneyGreen)
                    }
                    .disabled(!viewModel.canCreateBill)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadInitialData()
            }
            .sheet(isPresented: $viewModel.showCreateBillSheet) {
                CreateBillSheet(viewModel: viewModel)
            }
            .navigationDestination(item: $selectedSwap) { swap in
                SwapDetailView(swap: swap)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

// MARK: - Tier Header (Redesigned)

struct TierHeaderView: View {
    let tierName: String
    let maxBill: String
    let activeSwaps: Int
    let maxSwaps: Int
    let pointsBalance: Int

    var body: some View {
        HStack {
            // Tier info
            VStack(alignment: .leading, spacing: 4) {
                Text(tierName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2D3B35"))

                Text("Up to \(maxBill) per bill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "666666"))
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(Color.billixGoldenAmber)
                    Text("\(pointsBalance) pts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2D3B35"))
                }

                Text("\(activeSwaps)/\(maxSwaps) active")
                    .font(.caption)
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Tab Selector (Redesigned)

struct SwapTabSelector: View {
    @Binding var selectedTab: SwapHubTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SwapHubTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? Color(hex: "2D3B35") : Color(hex: "666666"))

                        // Underline indicator
                        Rectangle()
                            .fill(selectedTab == tab ? Color.billixMoneyGreen : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
    }
}

// MARK: - Available Bills Tab

struct AvailableBillsTab: View {
    let bills: [SwapBill]
    let onSelect: (SwapBill) -> Void

    var body: some View {
        if bills.isEmpty {
            EmptyStateView(
                icon: "arrow.left.arrow.right",
                title: "No Bills Available",
                message: "There are no bills available for swap right now. Check back later!"
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(bills) { bill in
                    BillCard(bill: bill)
                        .onTapGesture { onSelect(bill) }
                }
            }
        }
    }
}

// MARK: - My Bills Tab

struct MyBillsTab: View {
    let bills: [SwapBill]
    let onCreateBill: () -> Void
    let onDeleteBill: (SwapBill) -> Void

    var body: some View {
        if bills.isEmpty {
            VStack(spacing: 20) {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Bills Yet",
                    message: "Add a bill to start swapping with others."
                )

                Button {
                    onCreateBill()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Your First Bill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(12)
                }
            }
        } else {
            LazyVStack(spacing: 12) {
                ForEach(bills) { bill in
                    BillCard(bill: bill, showStatus: true)
                        .contextMenu {
                            if bill.status == .draft {
                                Button(role: .destructive) {
                                    onDeleteBill(bill)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Active Swaps Tab

struct ActiveSwapsTab: View {
    let swaps: [BillSwap]
    let onSelect: (BillSwap) -> Void

    var body: some View {
        if swaps.isEmpty {
            EmptyStateView(
                icon: "clock",
                title: "No Active Swaps",
                message: "Your active swaps will appear here."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(swaps) { swap in
                    SwapCard(swap: swap)
                        .onTapGesture { onSelect(swap) }
                }
            }
        }
    }
}

// MARK: - Swap History Tab

struct SwapHistoryTab: View {
    let swaps: [BillSwap]
    let onSelect: (BillSwap) -> Void

    var body: some View {
        if swaps.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle",
                title: "No History Yet",
                message: "Your completed swaps will appear here."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(swaps) { swap in
                    SwapCard(swap: swap, showStatus: true)
                        .onTapGesture { onSelect(swap) }
                }
            }
        }
    }
}

// MARK: - Bill Card (Redesigned)

struct BillCard: View {
    let bill: SwapBill
    var showStatus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category icon
                Image(systemName: bill.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.billixMoneyGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.billixMoneyGreen.opacity(0.1))
                    .cornerRadius(10)

                // Bill info
                VStack(alignment: .leading, spacing: 2) {
                    Text(bill.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2D3B35"))

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.caption)
                            .foregroundColor(Color(hex: "666666"))
                    }
                }

                Spacer()

                // Amount and status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.formattedAmount)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.billixMoneyGreen)

                    if showStatus {
                        StatusBadge(
                            text: bill.status.displayName,
                            color: statusColor
                        )
                    }
                }
            }

            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(bill.formattedDueDate)
                        .font(.caption)
                }
                .foregroundColor(Color(hex: "666666"))

                Spacer()

                Text(bill.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "F7F9F8"))
                    .cornerRadius(6)
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch bill.status {
        case .active: return Color.billixMoneyGreen
        case .lockedInSwap: return .orange
        case .paidConfirmed: return .blue
        case .draft: return .gray
        case .expired: return .red
        case .removed: return .gray
        }
    }
}

// MARK: - Swap Card (Redesigned)

struct SwapCard: View {
    let swap: BillSwap
    var showStatus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Swap type icon
                Image(systemName: swap.swapType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.billixMoneyGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.billixMoneyGreen.opacity(0.1))
                    .cornerRadius(10)

                // Swap info
                VStack(alignment: .leading, spacing: 2) {
                    Text(swap.swapType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2D3B35"))

                    Text(swap.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(Color(hex: "666666"))
                }

                Spacer()

                SwapStatusBadge(status: swap.status)
            }

            // Time remaining (if applicable)
            if let timeRemaining = swap.timeRemainingString {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(timeRemaining)
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Status Badge (Generic)

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - Swap Status Badge

struct SwapStatusBadge: View {
    let status: BillSwapStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch status {
        case .offered, .countered: return .blue
        case .acceptedPendingFee, .locked: return .orange
        case .awaitingProof: return .purple
        case .completed: return Color.billixMoneyGreen
        case .failed, .disputed: return .red
        case .cancelled, .expired: return .gray
        }
    }
}

// MARK: - Empty State (Redesigned)

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color.gray.opacity(0.4))

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "2D3B35"))

            Text(message)
                .font(.caption)
                .foregroundColor(Color(hex: "666666"))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Helpers

extension BillSwap {
    var timeRemainingString: String? {
        let now = Date()

        if status == .offered, let deadline = acceptDeadline {
            let remaining = deadline.timeIntervalSince(now)
            if remaining > 0 {
                let hours = Int(remaining / 3600)
                let minutes = Int(remaining) % 3600 / 60
                return hours > 0 ? "\(hours)h \(minutes)m left to accept" : "\(minutes)m left"
            }
        }

        if status == .awaitingProof, let deadline = proofDueDeadline {
            let remaining = deadline.timeIntervalSince(now)
            if remaining > 0 {
                let hours = Int(remaining / 3600)
                return "\(hours)h left for proof"
            }
        }

        return nil
    }
}

#Preview {
    BillSwapView()
}
