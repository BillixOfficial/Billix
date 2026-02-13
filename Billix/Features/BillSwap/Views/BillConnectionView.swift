//
//  BillConnectionView.swift
//  Billix
//
//  Bill Connection feature - peer-to-peer social coordination for bill support
//  Replaces BillSwapView with the new 5-phase workflow
//

import SwiftUI
import Supabase

// MARK: - Theme (matching HomeView)

private enum ConnectionTheme {
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

struct BillConnectionView: View {
    @StateObject private var viewModel = ConnectionHomeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ConnectionTab = .board
    @State private var showRequestSheet = false
    @State private var showHelpSheet = false
    @State private var selectedConnection: Connection?
    @State private var selectedItemForSupport: CommunityBoardItem?

    enum ConnectionTab: String, CaseIterable {
        case board = "Board"
        case requests = "Requests"
        case active = "Active"
        case history = "History"

        var icon: String {
            switch self {
            case .board: return "rectangle.grid.2x2.fill"
            case .requests: return "hand.raised.fill"
            case .active: return "arrow.triangle.2.circlepath"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ConnectionTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    connectionHeader

                    // Reputation Card
                    ReputationCard(
                        currentTier: viewModel.currentTier,
                        completedConnections: viewModel.completedConnectionsCount,
                        onLearnMore: { showHelpSheet = true }
                    )
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)
                    .padding(.top, 12)

                    // Tab selector
                    connectionTabBar
                        .padding(.top, 12)

                    // Content
                    TabView(selection: $selectedTab) {
                        CommunityBoardContent(
                            viewModel: viewModel,
                            selectedItemForSupport: $selectedItemForSupport
                        )
                        .tag(ConnectionTab.board)

                        MyRequestsContent(
                            viewModel: viewModel,
                            showRequestSheet: $showRequestSheet,
                            selectedConnection: $selectedConnection
                        )
                        .tag(ConnectionTab.requests)

                        ActiveConnectionsContent(
                            viewModel: viewModel,
                            selectedConnection: $selectedConnection
                        )
                        .tag(ConnectionTab.active)

                        HistoryConnectionsContent(
                            viewModel: viewModel,
                            selectedConnection: $selectedConnection
                        )
                        .tag(ConnectionTab.history)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRequestSheet) {
                RequestBillView()
            }
            .sheet(isPresented: $showHelpSheet) {
                BillConnectionHelpView()
            }
            .sheet(item: $selectedItemForSupport) { item in
                OfferSupportSheet(bill: item.bill, viewModel: viewModel)
            }
            .navigationDestination(item: $selectedConnection) { connection in
                ConnectionDetailView(connection: connection)
            }
            .task { await viewModel.loadData() }
            .refreshable { await viewModel.refresh() }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Something went wrong.")
            }
        }
    }

    // MARK: - Header

    private var connectionHeader: some View {
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
                .foregroundColor(ConnectionTheme.accent)
            }

            Spacer()

            Text("Bill Connection")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(ConnectionTheme.primaryText)

            Spacer()

            HStack(spacing: 12) {
                Button { showHelpSheet = true } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ConnectionTheme.accent)
                }

                Button { showRequestSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ConnectionTheme.accent)
                }
            }
        }
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Tab Bar

    private var connectionTabBar: some View {
        HStack(spacing: 4) {
            ForEach(ConnectionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if selectedTab == tab {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [ConnectionTheme.accent.opacity(0.15), ConnectionTheme.accent.opacity(0.08)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: selectedTab == tab ? 18 : 16, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? ConnectionTheme.accent : ConnectionTheme.secondaryText)
                        }
                        .frame(height: 40)

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? ConnectionTheme.accent : ConnectionTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ConnectionTheme.accent.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(ConnectionTheme.accent.opacity(0.12), lineWidth: 1)
                            )
                        : nil
                    )
                }
            }
        }
        .padding(6)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(18)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 3)
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
    }
}

// MARK: - Community Board Content

