//
//  MatchDetailView.swift
//  Billix
//
//  The "Handshake" UI - shows swap details and handles the fee gate
//  Redesigned to match the light theme design system
//

import SwiftUI
import PhotosUI

// MARK: - Theme Colors (matching BillSwapView)

private enum DetailTheme {
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

    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8
}

// MARK: - Update Types

private struct ChatUnlockedUpdate: Encodable {
    let chatUnlocked: Bool
    let chatUnlockedAt: String

    enum CodingKeys: String, CodingKey {
        case chatUnlocked = "chat_unlocked"
        case chatUnlockedAt = "chat_unlocked_at"
    }
}

// MARK: - Main View

struct MatchDetailView: View {
    @StateObject private var viewModel: SwapDetailViewModel
    @StateObject private var tokenService = TokenService.shared
    @StateObject private var dealService = DealService.shared
    @StateObject private var extensionService = ExtensionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showProofPicker = false
    @State private var selectedProofItem: PhotosPickerItem?
    @State private var showDisputeSheet = false
    @State private var showDisclaimer = false
    @State private var showChat = false
    @State private var showTokenPurchase = false

    // New Deal Builder states
    @State private var showDealBuilder = false
    @State private var showExtensionRequest = false
    @State private var showExtensionResponse = false
    @State private var showTimeline = false
    @State private var currentDeal: SwapDeal?
    @State private var pendingExtension: ExtensionRequest?
    @State private var recentEvents: [SwapEvent] = []

    init(swapId: UUID) {
        _viewModel = StateObject(wrappedValue: SwapDetailViewModel(swapId: swapId))
    }

