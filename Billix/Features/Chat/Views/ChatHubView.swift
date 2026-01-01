//
//  ChatHubView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

// MARK: - Theme

private enum ChatTheme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let info = Color(hex: "#5BA4D4")
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
                    // Search bar
                    searchBar

                    // Content
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        loadingView
                    } else if !viewModel.searchQuery.isEmpty {
                        searchResultsView
                    } else if viewModel.conversations.isEmpty {
                        emptyStateView
                    } else {
                        conversationsList
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ChatTheme.accent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(ChatTheme.accent)
                }
            }
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(ChatTheme.secondaryText)

                TextField("Search users or conversations...", text: $viewModel.searchQuery)
                    .font(.system(size: 16))
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
                            .font(.system(size: 16))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ChatTheme.cardBackground)
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "message.circle")
                .font(.system(size: 70))
                .foregroundColor(ChatTheme.info.opacity(0.5))

            Text("No Messages Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ChatTheme.primaryText)

            Text("Start a conversation by searching\nfor someone's @handle")
                .font(.system(size: 15))
                .foregroundColor(ChatTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showNewChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.message.fill")
                    Text("Start a Chat")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(ChatTheme.info)
                .cornerRadius(12)
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