private struct CommunityBoardContent: View {
    @ObservedObject var viewModel: ConnectionHomeViewModel
    @Binding var selectedItemForSupport: CommunityBoardItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.grid.2x2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ConnectionTheme.accent)
                        Text("COMMUNITY BOARD")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)
                    }

                    Spacer()

                    if !viewModel.communityRequests.isEmpty {
                        Text("\(viewModel.communityRequests.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ConnectionTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ConnectionTheme.accentLight)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, ConnectionTheme.horizontalPadding)

                if viewModel.communityRequests.isEmpty {
                    emptyBoardView
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.communityRequests) { item in
                            SupportRequestCard(item: item) {
                                selectedItemForSupport = item
                            }
                        }
                    }
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }

    private var emptyBoardView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ConnectionTheme.purple.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundColor(ConnectionTheme.purple)
            }

            VStack(spacing: 6) {
                Text("No support requests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("Check back later for bills\nthat need community support")
                    .font(.system(size: 13))
                    .foregroundColor(ConnectionTheme.secondaryText)
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
                .foregroundColor(ConnectionTheme.accent)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
    }
}

// MARK: - Support Request Card

private struct SupportRequestCard: View {
    let item: CommunityBoardItem
    let onOfferSupport: () -> Void

    private var bill: SupportBill { item.bill }

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
        default: return ConnectionTheme.accent
        }
    }

    private var urgencyColor: Color {
        Color(hex: bill.urgencyLevel.color)
    }

    private var connectionTypeColor: Color {
        item.connectionType == .mutual ? ConnectionTheme.accent : ConnectionTheme.warning
    }

    private var connectionTypeIcon: String {
        item.connectionType == .mutual ? "arrow.left.arrow.right" : "hand.raised.fill"
    }

    private var timerColor: Color {
        if item.isExpired {
            return ConnectionTheme.danger
        } else if item.timeUntilExpiry < 24 * 60 * 60 { // Less than 24h
            return ConnectionTheme.warning
        } else {
            return ConnectionTheme.secondaryText
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top badges row: Connection type + Timer
            HStack(spacing: 8) {
                // Connection type badge
                HStack(spacing: 4) {
                    Image(systemName: connectionTypeIcon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(item.connectionType.displayName)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(connectionTypeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(connectionTypeColor.opacity(0.12))
                .cornerRadius(6)

                Spacer()

                // Timer badge
                HStack(spacing: 4) {
                    Image(systemName: item.isExpired ? "clock.badge.xmark" : "clock")
                        .font(.system(size: 10, weight: .semibold))
                    Text(item.timeRemainingText)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(timerColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(timerColor.opacity(0.12))
                .cornerRadius(6)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Main content
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
                        .foregroundColor(ConnectionTheme.primaryText)

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.system(size: 13))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(urgencyColor)
                            .frame(width: 6, height: 6)
                        Text(bill.urgencyLevel.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(urgencyColor)
                    }
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.formattedAmount)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ConnectionTheme.primaryText)

                    if let location = bill.cityFromZip {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9))
                            Text(location)
                                .font(.system(size: 10))
                                .lineLimit(1)
                        }
                        .foregroundColor(ConnectionTheme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 14)

            // Action button - different for expired
            if item.isExpired {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Request Expired")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(ConnectionTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                Button(action: onOfferSupport) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Offer Support")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ConnectionTheme.accent)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .opacity(item.isExpired ? 0.7 : 1.0) // Dim expired cards
    }
}

// MARK: - My Requests Content