    var body: some View {
        mainContent
            .navigationTitle("Swap Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { await loadInitialData() }
            .photosPicker(isPresented: $showProofPicker, selection: $selectedProofItem, matching: .images)
            .onChange(of: selectedProofItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.proofImage = image
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .alert("Payment Successful!", isPresented: $viewModel.showPaymentSuccess) {
                Button("Continue", role: .cancel) { }
            } message: {
                Text("You can now see your partner's account details. Pay their bill to complete the swap.")
            }
            .alert("Proof Uploaded!", isPresented: $viewModel.showProofSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your partner will be notified. The swap will complete once they pay your bill too.")
            }
            .sheet(isPresented: $showDisputeSheet) {
                DisputeSheetView { reason in
                    Task {
                        await viewModel.raiseDispute(reason: reason)
                    }
                }
            }
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerSheetView {
                    showDisclaimer = false
                    showChat = true
                }
            }
            .sheet(isPresented: $showDealBuilder) {
                if let swap = viewModel.swap {
                    DealBuilderSheet(
                        swap: swap,
                        existingDeal: currentDeal
                    ) { newDeal in
                        currentDeal = newDeal
                        Task { await loadDealAndEvents() }
                    }
                }
            }
            .sheet(isPresented: $showExtensionRequest) {
                if let swap = viewModel.swap, let deal = currentDeal {
                    let isUserA = swap.isUserA(userId: viewModel.currentUserId ?? UUID())
                    let deadline = isUserA ? deal.deadlineA : deal.deadlineB
                    ExtensionRequestSheet(
                        swapId: swap.id,
                        currentDeadline: deadline
                    ) {
                        Task { await loadDealAndEvents() }
                    }
                }
            }
            .sheet(isPresented: $showExtensionResponse) {
                if let extension_ = pendingExtension {
                    ExtensionResponseSheet(request: extension_) { approved in
                        Task { await loadDealAndEvents() }
                    }
                }
            }
            .sheet(isPresented: $showTimeline) {
                if let swap = viewModel.swap {
                    NavigationStack {
                        SwapTimelineView(swapId: swap.id)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { showTimeline = false }
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showTierAdvancement) {
                if let result = viewModel.tierAdvancementResult {
                    TierAdvancementSheet(result: result)
                }
            }
            .navigationDestination(isPresented: $showChat) {
                chatDestination
            }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            DetailTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let swap = viewModel.swap {
                        statusHeader(swap: swap)

                        // Deal Card Section (new)
                        dealSection(swap: swap)

                        // Extension Alert (if pending)
                        if let ext = pendingExtension {
                            extensionAlertCard(extension_: ext)
                        }

                        progressSection(swap: swap)
                        billsComparisonSection

                        // Recent Activity (new)
                        if !recentEvents.isEmpty {
                            recentActivitySection
                        }

                        actionSection(swap: swap)
                    }
                }
                .padding(.horizontal, DetailTheme.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Deal Section

    @ViewBuilder
    private func dealSection(swap: BillSwapTransaction) -> some View {
        if let deal = currentDeal {
            VStack(spacing: 12) {
                DealCardView(
                    deal: deal,
                    swap: swap,
                    onAccept: {
                        Task {
                            try? await DealService.shared.acceptDeal(dealId: deal.id)
                            await loadDealAndEvents()
                        }
                    },
                    onReject: {
                        Task {
                            try? await DealService.shared.rejectDeal(dealId: deal.id)
                            await loadDealAndEvents()
                        }
                    },
                    onCounter: {
                        showDealBuilder = true
                    }
                )

                // Extension button (only for active deals)
                if deal.status == .accepted {
                    extensionButton
                }
            }
        } else if swap.status == .pending || swap.status == .active {
            // No deal yet - show propose button
            proposeTermsButton
        }
    }

    private var proposeTermsButton: some View {
        Button {
            showDealBuilder = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Propose Swap Terms")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Set amounts, deadlines, and proof requirements")
                        .font(.system(size: 12))
                        .foregroundColor(DetailTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(DetailTheme.primaryText)
            .padding(16)
            .background(DetailTheme.cardBackground)
            .cornerRadius(DetailTheme.cornerRadius)
            .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: DetailTheme.cornerRadius)
                    .stroke(DetailTheme.accent, lineWidth: 2)
            )
        }
    }

    private var extensionButton: some View {
        Button {
            showExtensionRequest = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 14))
                Text("Request Extension")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(DetailTheme.warning)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DetailTheme.warning.opacity(0.1))
            .cornerRadius(20)
        }
    }

    // MARK: - Extension Alert Card

    private func extensionAlertCard(extension_: ExtensionRequest) -> some View {
        let canRespond = extension_.canRespond(userId: viewModel.currentUserId ?? UUID())

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundColor(DetailTheme.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text(canRespond ? "Extension Request" : "Your Extension Request")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DetailTheme.primaryText)

                    Text(extension_.formattedExtensionDuration)
                        .font(.system(size: 13))
                        .foregroundColor(DetailTheme.secondaryText)

                    if let remaining = extension_.formattedTimeRemaining {
                        Text(remaining)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DetailTheme.warning)
                    }
                }

                Spacer()

                if canRespond {
                    Button {
                        showExtensionResponse = true
                    } label: {
                        Text("Respond")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DetailTheme.accent)
                            .cornerRadius(8)
                    }
                } else {
                    Text("Pending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DetailTheme.warning)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DetailTheme.warning.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(DetailTheme.warning.opacity(0.08))
        .cornerRadius(DetailTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DetailTheme.cornerRadius)
                .stroke(DetailTheme.warning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DetailTheme.secondaryText)
                    .tracking(0.5)

                Spacer()

                Button {
                    showTimeline = true
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(DetailTheme.accent)
                }
            }

            CompactSwapTimeline(events: recentEvents, maxEvents: 3)
        }
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 12) {
                // Timeline button
                Button {
                    showTimeline = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(DetailTheme.accent)
                }

                // More options menu
                Menu {
                    Button {
                        showChat = true
                    } label: {
                        Label("Open Chat", systemImage: "message")
                    }

                    if currentDeal?.status == .accepted {
                        Button {
                            showExtensionRequest = true
                        } label: {
                            Label("Request Extension", systemImage: "calendar.badge.plus")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDisputeSheet = true
                    } label: {
                        Label("Report Issue", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(DetailTheme.accent)
                }
            }
        }
    }

    // MARK: - Chat Destination

    @ViewBuilder
    private var chatDestination: some View {
        if let swap = viewModel.swap,
           let userId = viewModel.currentUserId {
            let partnerId = swap.isUserA(userId: userId) ? swap.userBId : swap.userAId
            let participant = ChatParticipant(
                userId: partnerId,
                handle: nil,
                displayName: "Swap Partner"
            )
            ChatConversationView(conversationId: swap.id, otherParticipant: participant)
        }
    }

    // MARK: - Load Initial Data

    private func loadInitialData() async {
        await viewModel.loadSwap()
        await viewModel.loadFreeSwapCount()
        await tokenService.loadBalance()
        await loadDealAndEvents()
    }

    private func loadDealAndEvents() async {
        guard let swap = viewModel.swap else { return }

        // Load current deal
        currentDeal = try? await DealService.shared.getCurrentDeal(for: swap.id)

        // Load pending extension
        pendingExtension = try? await ExtensionService.shared.getPendingRequest(for: swap.id)

        // Load recent events
        let events = try? await SwapEventService.shared.getEvents(for: swap.id)
        recentEvents = Array((events ?? []).suffix(5))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading swap details...")
                .font(.system(size: 14))
                .foregroundColor(DetailTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Status Header

    private func statusHeader(swap: BillSwapTransaction) -> some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusColor(for: swap.status).opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: swap.status.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(statusColor(for: swap.status))
            }

            // Message
            Text(viewModel.statusMessage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DetailTheme.primaryText)
                .multilineTextAlignment(.center)

            // Status badge
            HStack(spacing: 6) {
                Image(systemName: swap.status.iconName)
                    .font(.system(size: 12))
                Text(swap.status.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(statusColor(for: swap.status))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(statusColor(for: swap.status).opacity(0.1))
            .cornerRadius(20)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private func statusColor(for status: BillSwapStatus) -> Color {
        switch status {
        case .pending: return DetailTheme.warning
        case .active: return DetailTheme.info
        case .expired: return DetailTheme.danger
        case .completed: return DetailTheme.success
        case .dispute: return DetailTheme.danger
        }
    }

    // MARK: - Progress Section

    private func progressSection(swap: BillSwapTransaction) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("SWAP PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DetailTheme.secondaryText)
                    .tracking(0.5)
                Spacer()
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DetailTheme.accent)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DetailTheme.accent.opacity(0.12))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [DetailTheme.accent, DetailTheme.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.progress, height: 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.progress)
                }
            }
            .frame(height: 10)

            // Progress steps
            HStack(spacing: 0) {
                ProgressStepView(
                    title: "You Paid\nFee",
                    isComplete: viewModel.hasPaidFee,
                    isFirst: true
                )
                ProgressStepView(
                    title: "Partner\nPaid Fee",
                    isComplete: swap.bothPaidFees,
                    isFirst: false
                )
                ProgressStepView(
                    title: "You Paid\nBill",
                    isComplete: viewModel.hasPaidPartner,
                    isFirst: false
                )
                ProgressStepView(
                    title: "Partner\nPaid Bill",
                    isComplete: viewModel.partnerHasPaidMe,
                    isFirst: false
                )
            }
        }
        .padding(DetailTheme.cardPadding)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    // MARK: - Bills Comparison

    private var billsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BILLS IN THIS SWAP")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DetailTheme.secondaryText)
                .tracking(0.5)

            HStack(spacing: 12) {
                // My bill
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DetailTheme.secondaryText)

                    if let bill = viewModel.myBill {
                        BillCompactCard(
                            bill: bill,
                            showAccountNumber: true,
                            isBlurred: false
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                // Swap icon
                ZStack {
                    Circle()
                        .fill(DetailTheme.accentLight)
                        .frame(width: 36, height: 36)

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DetailTheme.accent)
                }

                // Partner's bill
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner's Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DetailTheme.secondaryText)

                    if let bill = viewModel.partnerBill {
                        BillCompactCard(
                            bill: bill,
                            showAccountNumber: viewModel.canSeeAccountNumber,
                            isBlurred: !viewModel.canSeeAccountNumber
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(DetailTheme.cardPadding)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    // MARK: - Action Section

    @ViewBuilder
    private func actionSection(swap: BillSwapTransaction) -> some View {
        if viewModel.isExpired {
            expiredSection
        } else if !viewModel.hasPaidFee {
            handshakeFeeSection
        } else if !viewModel.canSeeAccountNumber {
            // User committed but partner hasn't - waiting state
            waitingForPartnerCommitSection
        } else if !viewModel.hasPaidPartner {
            payPartnerSection
        } else if !viewModel.partnerHasPaidMe {
            waitingSection
        } else {
            completedSection
        }
    }

    private var expiredSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DetailTheme.danger.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "clock.badge.xmark.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DetailTheme.danger)
            }

            VStack(spacing: 8) {
                Text("Match Expired")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("This match has expired because both parties didn't confirm within 24 hours.")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                dismiss()
            } label: {
                Text("Find New Matches")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DetailTheme.accent)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private var waitingForPartnerCommitSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DetailTheme.info.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "hourglass")
                    .font(.system(size: 32))
                    .foregroundColor(DetailTheme.info)
            }

            VStack(spacing: 8) {
                Text("Waiting for Partner")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("You've confirmed! Waiting for your partner to confirm the swap. Once they do, account details will be revealed.")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                // Timer countdown
                if let timeRemaining = viewModel.formattedTimeRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(timeRemaining)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(DetailTheme.warning)
                    .padding(.top, 8)
                }
            }

            // Your confirmation status
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DetailTheme.success)
                Text("You've confirmed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DetailTheme.success)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DetailTheme.success.opacity(0.1))
            .cornerRadius(8)

            // Animated waiting indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(DetailTheme.info)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private var handshakeFeeSection: some View {
        VStack(spacing: 20) {
            // Lock icon
            ZStack {
                Circle()
                    .fill(DetailTheme.accent.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "message.badge.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DetailTheme.accent)
            }

            VStack(spacing: 8) {
                Text("Ready to Connect")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("Use 1 Connect Token to unlock chat with your match. You'll exchange payment details (Venmo, CashApp) directly in chat.")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                // Timer countdown
                if let timeRemaining = viewModel.formattedTimeRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(timeRemaining)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(DetailTheme.warning)
                    .padding(.top, 4)
                }
            }

            // Token balance display
            tokenBalanceCard

            // Connect button - different text based on user tier
            Button {
                Task {
                    await useTokenAndConnect()
                }
            } label: {
                HStack(spacing: 8) {
                    if tokenService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: tokenButtonIcon)
                            .font(.system(size: 16))
                        Text(tokenButtonText)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canUseToken ? DetailTheme.accent : DetailTheme.secondaryText)
                .cornerRadius(12)
            }
            .disabled(tokenService.isLoading || !canUseToken)

            // Buy more tokens option (shown when no tokens available)
            if !tokenService.hasUnlimitedTokens && !tokenService.hasTokens {
                Button {
                    Task {
                        try? await tokenService.purchaseTokenPack()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Buy 3 Tokens for $1.99")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(DetailTheme.accent)
                }
                .padding(.top, 4)

                Button {
                    // Navigate to Prime subscription
                } label: {
                    Text("or Get Unlimited with Prime")
                        .font(.system(size: 12))
                        .foregroundColor(DetailTheme.secondaryText)
                }
            }
        }
        .padding(24)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private var tokenBalanceCard: some View {
        HStack(spacing: 12) {
            // Token icon
            ZStack {
                Circle()
                    .fill(DetailTheme.accent.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: tokenService.hasUnlimitedTokens ? "infinity" : "coins")
                    .font(.system(size: 18))
                    .foregroundColor(DetailTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Tokens")
                    .font(.system(size: 12))
                    .foregroundColor(DetailTheme.secondaryText)

                if tokenService.hasUnlimitedTokens {
                    HStack(spacing: 4) {
                        Text("Unlimited")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DetailTheme.accent)
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                } else {
                    Text("\(tokenService.totalAvailableTokens) available")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DetailTheme.primaryText)
                }
            }

            Spacer()

            if !tokenService.hasUnlimitedTokens {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tokenService.freeTokensRemaining) free")
                        .font(.system(size: 11))
                        .foregroundColor(DetailTheme.secondaryText)
                    Text("\(tokenService.tokenBalance) purchased")
                        .font(.system(size: 11))
                        .foregroundColor(DetailTheme.secondaryText)
                }
            }
        }
        .padding(14)
        .background(DetailTheme.background)
        .cornerRadius(12)
    }

    private var canUseToken: Bool {
        tokenService.hasUnlimitedTokens || tokenService.hasTokens
    }

    private var tokenButtonIcon: String {
        if tokenService.hasUnlimitedTokens {
            return "star.fill"
        } else if tokenService.hasTokens {
            return "message.fill"
        } else {
            return "lock.fill"
        }
    }

    private var tokenButtonText: String {
        if tokenService.hasUnlimitedTokens {
            return "Connect (Free with Prime)"
        } else if tokenService.freeTokensRemaining > 0 {
            return "Use Free Token to Connect"
        } else if tokenService.tokenBalance > 0 {
            return "Use 1 Token to Connect"
        } else {
            return "No Tokens Available"
        }
    }

    private func useTokenAndConnect() async {
        guard let swapId = viewModel.swap?.id else { return }

        do {
            let success = try await tokenService.useToken(for: swapId)
            if success {
                // Mark swap as chat unlocked
                try await SupabaseService.shared.client
                    .from("swaps")
                    .update(ChatUnlockedUpdate(
                        chatUnlocked: true,
                        chatUnlockedAt: ISO8601DateFormatter().string(from: Date())
                    ))
                    .eq("id", value: swapId.uuidString)
                    .execute()

                // Show disclaimer before opening chat
                showDisclaimer = true
            }
        } catch {
            viewModel.error = error
            viewModel.showError = true
        }
    }

    private var payPartnerSection: some View {
        VStack(spacing: 20) {
            // Success icon
            ZStack {
                Circle()
                    .fill(DetailTheme.success.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DetailTheme.success)
            }

            VStack(spacing: 8) {
                Text("Account Unlocked!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("Pay your partner's bill, then upload proof")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
            }

            if let bill = viewModel.partnerBill {
                // Account details card
                VStack(spacing: 12) {
                    if let accountNumber = bill.accountNumber {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Number")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(DetailTheme.secondaryText)
                                Text(accountNumber)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(DetailTheme.primaryText)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = accountNumber
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16))
                                    .foregroundColor(DetailTheme.accent)
                                    .padding(10)
                                    .background(DetailTheme.accentLight)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .background(DetailTheme.accent.opacity(0.05))
                        .cornerRadius(12)
                    }

                    if let guestPayLink = bill.guestPayLink, let url = URL(string: guestPayLink) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                    .font(.system(size: 16))
                                Text("Open Guest Pay Portal")
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(DetailTheme.info)
                            .padding(14)
                            .background(DetailTheme.info.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                }

                // Divider
                Rectangle()
                    .fill(DetailTheme.secondaryText.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, 8)

                // Proof upload section
                VStack(spacing: 12) {
                    Text("Upload Payment Proof")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DetailTheme.primaryText)

                    if let proofImage = viewModel.proofImage {
                        Image(uiImage: proofImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DetailTheme.accent.opacity(0.3), lineWidth: 2)
                            )

                        Button {
                            Task {
                                await viewModel.uploadProof()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isUploadingProof {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Submit Proof")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DetailTheme.success)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isUploadingProof)
                    } else {
                        Button {
                            showProofPicker = true
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Take Photo of Receipt")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(DetailTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(DetailTheme.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DetailTheme.secondaryText.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private var waitingSection: some View {
        VStack(spacing: 20) {
            // Clock icon with animation
            ZStack {
                Circle()
                    .fill(DetailTheme.info.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "clock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DetailTheme.info)
            }

            VStack(spacing: 8) {
                Text("Waiting for Partner")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("You've done your part! Now waiting for your partner to pay your bill.")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Animated waiting indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(DetailTheme.info)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                }
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }

    private var completedSection: some View {
        VStack(spacing: 20) {
            // Success checkmark
            ZStack {
                Circle()
                    .fill(DetailTheme.success.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(DetailTheme.success)
            }

            VStack(spacing: 8) {
                Text("Swap Complete!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DetailTheme.primaryText)

                Text("Both bills have been paid successfully!")
                    .font(.system(size: 14))
                    .foregroundColor(DetailTheme.secondaryText)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DetailTheme.success)
                    .cornerRadius(12)
            }
        }
        .padding(28)
        .background(DetailTheme.cardBackground)
        .cornerRadius(DetailTheme.cornerRadius)
        .shadow(color: DetailTheme.shadowColor, radius: DetailTheme.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Progress Step View

private struct ProgressStepView: View {
    let title: String
    let isComplete: Bool
    let isFirst: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isComplete ? DetailTheme.success : DetailTheme.secondaryText.opacity(0.15))
                    .frame(width: 28, height: 28)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(DetailTheme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isComplete ? DetailTheme.primaryText : DetailTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bill Compact Card

private struct BillCompactCard: View {
    let bill: SwapBill
    let showAccountNumber: Bool
    let isBlurred: Bool

    private var iconColor: Color {
        switch bill.category {
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phonePlan: return .green
        default: return DetailTheme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Provider with icon
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: bill.category?.icon ?? "doc.fill")
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                }

                Text(bill.providerName ?? "Unknown")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DetailTheme.primaryText)
                    .lineLimit(1)
            }

            // Amount
            Text(bill.formattedAmount)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(DetailTheme.accent)

            // Due date
            if let dueDate = bill.formattedDueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(dueDate)
                        .font(.system(size: 11))
                }
                .foregroundColor(DetailTheme.secondaryText)
            }

            // Account number
            HStack(spacing: 4) {
                Text("Acct:")
                    .font(.system(size: 11))
                    .foregroundColor(DetailTheme.secondaryText)

                if showAccountNumber, let account = bill.accountNumber {
                    Text(account)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(DetailTheme.primaryText)
                } else {
                    Text("••••••••")
                        .font(.system(size: 11))
                        .foregroundColor(DetailTheme.secondaryText)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DetailTheme.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DetailTheme.secondaryText.opacity(0.1), lineWidth: 1)
        )
        .blur(radius: isBlurred ? 4 : 0)
    }
}

// MARK: - Status Badge (Updated)

struct StatusBadge: View {
    let status: BillSwapStatus

    var config: (color: Color, icon: String) {
        switch status {
        case .pending: return (DetailTheme.warning, "clock.fill")
        case .active: return (DetailTheme.info, "arrow.triangle.2.circlepath")
        case .expired: return (DetailTheme.danger, "clock.badge.xmark.fill")
        case .completed: return (DetailTheme.success, "checkmark.circle.fill")
        case .dispute: return (DetailTheme.danger, "exclamationmark.triangle.fill")
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: config.icon)
                .font(.system(size: 11))
            Text(status.displayName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(config.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(config.color.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Dispute Sheet View (Updated)

struct DisputeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DetailTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(DetailTheme.warning.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(DetailTheme.warning)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Report an Issue")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DetailTheme.primaryText)

                        Text("Please describe the issue with this swap")
                            .font(.system(size: 14))
                            .foregroundColor(DetailTheme.secondaryText)
                    }

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DetailTheme.secondaryText)

                        TextEditor(text: $reason)
                            .font(.system(size: 15))
                            .foregroundColor(DetailTheme.primaryText)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(DetailTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DetailTheme.secondaryText.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, DetailTheme.horizontalPadding)

                    Spacer()

                    // Submit button
                    Button {
                        onSubmit(reason)
                        dismiss()
                    } label: {
                        Text("Submit Report")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(reason.isEmpty ? DetailTheme.secondaryText : DetailTheme.danger)
                            .cornerRadius(12)
                    }
                    .disabled(reason.isEmpty)
                    .padding(.horizontal, DetailTheme.horizontalPadding)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dispute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DetailTheme.accent)
                }
            }
        }
    }
}

// MARK: - Legacy Support (for old ProgressStep usage)

struct ProgressStep: View {
    let title: String
    let isComplete: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isComplete ? DetailTheme.success : DetailTheme.secondaryText.opacity(0.15))
                    .frame(width: 24, height: 24)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(DetailTheme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isComplete ? DetailTheme.primaryText : DetailTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Legacy BillInfoCard Support

struct BillInfoCard: View {
    let bill: SwapBill
    let showAccountNumber: Bool
    let isBlurred: Bool

    private var iconColor: Color {
        switch bill.category {
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phonePlan: return .green
        default: return DetailTheme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: bill.category?.icon ?? "doc.fill")
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                }

                Text(bill.providerName ?? "Unknown")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DetailTheme.primaryText)
            }

            Text(bill.formattedAmount)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(DetailTheme.accent)

            if let dueDate = bill.formattedDueDate {
                Text("Due: \(dueDate)")
                    .font(.system(size: 11))
                    .foregroundColor(DetailTheme.secondaryText)
            }

            HStack(spacing: 4) {
                Text("Acct:")
                    .font(.system(size: 11))
                    .foregroundColor(DetailTheme.secondaryText)
                if showAccountNumber, let account = bill.accountNumber {
                    Text(account)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DetailTheme.primaryText)
                } else {
                    Text("••••••••")
                        .font(.system(size: 11))
                        .foregroundColor(DetailTheme.secondaryText)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DetailTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DetailTheme.secondaryText.opacity(0.1), lineWidth: 1)
        )
        .blur(radius: isBlurred ? 4 : 0)
    }
}

// MARK: - Preview

#Preview("Match Detail View") {
    NavigationStack {
        MatchDetailView(swapId: UUID())
    }
}

#Preview("Dispute Sheet") {
    DisputeSheetView { _ in }
}

