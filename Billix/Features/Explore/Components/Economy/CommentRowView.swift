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
    let onLike: (CommunityComment) -> Void
    let onReply: (CommunityComment) -> Void
    let onDelete: (CommunityComment) -> Void

    @State private var showDeleteConfirmation = false
    @State private var showAllReplies = false

    private let maxVisibleReplies = 2
    private let textColor = Color(hex: "#1A1A1A")
    private let secondaryColor = Color(hex: "#6B7280")
    private let accentColor = Color.billixDarkTeal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar (anonymous shows question mark icon)
            if comment.isAnonymous {
                Circle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: isReply ? 32 : 40, height: isReply ? 32 : 40)
                    .overlay(
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: isReply ? 12 : 14))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    )
            } else {
                Circle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: isReply ? 32 : 40, height: isReply ? 32 : 40)
                    .overlay(
                        Text(comment.authorName.prefix(1).uppercased())
                            .font(.system(size: isReply ? 14 : 16, weight: .semibold))
                            .foregroundColor(secondaryColor)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                // Author info
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor)

                    // Only show username if not anonymous
                    if !comment.isAnonymous && !comment.authorUsername.isEmpty {
                        Text(comment.authorUsername)
                            .font(.system(size: 13))
                            .foregroundColor(secondaryColor)

                        Text("·")
                            .foregroundColor(secondaryColor)
                    }

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
                    Button { onLike(comment) } label: {
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

                    // Reply button (available on ALL comments including replies)
                    Button { onReply(comment) } label: {
                        Text("Reply")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryColor)
                    }
                    .buttonStyle(.plain)

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

                // Nested replies (collapsed by default)
                if !comment.replies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        // Show limited or all replies
                        let visibleReplies = showAllReplies
                            ? comment.replies
                            : Array(comment.replies.prefix(maxVisibleReplies))

                        ForEach(visibleReplies) { reply in
                            CommentRowView(
                                comment: reply,
                                isReply: true,
                                onLike: onLike,
                                onReply: onReply,
                                onDelete: onDelete
                            )
                        }

                        // "View X more replies" button
                        if !showAllReplies && comment.replies.count > maxVisibleReplies {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllReplies = true
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.system(size: 12))
                                    Text("View \(comment.replies.count - maxVisibleReplies) more replies")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(accentColor)
                                .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
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
                onDelete(comment)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .onTapGesture {
            // Prevent taps from propagating
        }
    }
}

// MARK: - Preview

struct CommentRowView_Comment_Row_Previews: PreviewProvider {
    static var previews: some View {
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
        onLike: { _ in },
        onReply: { _ in },
        onDelete: { _ in }
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
        onLike: { _ in },
        onReply: { _ in },
        onDelete: { _ in }
        )
        }
        .padding()
    }
}