private struct MyRequestsContent: View {
    @ObservedObject var viewModel: ConnectionHomeViewModel
    @Binding var showRequestSheet: Bool
    @Binding var selectedConnection: Connection?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ConnectionTheme.accent)
                        Text("MY REQUESTS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)
                    }

                    Spacer()
                }
                .padding(.horizontal, ConnectionTheme.horizontalPadding)

                if viewModel.myRequests.isEmpty {
                    emptyRequestsView
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.myRequests) { connection in
                            MyRequestCard(connection: connection) {
                                selectedConnection = connection
                            }
                        }
                    }
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }

    private var emptyRequestsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ConnectionTheme.accent.opacity(0.2), ConnectionTheme.accent.opacity(0.05)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(ConnectionTheme.accent.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(ConnectionTheme.accent)
            }

            VStack(spacing: 8) {
                Text("Request support")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("Post a bill to the Community Board\nand let neighbors help you out")
                    .font(.system(size: 14))
                    .foregroundColor(ConnectionTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showRequestSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Post Request")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(ConnectionTheme.accent)
                .cornerRadius(14)
                .shadow(color: ConnectionTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
    }
}

// MARK: - My Request Card

private struct MyRequestCard: View {
    let connection: Connection
    let onTap: () -> Void

    @State private var showMutualMatches = false
    @State private var bill: SupportBill?

    /// Whether this connection can find a mutual partner
    private var canFindMutualPartner: Bool {
        connection.connectionType == .mutual &&
        connection.status == .requested &&
        connection.mutualPairId == nil
    }

    private var statusConfig: (color: Color, icon: String) {
        switch connection.status {
        case .requested: return (ConnectionTheme.warning, "clock.fill")
        case .handshake: return (ConnectionTheme.info, "bubble.left.and.bubble.right.fill")
        case .executing: return (ConnectionTheme.purple, "arrow.up.right.square")
        case .proofing: return (ConnectionTheme.info, "doc.text.magnifyingglass")
        case .completed: return (ConnectionTheme.success, "checkmark.circle.fill")
        case .disputed: return (ConnectionTheme.danger, "exclamationmark.triangle.fill")
        case .cancelled: return (ConnectionTheme.secondaryText, "xmark.circle.fill")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                VStack(spacing: 12) {
                    HStack {
                        // Phase indicator
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(statusConfig.color.opacity(0.12))
                                .frame(width: 36, height: 36)

                            Image(systemName: statusConfig.icon)
                                .font(.system(size: 14))
                                .foregroundColor(statusConfig.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Connection #\(connection.id.uuidString.prefix(8))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ConnectionTheme.primaryText)

                                // Mutual badge
                                if connection.connectionType == .mutual {
                                    HStack(spacing: 2) {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundColor(ConnectionTheme.accent)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(ConnectionTheme.accent.opacity(0.12))
                                    .cornerRadius(4)
                                }
                            }

                            Text(connection.status.phaseDescription)
                                .font(.system(size: 12))
                                .foregroundColor(ConnectionTheme.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Phase badge
                        if let phase = connection.status.phaseNumber {
                            Text("Phase \(phase)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(statusConfig.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusConfig.color.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ConnectionTheme.accent.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(ConnectionTheme.accent)
                                .frame(width: geo.size.width * connection.progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(Int(connection.progressPercentage * 100))% complete")
                            .font(.system(size: 12))
                            .foregroundColor(ConnectionTheme.secondaryText)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("View")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(ConnectionTheme.accent)
                    }
                }
                .padding(14)
            }
            .buttonStyle(PlainButtonStyle())

            // Find Mutual Partner button (for unpaired mutual requests)
            if canFindMutualPartner {
                Divider()
                    .padding(.horizontal, 14)

                Button {
                    Task {
                        // Load bill if not already loaded
                        if bill == nil {
                            bill = try? await ConnectionService.shared.getBill(id: connection.billId)
                        }
                        showMutualMatches = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                        Text("Find Mutual Partner")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ConnectionTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .sheet(isPresented: $showMutualMatches) {
            if let bill = bill {
                MutualMatchesView(myConnection: connection, myBill: bill)
            }
        }
        .task {
            // Pre-load bill if this is a mutual request
            if canFindMutualPartner && bill == nil {
                bill = try? await ConnectionService.shared.getBill(id: connection.billId)
            }
        }
    }
}

// MARK: - Active Connections Content

private struct ActiveConnectionsContent: View {
    @ObservedObject var viewModel: ConnectionHomeViewModel
    @Binding var selectedConnection: Connection?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if viewModel.activeConnections.isEmpty {
                    emptyActiveView
                } else {
                    // Header
                    HStack {
                        Text("\(viewModel.activeConnections.count) active connection\(viewModel.activeConnections.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)

                    VStack(spacing: 12) {
                        ForEach(viewModel.activeConnections) { connection in
                            ActiveConnectionCard(connection: connection) {
                                selectedConnection = connection
                            }
                        }
                    }
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)
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
                    .fill(ConnectionTheme.info.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "arrow.left.arrow.right.circle")
                    .font(.system(size: 28))
                    .foregroundColor(ConnectionTheme.info)
            }

            VStack(spacing: 6) {
                Text("No active connections")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("Offer support on the Board\nor post your own request")
                    .font(.system(size: 13))
                    .foregroundColor(ConnectionTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
    }
}

// MARK: - Active Connection Card

private struct ActiveConnectionCard: View {
    let connection: Connection
    let onTap: () -> Void

    private var statusConfig: (color: Color, icon: String) {
        switch connection.status {
        case .requested: return (ConnectionTheme.warning, "clock.fill")
        case .handshake: return (ConnectionTheme.info, "bubble.left.and.bubble.right.fill")
        case .executing: return (ConnectionTheme.purple, "arrow.up.right.square")
        case .proofing: return (ConnectionTheme.info, "doc.text.magnifyingglass")
        case .completed: return (ConnectionTheme.success, "checkmark.circle.fill")
        case .disputed: return (ConnectionTheme.danger, "exclamationmark.triangle.fill")
        case .cancelled: return (ConnectionTheme.secondaryText, "xmark.circle.fill")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    // Status icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(statusConfig.color.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: statusConfig.icon)
                            .font(.system(size: 14))
                            .foregroundColor(statusConfig.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connection #\(connection.id.uuidString.prefix(8))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ConnectionTheme.primaryText)

                        Text(connection.connectionType.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }

                    Spacer()

                    // Status badge
                    Text(connection.status.displayName)
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
                            .fill(ConnectionTheme.accent.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(ConnectionTheme.accent)
                            .frame(width: geo.size.width * connection.progressPercentage, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    if let phase = connection.status.phaseNumber {
                        Text("Phase \(phase) of 5")
                            .font(.system(size: 12))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(ConnectionTheme.accent)
                }
            }
            .padding(14)
            .background(ConnectionTheme.cardBackground)
            .cornerRadius(ConnectionTheme.cornerRadius)
            .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History Connections Content

private struct HistoryConnectionsContent: View {
    @ObservedObject var viewModel: ConnectionHomeViewModel
    @Binding var selectedConnection: Connection?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(ConnectionTheme.accent)
                        Text("CONNECTION HISTORY")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)
                    }

                    Spacer()

                    if !viewModel.completedConnections.isEmpty {
                        Text("\(viewModel.completedConnections.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ConnectionTheme.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ConnectionTheme.success.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, ConnectionTheme.horizontalPadding)

                if viewModel.completedConnections.isEmpty {
                    emptyHistoryView
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.completedConnections) { connection in
                            CompletedConnectionCard(
                                connection: connection,
                                userProfiles: viewModel.userProfiles,
                                currentUserId: viewModel.currentUserId
                            ) {
                                selectedConnection = connection
                            }
                        }
                    }
                    .padding(.horizontal, ConnectionTheme.horizontalPadding)
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ConnectionTheme.success.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 28))
                    .foregroundColor(ConnectionTheme.success)
            }

            VStack(spacing: 6) {
                Text("No completed connections yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("Completed connections will\nappear here with full details")
                    .font(.system(size: 13))
                    .foregroundColor(ConnectionTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, ConnectionTheme.horizontalPadding)
    }
}

// MARK: - Completed Connection Card

private struct CompletedConnectionCard: View {
    let connection: Connection
    let userProfiles: [UUID: ConnectionUserProfile]
    let currentUserId: UUID?
    let onTap: () -> Void

    private var initiatorProfile: ConnectionUserProfile? {
        userProfiles[connection.initiatorId]
    }

    private var supporterProfile: ConnectionUserProfile? {
        guard let supporterId = connection.supporterId else { return nil }
        return userProfiles[supporterId]
    }

    private var isInitiator: Bool {
        guard let userId = currentUserId else { return false }
        return connection.initiatorId == userId
    }

    private var roleText: String {
        isInitiator ? "You requested support" : "You provided support"
    }

    private var roleColor: Color {
        isInitiator ? ConnectionTheme.info : ConnectionTheme.success
    }

    private var roleIcon: String {
        isInitiator ? "hand.raised.fill" : "heart.fill"
    }

    private var duration: String {
        guard let completedAt = connection.completedAt else {
            return "Unknown"
        }

        let interval = completedAt.timeIntervalSince(connection.createdAt)
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(minutes)m"
        }
    }

    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: connection.createdAt)
    }

    private var formattedEndDate: String {
        guard let completedAt = connection.completedAt else {
            return "N/A"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header with success indicator
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(ConnectionTheme.success)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("Completed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ConnectionTheme.success)
                    }

                    Spacer()

                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(duration)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(ConnectionTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .padding(14)
                .background(ConnectionTheme.success.opacity(0.06))

                // Main content
                VStack(spacing: 14) {
                    // Role indicator
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(roleColor.opacity(0.12))
                                .frame(width: 32, height: 32)

                            Image(systemName: roleIcon)
                                .font(.system(size: 14))
                                .foregroundColor(roleColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(roleText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ConnectionTheme.primaryText)

                            Text(connection.connectionType.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(ConnectionTheme.secondaryText)
                        }

                        Spacer()

                        // Connection ID
                        Text("#\(connection.id.uuidString.prefix(8))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }

                    Divider()

                    // Participants section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PARTICIPANTS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)

                        // Requester
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(ConnectionTheme.info.opacity(0.12))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(ConnectionTheme.info)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Requester")
                                    .font(.system(size: 10))
                                    .foregroundColor(ConnectionTheme.secondaryText)
                                Text(initiatorProfile?.displayText ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ConnectionTheme.primaryText)
                            }

                            Spacer()

                            if isInitiator {
                                Text("You")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(ConnectionTheme.info)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ConnectionTheme.info.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }

                        // Supporter
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(ConnectionTheme.success.opacity(0.12))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(ConnectionTheme.success)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Supporter")
                                    .font(.system(size: 10))
                                    .foregroundColor(ConnectionTheme.secondaryText)
                                Text(supporterProfile?.displayText ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ConnectionTheme.primaryText)
                            }

                            Spacer()

                            if !isInitiator {
                                Text("You")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(ConnectionTheme.success)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ConnectionTheme.success.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }
                    }

                    Divider()

                    // Timeline section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TIMELINE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(ConnectionTheme.secondaryText)
                            .tracking(0.5)

                        HStack(spacing: 12) {
                            // Started
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(ConnectionTheme.info)
                                    Text("Started")
                                        .font(.system(size: 10))
                                        .foregroundColor(ConnectionTheme.secondaryText)
                                }
                                Text(formattedStartDate)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ConnectionTheme.primaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Completed
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(ConnectionTheme.success)
                                    Text("Completed")
                                        .font(.system(size: 10))
                                        .foregroundColor(ConnectionTheme.secondaryText)
                                }
                                Text(formattedEndDate)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ConnectionTheme.primaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Matched date if available
                        if let matchedAt = connection.matchedAt {
                            let formatter = DateFormatter()
                            let _ = formatter.dateStyle = .medium
                            let _ = formatter.timeStyle = .short

                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(ConnectionTheme.warning)
                                Text("Matched: \(formatter.string(from: matchedAt))")
                                    .font(.system(size: 10))
                                    .foregroundColor(ConnectionTheme.secondaryText)
                            }
                        }
                    }

                    // View details link
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("View Details")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(ConnectionTheme.accent)
                    }
                }
                .padding(14)
            }
            .background(ConnectionTheme.cardBackground)
            .cornerRadius(ConnectionTheme.cornerRadius)
            .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Offer Support Sheet

private struct OfferSupportSheet: View {
    let bill: SupportBill
    @ObservedObject var viewModel: ConnectionHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showIDVerificationSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Bill summary
                VStack(spacing: 12) {
                    Text(bill.formattedAmount)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(ConnectionTheme.accent)

                    Text(bill.category?.displayName ?? "Bill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ConnectionTheme.primaryText)

                    if let provider = bill.providerName {
                        Text(provider)
                            .font(.system(size: 14))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }
                }
                .padding(.top, 20)

                // What you'll do
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT YOU'LL DO")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ConnectionTheme.secondaryText)
                        .tracking(0.5)

                    VStack(spacing: 8) {
                        OfferStep(number: 1, text: "Chat and agree on terms")
                        OfferStep(number: 2, text: "Pay via the utility's Guest Pay portal")
                        OfferStep(number: 3, text: "Upload proof of payment")
                        OfferStep(number: 4, text: "Earn reputation points")
                    }
                }
                .padding()
                .background(ConnectionTheme.cardBackground)
                .cornerRadius(ConnectionTheme.cornerRadius)
                .padding(.horizontal)

                Spacer()

                // Confirm button
                Button {
                    isLoading = true
                    Task {
                        do {
                            // Get the connection for this bill
                            let connection = try await ConnectionService.shared.getConnectionByBillId(billId: bill.id)
                            // Offer support (moves to handshake phase)
                            _ = try await ConnectionService.shared.offerSupport(connectionId: connection.id)
                            // Refresh data and dismiss
                            await viewModel.refresh()
                            dismiss()
                        } catch let error as ConnectionError {
                            // Check for ID verification requirement
                            if case .idVerificationRequired = error {
                                showIDVerificationSheet = true
                            } else {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                            isLoading = false
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                            isLoading = false
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 16))
                            Text("Offer Support")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ConnectionTheme.accent)
                    .cornerRadius(14)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(ConnectionTheme.background)
            .navigationTitle("Offer Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ConnectionTheme.accent)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showIDVerificationSheet) {
                IDVerificationView(onVerificationComplete: {
                    // User submitted verification - dismiss sheet
                    // They'll need to wait for approval before offering support
                    showIDVerificationSheet = false
                })
            }
        }
    }
}

private struct OfferStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ConnectionTheme.accent)
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(ConnectionTheme.primaryText)

            Spacer()
        }
    }
}

// MARK: - Help View

struct BillConnectionHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ConnectionTheme.accent.opacity(0.12))
                                .frame(width: 72, height: 72)

                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(ConnectionTheme.accent)
                        }

                        Text("Bill Connection")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(ConnectionTheme.primaryText)

                        Text("Community support for your bills")
                            .font(.system(size: 14))
                            .foregroundColor(ConnectionTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // The 5 Phases
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The 5-Phase Workflow")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ConnectionTheme.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            HelpPhaseCard(phase: 1, title: "Request", description: "Post your bill to the Community Board", icon: "hand.raised.fill")
                            HelpPhaseCard(phase: 2, title: "Handshake", description: "Chat and agree on terms with your supporter", icon: "bubble.left.and.bubble.right.fill")
                            HelpPhaseCard(phase: 3, title: "Execute", description: "Supporter pays via utility's Guest Pay portal", icon: "arrow.up.right.square")
                            HelpPhaseCard(phase: 4, title: "Proof", description: "Upload and verify payment confirmation", icon: "doc.text.magnifyingglass")
                            HelpPhaseCard(phase: 5, title: "Reputation", description: "Both users earn reputation points", icon: "star.fill")
                        }
                        .padding(.horizontal)
                    }

                    // The 3 Tiers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reputation Tiers")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ConnectionTheme.primaryText)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            HelpTierCard(tier: .neighbor)
                            HelpTierCard(tier: .contributor)
                            HelpTierCard(tier: .pillar)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(ConnectionTheme.background)
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(ConnectionTheme.accent)
                }
            }
        }
    }
}

