//
//  BillInteractionBar.swift
//  Billix
//
//  Icon-based interaction bar for bill listings (no emojis)
//

import SwiftUI

struct BillInteractionBar: View {
    let voteScore: Int
    let tipCount: Int
    let userVote: VoteType?
    let isBookmarked: Bool

    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onBookmark: () -> Void
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Vote section
            HStack(spacing: 4) {
                // Upvote button
                Button(action: onUpvote) {
                    Image(systemName: userVote == .up ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(userVote == .up ? Color(hex: "#4CAF7A") : Color(hex: "#8B9A94"))
                }
                .buttonStyle(PlainButtonStyle())

                // Score
                Text("\(voteScore)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(voteScoreColor)
                    .frame(minWidth: 24)

                // Downvote button
                Button(action: onDownvote) {
                    Image(systemName: userVote == .down ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(userVote == .down ? Color(hex: "#E07A6B") : Color(hex: "#8B9A94"))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            // Bookmark button
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isBookmarked ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Message/Tips button
            Button(action: onMessage) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 16, weight: .medium))

                    if tipCount > 0 {
                        Text("\(tipCount)")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundColor(Color(hex: "#8B9A94"))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#F7F9F8"))
        .cornerRadius(10)
    }

    private var voteScoreColor: Color {
        if voteScore > 0 {
            return Color(hex: "#4CAF7A")
        } else if voteScore < 0 {
            return Color(hex: "#E07A6B")
        } else {
            return Color(hex: "#8B9A94")
        }
    }
}

// MARK: - Compact Version (for card footer)

struct CompactInteractionBar: View {
    let voteScore: Int
    let tipCount: Int
    let userVote: VoteType?
    let isBookmarked: Bool

    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onBookmark: () -> Void
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Vote section
            HStack(spacing: 6) {
                Button(action: onUpvote) {
                    Image(systemName: userVote == .up ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 16))
                        .foregroundColor(userVote == .up ? Color(hex: "#4CAF7A") : Color(hex: "#8B9A94"))
                }
                .buttonStyle(BillExplorerScaleButtonStyle())

                Text("\(voteScore)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(voteScoreColor)

                Button(action: onDownvote) {
                    Image(systemName: userVote == .down ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 16))
                        .foregroundColor(userVote == .down ? Color(hex: "#E07A6B") : Color(hex: "#8B9A94"))
                }
                .buttonStyle(BillExplorerScaleButtonStyle())
            }

            Spacer()

            // Bookmark
            Button(action: onBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14))
                    .foregroundColor(isBookmarked ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
            }
            .buttonStyle(BillExplorerScaleButtonStyle())
        }
    }

    private var voteScoreColor: Color {
        if voteScore > 0 {
            return Color(hex: "#4CAF7A")
        } else if voteScore < 0 {
            return Color(hex: "#E07A6B")
        } else {
            return Color(hex: "#8B9A94")
        }
    }
}

// MARK: - Bill Explorer Scale Button Style

private struct BillExplorerScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Full bar
        BillInteractionBar(
            voteScore: 24,
            tipCount: 12,
            userVote: .up,
            isBookmarked: true,
            onUpvote: {},
            onDownvote: {},
            onBookmark: {},
            onMessage: {}
        )
        .padding(.horizontal)

        // Neutral state
        BillInteractionBar(
            voteScore: 0,
            tipCount: 3,
            userVote: nil,
            isBookmarked: false,
            onUpvote: {},
            onDownvote: {},
            onBookmark: {},
            onMessage: {}
        )
        .padding(.horizontal)

        // Negative score
        BillInteractionBar(
            voteScore: -5,
            tipCount: 1,
            userVote: .down,
            isBookmarked: false,
            onUpvote: {},
            onDownvote: {},
            onBookmark: {},
            onMessage: {}
        )
        .padding(.horizontal)

        Divider()

        // Compact version
        CompactInteractionBar(
            voteScore: 18,
            tipCount: 7,
            userVote: nil,
            isBookmarked: false,
            onUpvote: {},
            onDownvote: {},
            onBookmark: {},
            onMessage: {}
        )
        .padding(.horizontal)
    }
    .padding(.vertical)
    .background(Color.white)
}