// MARK: - Disclaimer Sheet View

struct DisclaimerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DetailTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(DetailTheme.warning.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(DetailTheme.warning)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        Text("Important Notice")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(DetailTheme.primaryText)

                        Text("Billix is a connection tool only.\nWe do not handle money.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DetailTheme.primaryText)
                            .multilineTextAlignment(.center)
                    }

                    // Bullet points
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerBullet(
                            icon: "person.badge.shield.checkmark",
                            text: "You are responsible for verifying your partner"
                        )
                        DisclaimerBullet(
                            icon: "dollarsign.circle",
                            text: "Do not send money without confirming details"
                        )
                        DisclaimerBullet(
                            icon: "message.badge.filled.fill",
                            text: "Exchange payment info (Venmo, CashApp) in chat"
                        )
                        DisclaimerBullet(
                            icon: "flag.fill",
                            text: "Report suspicious behavior immediately"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(DetailTheme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, DetailTheme.horizontalPadding)

                    Spacer()

                    // Accept button
                    Button {
                        onAccept()
                    } label: {
                        Text("I Understand & Agree")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DetailTheme.accent)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, DetailTheme.horizontalPadding)

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DetailTheme.secondaryText)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Before You Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DetailTheme.secondaryText)
                    }
                }
            }
        }
    }
}

private struct DisclaimerBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(DetailTheme.accent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(DetailTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Disclaimer Sheet") {
    DisclaimerSheetView { }
}
