//
//  CommentRowView.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Individual comment row for comments sheet
//

import SwiftUI

struct CommentRowView: View {
    let comment: CommunityComment
    let isReply: Bool
    let onLike: () -> Void
    let onReply: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private let textColor = Color(hex: "#1A1A1A")
    private let secondaryColor = Color(hex: "#6B7280")
    private let accentColor = Color.billixDarkTeal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(hex: "#E5E7EB"))
                .frame(width: isReply ? 32 : 40, height: isReply ? 32 : 40)
                .overlay(
                    Text(comment.authorName.prefix(1).uppercased())
                        .font(.system(size: isReply ? 14 : 16, weight: .semibold))
                        .foregroundColor(secondaryColor)
                )

            VStack(alignment: .leading, spacing: 6) {
                // Author info
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor)

                    Text(comment.authorUsername)
                        .font(.system(size: 13))
                        .foregroundColor(secondaryColor)

                    Text("·")
                        .foregroundColor(secondaryColor)

                    Text(comment.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(secondaryColor)
                }

                // Content
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)

                // Actions row
                HStack(spacing: 20) {
                    // Like button
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 14))
                                .foregroundColor(comment.isLiked ? accentColor : secondaryColor)

                            if comment.likeCount > 0 {
                                Text("\(comment.likeCount)")
                                    .font(.system(size: 13))
                                    .foregroundColor(comment.isLiked ? accentColor : secondaryColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Reply button (only for top-level comments)
                    if !isReply {
                        Button(action: onReply) {
                            Text("Reply")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(secondaryColor)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Delete button (only for own comments)
                    if comment.isOwnComment {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(secondaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)

                // Nested replies
                if !comment.replies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(comment.replies) { reply in
                            CommentRowView(
                                comment: reply,
                                isReply: true,
                                onLike: onLike,
                                onReply: {},  // No nested replies
                                onDelete: onDelete
                            )
                        }
                    }
                    .padding(.top, 12)
                    .padding(.leading, 4)
                }
            }
        }
        .padding(.leading, isReply ? 20 : 0)
        .confirmationDialog(
            "Delete Comment",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
}

// MARK: - Preview

#Preview("Comment Row") {
    VStack(spacing: 20) {
        CommentRowView(
            comment: CommunityComment(
                authorName: "Sarah M.",
                authorUsername: "@sarahm",
                content: "Great tip! I'll definitely try this out. Thanks for sharing!",
                timestamp: Date().addingTimeInterval(-3600),
                likeCount: 5,
                replies: [
                    CommunityComment(
                        authorName: "Mike R.",
                        authorUsername: "@mike_r",
                        content: "Same here! Let us know how it goes.",
                        timestamp: Date().addingTimeInterval(-1800),
                        likeCount: 2
                    )
                ],
                isLiked: true
            ),
            isReply: false,
            onLike: {},
            onReply: {},
            onDelete: {}
        )

        Divider()

        CommentRowView(
            comment: CommunityComment(
                authorName: "You",
                authorUsername: "@you",
                content: "This is my own comment that I can delete.",
                timestamp: Date(),
                likeCount: 0,
                isOwnComment: true
            ),
            isReply: false,
            onLike: {},
            onReply: {},
            onDelete: {}
        )
    }
    .padding()
}