private struct HelpPhaseCard: View {
    let phase: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ConnectionTheme.accent)
                    .frame(width: 32, height: 32)

                Text("\(phase)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(ConnectionTheme.primaryText)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(ConnectionTheme.secondaryText)
            }

            Spacer()
        }
        .padding(14)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ConnectionTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

private struct HelpTierCard: View {
    let tier: ReputationTier

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tier.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: tier.icon)
                    .font(.system(size: 18))
                    .foregroundColor(tier.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("Up to $\(Int(tier.maxAmount))")
                    .font(.system(size: 13))
                    .foregroundColor(tier.color)
            }

            Spacer()

            Text(tier.requirements)
                .font(.system(size: 11))
                .foregroundColor(ConnectionTheme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ConnectionTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Reputation Card

struct ReputationCard: View {
    let currentTier: ReputationTier
    let completedConnections: Int
    let onLearnMore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Tier icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: currentTier.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: currentTier.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(currentTier.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ConnectionTheme.primaryText)

                Text("\(completedConnections) connections completed")
                    .font(.system(size: 12))
                    .foregroundColor(ConnectionTheme.secondaryText)
            }

            Spacer()

            Button(action: onLearnMore) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ConnectionTheme.secondaryText)
            }
        }
        .padding(16)
        .background(ConnectionTheme.cardBackground)
        .cornerRadius(ConnectionTheme.cornerRadius)
        .shadow(color: ConnectionTheme.shadowColor, radius: ConnectionTheme.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - ViewModel

@MainActor
class ConnectionHomeViewModel: ObservableObject {
    @Published var communityRequests: [CommunityBoardItem] = []
    @Published var myRequests: [Connection] = []
    @Published var activeConnections: [Connection] = []
    @Published var completedConnections: [Connection] = []
    @Published var completedConnectionsCount: Int = 0
    @Published var currentTier: ReputationTier = .neighbor
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false

    // Cache for user profiles (handle lookups)
    @Published var userProfiles: [UUID: ConnectionUserProfile] = [:]

    // Current user ID for determining roles
    var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ConnectionService.shared.fetchCommunityBoard()
            try await ConnectionService.shared.fetchMyConnections()

            communityRequests = ConnectionService.shared.communityRequests
            myRequests = ConnectionService.shared.myRequests
            activeConnections = ConnectionService.shared.activeConnections
            completedConnections = ConnectionService.shared.completedConnections
            completedConnectionsCount = ConnectionService.shared.completedConnections.count

            // Load profiles for completed connections
            await loadUserProfiles(for: completedConnections)

            if let info = try? await ReputationService.shared.loadUserReputation() {
                currentTier = info.reputationTier
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func refresh() async {
        await loadData()
    }

    /// Load user profiles for displaying handles in history
    private func loadUserProfiles(for connections: [Connection]) async {
        var userIds = Set<UUID>()

        for connection in connections {
            userIds.insert(connection.initiatorId)
            if let supporterId = connection.supporterId {
                userIds.insert(supporterId)
            }
        }

        for userId in userIds {
            if userProfiles[userId] == nil {
                if let profile = try? await fetchUserProfile(userId: userId) {
                    userProfiles[userId] = profile
                }
            }
        }
    }

    /// Fetch a user's profile for handle display
    private func fetchUserProfile(userId: UUID) async throws -> ConnectionUserProfile {
        let supabase = SupabaseService.shared.client

        let profile: ConnectionUserProfile = try await supabase
            .from("profiles")
            .select("user_id, handle, display_name")
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }
}

// MARK: - User Profile for Connection Display

struct ConnectionUserProfile: Codable {
    let userId: UUID
    let handle: String
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case displayName = "display_name"
    }

    var displayText: String {
        if let name = displayName, !name.isEmpty {
            return "@\(handle) (\(name))"
        }
        return "@\(handle)"
    }
}

// MARK: - Previews

struct BillConnectionView_Bill_Connection_View_Previews: PreviewProvider {
    static var previews: some View {
        BillConnectionView()
    }
}
