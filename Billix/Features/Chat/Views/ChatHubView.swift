//
//  ChatHubView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

// MARK: - Theme

private enum ChatTheme {
    static let background = Color(hex: "#F5F7F6")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#1A2420")
    static let secondaryText = Color(hex: "#5C6B64")
    static let placeholderText = Color(hex: "#9BA8A1")
    static let accent = Color(hex: "#2D6B4D")
    static let info = Color(hex: "#3B8BC4")
    static let searchBackground = Color(hex: "#EAEEEC")
    static let divider = Color(hex: "#D8DDD9")
}

struct ChatHubView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatHubViewModel()
    @State private var selectedConversation: ConversationWithDetails?
    @State private var selectedUser: ChatParticipant?
    @State private var showNewChat = false
    @State private var selectedSwapConversation: SwapConversation?
    @State private var swapConversations: [SwapConversation] = []
    @State private var selectedTab: ChatTab = .all

    enum ChatTab: String, CaseIterable {
        case all = "All"
        case swaps = "Swaps"
        case direct = "Direct"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChatTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom header
                    headerView

                    // Search bar
                    searchBar

                    // Divider
                    Rectangle()
                        .fill(ChatTheme.divider)
                        .frame(height: 1)

                    // Tab picker
                    tabPicker

                    // Content
                    if viewModel.isLoading && viewModel.conversations.isEmpty && swapConversations.isEmpty {
                        loadingView
                    } else if !viewModel.searchQuery.isEmpty {
                        searchResultsView
                    } else {
                        contentForSelectedTab
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadConversations()
                await loadSwapConversations()
            }
            .refreshable {
                await viewModel.loadConversations()
                await loadSwapConversations()
            }
            .navigationDestination(item: $selectedConversation) { convo in
                ChatConversationView(
                    conversationId: convo.conversation.id,
                    otherParticipant: convo.otherParticipant
                )
            }
            .navigationDestination(item: $selectedUser) { user in
                NewChatConversationView(otherUser: user)
            }
            .navigationDestination(item: $selectedSwapConversation) { swapConvo in
                MatchDetailView(swapId: swapConvo.swap.id)
            }
            .sheet(isPresented: $showNewChat) {
                NewChatView { user in
                    showNewChat = false
                    selectedUser = user
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ChatTheme.accent)
            }

            Spacer()

            Text("Messages")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ChatTheme.primaryText)

            Spacer()

            Button {
                showNewChat = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ChatTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChatTheme.cardBackground)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(ChatTheme.secondaryText)

            TextField("Search users or conversations...", text: $viewModel.searchQuery)
                .font(.system(size: 16))
                .foregroundColor(ChatTheme.primaryText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.searchUsers()
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ChatTheme.placeholderText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(ChatTheme.searchBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ChatTheme.cardBackground)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ChatTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))

                            // Badge for swaps with action needed
                            if tab == .swaps {
                                let actionCount = swapConversations.filter { $0.requiresAction }.count
                                if actionCount > 0 {
                                    Text("\(actionCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        Rectangle()
                            .fill(selectedTab == tab ? ChatTheme.accent : Color.clear)
                            .frame(height: 2)
                    }
                    .foregroundColor(selectedTab == tab ? ChatTheme.accent : ChatTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(ChatTheme.cardBackground)
    }

    // MARK: - Content for Selected Tab

    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .all:
            allConversationsList
        case .swaps:
            swapConversationsList
        case .direct:
            directConversationsList
        }
    }

    // MARK: - All Conversations List

    private var allConversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Swap conversations with actions first
                let activeSwaps = swapConversations.filter { $0.requiresAction }
                if !activeSwaps.isEmpty {
                    swapSection(title: "ACTION NEEDED", conversations: activeSwaps)
                }

                // Regular conversations
                if !viewModel.filteredConversations.isEmpty {
                    ForEach(viewModel.filteredConversations) { convo in
                        Button {
                            selectedConversation = convo
                        } label: {
                            ConversationRow(conversation: convo)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Other swap conversations
                let otherSwaps = swapConversations.filter { !$0.requiresAction }
                if !otherSwaps.isEmpty {
                    swapSection(title: "ACTIVE SWAPS", conversations: otherSwaps)
                }

                if viewModel.filteredConversations.isEmpty && swapConversations.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredConversations) { convo in
                    Button {
                        selectedConversation = convo
                    } label: {
                        ConversationRow(conversation: convo)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Direct Conversations List

    private var directConversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.filteredConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 40))
                            .foregroundColor(ChatTheme.secondaryText.opacity(0.5))
                        Text("No direct messages yet")
                            .font(.system(size: 16))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                    .padding(.vertical, 60)
                } else {
                    ForEach(viewModel.filteredConversations) { convo in
                        Button {
                            selectedConversation = convo
                        } label: {
                            ConversationRow(conversation: convo)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Swap Conversations List

    private var swapConversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if swapConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 40))
                            .foregroundColor(ChatTheme.secondaryText.opacity(0.5))
                        Text("No active swaps")
                            .font(.system(size: 16))
                            .foregroundColor(ChatTheme.secondaryText)
                        Text("Your swap conversations will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(ChatTheme.secondaryText.opacity(0.7))
                    }
                    .padding(.vertical, 60)
                } else {
                    // Group by status
                    let grouped = swapConversations.groupedByStatus()
                    ForEach(grouped, id: \.status) { group in
                        swapSection(title: group.status.displayName.uppercased(), conversations: group.conversations)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Swap Section

    private func swapSection(title: String, conversations: [SwapConversation]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ChatTheme.secondaryText)
                .tracking(0.5)
                .padding(.horizontal, 4)
                .padding(.top, 8)

            ForEach(conversations) { swapConvo in
                Button {
                    selectedSwapConversation = swapConvo
                } label: {
                    SwapConversationRow(conversation: swapConvo)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Load Swap Conversations

    private func loadSwapConversations() async {
        guard let userId = SupabaseService.shared.currentUserId else { return }

        do {
            // Fetch active swaps for the user
            let swaps: [BillSwapTransaction] = try await SupabaseService.shared.client
                .from("swaps")
                .select()
                .or("user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(userId.uuidString)")
                .in("status", values: [BillSwapStatus.pending.rawValue, BillSwapStatus.active.rawValue])
                .order("created_at", ascending: false)
                .execute()
                .value

            var conversations: [SwapConversation] = []

            for swap in swaps {
                let partnerId = swap.partnerId(for: userId)

                // Get partner info
                let partnerInfo = try? await fetchPartnerInfo(partnerId: partnerId)

                // Get current deal
                let deal = try? await DealService.shared.getCurrentDeal(for: swap.id)

                // Get latest event
                let latestEvent = try? await SwapEventService.shared.getLatestEvent(for: swap.id)

                // Get pending extension
                let pendingExtension = try? await ExtensionService.shared.getPendingRequest(for: swap.id)

                let swapConvo = SwapConversation(
                    swap: swap,
                    partnerParticipant: partnerInfo ?? ChatParticipant(
                        userId: partnerId,
                        handle: nil,
                        displayName: "Swap Partner"
                    ),
                    currentDeal: deal,
                    lastEvent: latestEvent,
                    pendingExtension: pendingExtension,
                    hasUnreadEvents: false, // TODO: Implement unread tracking
                    conversationId: nil
                )
                conversations.append(swapConvo)
            }

            swapConversations = conversations.sortedByPriority
        } catch {
            print("Error loading swap conversations: \(error)")
        }
    }

    private func fetchPartnerInfo(partnerId: UUID) async throws -> ChatParticipant? {
        struct ProfileInfo: Decodable {
            let handle: String?
            let displayName: String?

            enum CodingKeys: String, CodingKey {
                case handle
                case displayName = "display_name"
            }
        }

        let profiles: [ProfileInfo] = try await SupabaseService.shared.client
            .from("profiles")
            .select("handle, display_name")
            .eq("user_id", value: partnerId.uuidString)
            .limit(1)
            .execute()
            .value

        if let profile = profiles.first {
            return ChatParticipant(
                userId: partnerId,
                handle: profile.handle,
                displayName: profile.displayName ?? profile.handle ?? "Swap Partner"
            )
        }
        return nil
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Show matching conversations first
                if !viewModel.filteredConversations.isEmpty {
                    Section {
                        ForEach(viewModel.filteredConversations) { convo in
                            Button {
                                selectedConversation = convo
                            } label: {
                                ConversationRow(conversation: convo)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        sectionHeader("Conversations")
                    }
                }

                // Show user search results
                if viewModel.isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching users...")
                            .font(.system(size: 14))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                    .padding(.vertical, 20)
                } else if !viewModel.searchResults.isEmpty {
                    Section {
                        ForEach(viewModel.searchResults) { user in
                            Button {
                                selectedUser = user
                            } label: {
                                UserSearchRow(user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        sectionHeader("Users")
                    }
                }

                if viewModel.filteredConversations.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isSearching {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(ChatTheme.secondaryText.opacity(0.5))

                        Text("No results found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ChatTheme.secondaryText)

                        Text("Try searching for a different username")
                            .font(.system(size: 14))
                            .foregroundColor(ChatTheme.secondaryText.opacity(0.7))
                    }
                    .padding(.vertical, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ChatTheme.secondaryText)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(ChatTheme.info.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ChatTheme.info)
            }

            VStack(spacing: 10) {
                Text("No Messages Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ChatTheme.primaryText)

                Text("Start a conversation by searching\nfor someone's @handle")
                    .font(.system(size: 16))
                    .foregroundColor(ChatTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showNewChat = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.message.fill")
                        .font(.system(size: 18))
                    Text("Start a Chat")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [ChatTheme.info, ChatTheme.info.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: ChatTheme.info.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading conversations...")
                .font(.system(size: 14))
                .foregroundColor(ChatTheme.secondaryText)
                .padding(.top, 12)
            Spacer()
        }
    }
}

// MARK: - New Chat Conversation View (Wrapper)

struct NewChatConversationView: View {
    let otherUser: ChatParticipant
    @State private var conversationId: UUID?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let id = conversationId {
                ChatConversationView(conversationId: id, otherParticipant: otherUser)
            } else if isLoading {
                VStack {
                    ProgressView()
                    Text("Starting conversation...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            } else {
                Text("Failed to create conversation")
                    .foregroundColor(.red)
            }
        }
        .task {
            do {
                let convo = try await ChatService.shared.getOrCreateConversation(with: otherUser.id)
                conversationId = convo.id
            } catch {
                print("Error creating conversation: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Swap Conversation Row

struct SwapConversationRow: View {
    let conversation: SwapConversation

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(Color(hex: conversation.status.badgeColor).opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: conversation.status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: conversation.status.badgeColor))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.partnerParticipant.displayName ?? "Swap Partner")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ChatTheme.primaryText)

                    Spacer()

                    if conversation.requiresAction {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }

                HStack(spacing: 6) {
                    // Status badge
                    Text(conversation.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: conversation.status.badgeColor))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: conversation.status.badgeColor).opacity(0.1))
                        .cornerRadius(4)

                    // Amount if available
                    if let amount = conversation.swapAmountText {
                        Text(amount)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ChatTheme.accent)
                    }
                }

                Text(conversation.previewText)
                    .font(.system(size: 13))
                    .foregroundColor(ChatTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(conversation.lastActivityAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(ChatTheme.secondaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ChatTheme.secondaryText.opacity(0.5))
            }
        }
        .padding(12)
        .background(ChatTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(conversation.requiresAction ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Previews

#if DEBUG
struct ChatHubView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHubView()
    }
}
#endif
