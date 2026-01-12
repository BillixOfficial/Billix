//
//  NewChatView.swift
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
                    // Custom header
                    headerView

                    // Search bar
                    searchBar

                    // Divider
                    Rectangle()
                        .fill(ChatTheme.divider)
                        .frame(height: 1)

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
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ChatTheme.accent)
            }

            Spacer()

            Text("New Message")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ChatTheme.primaryText)

            Spacer()

            // Invisible spacer for centering
            Text("Cancel")
                .font(.system(size: 17, weight: .medium))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChatTheme.cardBackground)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Text("@")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ChatTheme.info)

            TextField("Enter username...", text: $searchQuery)
                .font(.system(size: 17))
                .foregroundColor(ChatTheme.primaryText)
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
                        .font(.system(size: 20))
                        .foregroundColor(ChatTheme.placeholderText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ChatTheme.searchBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChatTheme.cardBackground)
    }

    // MARK: - Results List

    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(searchResults) { user in
                    Button {
                        onUserSelected(user)
                    } label: {
                        UserSearchRowEnhanced(user: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(ChatTheme.info.opacity(0.12))
                    .frame(width: 110, height: 110)

                Text("@")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(ChatTheme.info)
            }

            VStack(spacing: 10) {
                Text("Find Someone to Chat With")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ChatTheme.primaryText)

                Text("Enter a username to start a new conversation.\nUsernames look like @savingsking")
                    .font(.system(size: 16))
                    .foregroundColor(ChatTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(ChatTheme.secondaryText.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.slash.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ChatTheme.secondaryText.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Users Found")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ChatTheme.primaryText)

                Text("Try a different username")
                    .font(.system(size: 16))
                    .foregroundColor(ChatTheme.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.3)
                .tint(ChatTheme.info)

            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ChatTheme.secondaryText)

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

// MARK: - Enhanced User Search Row

private struct UserSearchRowEnhanced: View {
    let user: ChatParticipant

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(ChatTheme.accent.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ChatTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ChatTheme.primaryText)

                if !user.formattedHandle.isEmpty {
                    Text(user.formattedHandle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ChatTheme.info)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ChatTheme.placeholderText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ChatTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews

#if DEBUG
struct NewChatView_Previews: PreviewProvider {
    static var previews: some View {
        NewChatView { user in
            print("Selected: \(user.formattedHandle)")
        }
    }
}
#endif
