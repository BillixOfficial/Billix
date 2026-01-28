//
//  CommentsSheetView.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Bottom sheet for viewing and posting comments on community posts
//

import SwiftUI

struct CommentsSheetView: View {
    let post: CommunityPost
    let onCommentCountChanged: (Int) -> Void

    @StateObject private var viewModel: CommentsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    private let backgroundColor = Color(hex: "#F5F5F7")
    private let cardBackground = Color.white
    private let textColor = Color(hex: "#1A1A1A")
    private let secondaryColor = Color(hex: "#6B7280")
    private let accentColor = Color.billixDarkTeal

    init(post: CommunityPost, onCommentCountChanged: @escaping (Int) -> Void) {
        self.post = post
        self.onCommentCountChanged = onCommentCountChanged
        self._viewModel = StateObject(wrappedValue: CommentsViewModel(postId: post.id))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Comments list
                    if viewModel.isLoading && viewModel.comments.isEmpty {
                        loadingView
                    } else if viewModel.comments.isEmpty {
                        emptyStateView
                    } else {
                        commentsList
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.loadComments()
        }
        .onChange(of: viewModel.commentCount) { _, newCount in
            onCommentCountChanged(newCount)
        }
    }

    // MARK: - Comments List

    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.organizedComments) { comment in
                    CommentRowView(
                        comment: comment,
                        isReply: false,
                        onLike: {
                            Task {
                                await viewModel.toggleLike(for: comment)
                            }
                        },
                        onReply: {
                            viewModel.startReply(to: comment)
                            isInputFocused = true
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteComment(comment)
                            }
                        }
                    )

                    if comment.id != viewModel.organizedComments.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.loadComments()
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Reply indicator
            if let replyingTo = viewModel.replyingTo {
                HStack {
                    Text("Replying to \(replyingTo.authorUsername)")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryColor)

                    Spacer()

                    Button {
                        viewModel.cancelReply()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#F3F4F6"))
            }

            // Input field
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryColor)
                    )

                // Text field
                TextField(viewModel.inputPlaceholder, text: $viewModel.newCommentText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Send button
                Button {
                    Task {
                        await viewModel.sendComment()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(
                            viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? secondaryColor
                            : accentColor
                        )
                }
                .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(accentColor)

            Text("Loading comments...")
                .font(.system(size: 15))
                .foregroundColor(secondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#D1D5DB"))

            VStack(spacing: 6) {
                Text("No comments yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textColor)

                Text("Be the first to comment!")
                    .font(.system(size: 15))
                    .foregroundColor(secondaryColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Comments Sheet") {
    CommentsSheetView(
        post: CommunityPost.mockPosts[0],
        onCommentCountChanged: { _ in }
    )
}
