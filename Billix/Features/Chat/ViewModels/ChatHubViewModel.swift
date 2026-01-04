//
//  ChatHubViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI

@MainActor
class ChatHubViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var conversations: [ConversationWithDetails] = []
    @Published var searchQuery = ""
    @Published var searchResults: [ChatParticipant] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showNewChat = false

    // MARK: - Private Properties
    private let chatService = ChatService.shared
    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredConversations: [ConversationWithDetails] {
        if searchQuery.isEmpty {
            return conversations
        }

        let query = searchQuery.lowercased()
        return conversations.filter { convo in
            convo.otherParticipant.handle.lowercased().contains(query) ||
            convo.otherParticipant.displayName.lowercased().contains(query)
        }
    }

    var totalUnreadCount: Int {
        chatService.totalUnreadCount
    }

    // MARK: - Initialization

    init() {
        // Observe changes from ChatService
        Task {
            for await convos in chatService.$conversations.values {
                conversations = convos
            }
        }
    }

    // MARK: - Actions

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            try await chatService.fetchConversations()
            conversations = chatService.conversations
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func searchUsers() {
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

            guard !Task.isCancelled else { return }

            do {
                let results = try await chatService.searchUsers(query: query)
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
            }

            isSearching = false
        }
    }

    func startConversation(with user: ChatParticipant) async -> UUID? {
        do {
            let conversation = try await chatService.getOrCreateConversation(with: user.id)
            return conversation.id
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return nil
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    func refreshUnreadCount() async {
        await chatService.refreshUnreadCount()
    }
}
