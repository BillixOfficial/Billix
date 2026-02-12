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

                    // Content
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        loadingView
                    } else if !viewModel.searchQuery.isEmpty {
                        searchResultsView
                    } else {
                        conversationsList
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadConversations()
            }
            .refreshable {
                await viewModel.loadConversations()
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

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.filteredConversations.isEmpty {
                    emptyStateView
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

// MARK: - Previews

#if DEBUG
struct ChatHubView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHubView()
    }
}
#endif
