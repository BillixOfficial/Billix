//
//  NewChatView.swift
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

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [ChatParticipant] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    let onUserSelected: (ChatParticipant) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                ChatTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    if isSearching {
                        loadingView
                    } else if searchQuery.isEmpty {
                        instructionsView
                    } else if searchResults.isEmpty {
                        noResultsView
                    } else {
                        resultsListView
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ChatTheme.accent)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("@")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ChatTheme.info)

                TextField("Enter username...", text: $searchQuery)
                    .font(.system(size: 16))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchQuery) { _, newValue in
                        performSearch(query: newValue)
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(ChatTheme.cardBackground)
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Results List

    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(searchResults) { user in
                    Button {
                        onUserSelected(user)
                    } label: {
                        UserSearchRow(user: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "at")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(ChatTheme.info.opacity(0.5))

            Text("Find Someone to Chat With")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ChatTheme.primaryText)

            Text("Enter a username to start a new conversation.\nUsernames look like @savingsking")
                .font(.system(size: 15))
                .foregroundColor(ChatTheme.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.slash")
                .font(.system(size: 50))
                .foregroundColor(ChatTheme.secondaryText.opacity(0.5))

            Text("No Users Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ChatTheme.primaryText)

            Text("Try a different username")
                .font(.system(size: 14))
                .foregroundColor(ChatTheme.secondaryText)

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("Searching...")
                .font(.system(size: 14))
                .foregroundColor(ChatTheme.secondaryText)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Search

    private func performSearch(query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

            guard !Task.isCancelled else { return }

            do {
                let results = try await ChatService.shared.searchUsers(query: trimmedQuery)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct NewChatView_Previews: PreviewProvider {
    static var previews: some View {
        NewChatView { user in
            print("Selected: \(user.handle)")
        }
    }
}
#endif
