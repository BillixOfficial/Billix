//
//  CommunityPostCard.swift
//  Billix
//
//  Created by Claude Code on 1/24/26.
//  Community post card component for Economy Feed tab
//  Inspired by Reddit, Glassdoor, and modern fintech social feeds
//

import SwiftUI

// Reaction types for posts
enum PostReaction: String, CaseIterable {
    case heart = "heart.fill"
    case thumbsUp = "hand.thumbsup.fill"
    case lightbulb = "lightbulb.fill"
    case fire = "flame.fill"
    case clap = "hands.clap.fill"

    var color: Color {
        switch self {
        case .heart: return Color(hex: "#EF4444")
        case .thumbsUp: return Color.billixDarkTeal
        case .lightbulb: return Color.billixGoldenAmber
        case .fire: return Color(hex: "#F97316")
        case .clap: return Color.billixMoneyGreen
        }
    }

    var label: String {
        switch self {
        case .heart: return "Love"
        case .thumbsUp: return "Like"
        case .lightbulb: return "Insightful"
        case .fire: return "Fire"
        case .clap: return "Applause"
        }
    }
}

struct CommunityPostCard: View {
    let post: CommunityPost
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onShareTapped: () -> Void
    var onReactionSelected: ((PostReaction) -> Void)?

    @State private var isExpanded = false
    @State private var showReactions = false
    @State private var isPressed = false
    @State private var selectedReaction: PostReaction? = nil

    // Design colors
    private let cardBackground = Color.white
    private let headlineBlack = Color(hex: "#1A1A1A")
    private let metadataGrey = Color(hex: "#6B7280")
    private let dividerGrey = Color(hex: "#F3F4F6")
    private let subtleBackground = Color(hex: "#F9FAFB")
    private let commentBackground = Color(hex: "#FAFAFA")

    // Character limit for collapsed state
    private let collapsedCharLimit = 200

    private var shouldTruncate: Bool {
        post.content.count > collapsedCharLimit
    }

    private var displayContent: String {
        if shouldTruncate && !isExpanded {
            return String(post.content.prefix(collapsedCharLimit)) + "..."
        }
        return post.content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Post Card
            VStack(alignment: .leading, spacing: 0) {
                // Author Row
                authorSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Topic Tag (if applicable)
                if let topic = post.topic {
                    topicTag(topic)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                // Content
                contentSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                // Engagement Stats Bar
                engagementStatsBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // Divider
                Rectangle()
                    .fill(dividerGrey)
                    .frame(height: 1)

                // Action Buttons Row
                actionButtonsRow
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .background(cardBackground)

            // Top Comment Preview (if exists)
            if let comment = post.topComment {
                topCommentView(comment)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Top Comment View

    private func topCommentView(_ comment: CommunityComment) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gray bubble container for comment
            VStack(alignment: .leading, spacing: 8) {
                // Comment author row
                HStack(spacing: 8) {
                    // Small avatar
                    Circle()
                        .fill(Color.billixDarkTeal.opacity(0.15))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(comment.authorName.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.billixDarkTeal)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(comment.authorName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(headlineBlack)

                        Text(comment.authorUsername)
                            .font(.system(size: 12))
                            .foregroundColor(metadataGrey)
                    }

                    Spacer()

                    Text(comment.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(metadataGrey)
                }

                // Comment content
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(headlineBlack.opacity(0.9))
                    .lineSpacing(4)
                    .lineLimit(3)

                // Comment engagement
                HStack(spacing: 16) {
                    Button {
                        // Like comment
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(comment.likeCount)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(metadataGrey)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onCommentTapped()
                    } label: {
                        Text("Reply")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.billixDarkTeal)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(14)
            .background(Color(hex: "#F2F4F7"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(cardBackground)
    }

    // MARK: - Author Section

    private var authorSection: some View {
        HStack(spacing: 12) {
            // Avatar with tier ring
            ZStack {
                Circle()
                    .stroke(tierGradient, lineWidth: 2.5)
                    .frame(width: 46, height: 46)

                avatarImage
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }

            // Author Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(post.authorName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(headlineBlack)

                    // Verified badge for Budget Pro
                    if post.authorRole == "Budget Pro" {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.billixDarkTeal)
                    }
                }

                HStack(spacing: 6) {
                    // Tier Badge
                    tierBadge

                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(metadataGrey)

                    Text(post.timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(metadataGrey)
                }
            }

            Spacer()

            // More Menu
            Menu {
                Button(action: {}) {
                    Label("Save Post", systemImage: "bookmark")
                }
                Button(action: {}) {
                    Label("Follow \(post.authorName.components(separatedBy: " ").first ?? "")", systemImage: "person.badge.plus")
                }
                Divider()
                Button(role: .destructive, action: {}) {
                    Label("Report", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(metadataGrey)
                    .frame(width: 36, height: 36)
                    .background(subtleBackground)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Topic Tag

    private func topicTag(_ topic: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: topicIcon(for: topic))
                .font(.system(size: 10, weight: .semibold))

            Text(topic)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(topicColor(for: topic))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(topicColor(for: topic).opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayContent)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(headlineBlack)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)

            if shouldTruncate {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "read more")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.billixDarkTeal)
                }
            }
        }
    }

    // MARK: - Engagement Stats Bar

    private var engagementStatsBar: some View {
        HStack(spacing: 0) {
            // Reaction indicators
            if post.likeCount > 0 {
                HStack(spacing: -4) {
                    reactionBubble(icon: "heart.fill", color: Color(hex: "#EF4444"))
                    if post.likeCount > 5 {
                        reactionBubble(icon: "hand.thumbsup.fill", color: Color.billixDarkTeal)
                    }
                    if post.likeCount > 20 {
                        reactionBubble(icon: "lightbulb.fill", color: Color.billixGoldenAmber)
                    }
                }

                Text("\(post.likeCount)")
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)
                    .padding(.leading, 6)
            }

            Spacer()

            // Comments count
            if post.commentCount > 0 {
                Text("\(post.commentCount) Comments")
                    .font(.system(size: 13))
                    .foregroundColor(metadataGrey)
            }
        }
    }

    private func reactionBubble(icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)

            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 0) {
                // Like Button with long-press for reactions
                likeButtonWithReactions

                // Comment Button
                actionButton(
                    icon: "bubble.left",
                    label: "Comment",
                    color: metadataGrey,
                    action: onCommentTapped
                )

                // Share Button
                actionButton(
                    icon: "arrow.turn.up.right",
                    label: "Share",
                    color: metadataGrey,
                    action: onShareTapped
                )
            }

            // Reaction Picker Overlay
            if showReactions {
                reactionPicker
                    .offset(x: 8, y: -50)
                    .transition(.scale(scale: 0.5, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showReactions)
    }

    // MARK: - Like Button with Reactions

    private var likeButtonWithReactions: some View {
        let currentIcon = selectedReaction?.rawValue ?? (post.isLiked ? "heart.fill" : "heart")
        let currentColor = selectedReaction?.color ?? (post.isLiked ? Color(hex: "#EF4444") : metadataGrey)
        let currentLabel = selectedReaction?.label ?? "Like"

        return HStack(spacing: 6) {
            Image(systemName: currentIcon)
                .font(.system(size: 16, weight: .medium))

            Text(currentLabel)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(currentColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if showReactions {
                withAnimation {
                    showReactions = false
                }
            } else {
                onLikeTapped()
            }
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            withAnimation {
                showReactions = true
            }
        }
    }

    // MARK: - Reaction Picker

    private var reactionPicker: some View {
        HStack(spacing: 4) {
            ForEach(PostReaction.allCases, id: \.self) { reaction in
                Button {
                    selectReaction(reaction)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: reaction.rawValue)
                            .font(.system(size: 22))
                            .foregroundColor(reaction.color)
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(selectedReaction == reaction ? 1.2 : 1.0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }

    private func selectReaction(_ reaction: PostReaction) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedReaction == reaction {
                selectedReaction = nil
            } else {
                selectedReaction = reaction
            }
            showReactions = false
        }
        onReactionSelected?(reaction)
        if !post.isLiked {
            onLikeTapped()
        }
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar View

    private var avatarImage: some View {
        Group {
            if let avatarURL = post.authorAvatar, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(roleColor.opacity(0.15))
            .overlay(
                Text(String(post.authorName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(roleColor)
            )
    }

    // MARK: - Username Badge

    private var tierBadge: some View {
        Text(post.authorUsername)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(metadataGrey)
    }

    private var tierIcon: String {
        switch post.authorRole {
        case "Budget Pro":
            return "star.fill"
        case "Saver":
            return "leaf.fill"
        default:
            return "person.fill"
        }
    }

    private var tierGradient: LinearGradient {
        switch post.authorRole {
        case "Budget Pro":
            return LinearGradient(
                colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Saver":
            return LinearGradient(
                colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "#9CA3AF"), Color(hex: "#D1D5DB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var roleColor: Color {
        switch post.authorRole {
        case "Budget Pro":
            return Color.billixDarkTeal
        case "Saver":
            return Color.billixMoneyGreen
        default:
            return Color(hex: "#6B7280")
        }
    }

    // MARK: - Topic Helpers

    private func topicIcon(for topic: String) -> String {
        switch topic.lowercased() {
        case "savings":
            return "banknote"
        case "tips":
            return "lightbulb"
        case "bills":
            return "doc.text"
        case "question":
            return "questionmark.circle"
        case "milestone":
            return "flag.fill"
        default:
            return "tag"
        }
    }

    private func topicColor(for topic: String) -> Color {
        switch topic.lowercased() {
        case "savings":
            return Color.billixMoneyGreen
        case "tips":
            return Color.billixGoldenAmber
        case "bills":
            return Color.billixDarkTeal
        case "question":
            return Color.billixPurple
        case "milestone":
            return Color(hex: "#F59E0B")
        default:
            return Color(hex: "#6B7280")
        }
    }
}

// MARK: - Preview

#Preview("Community Post Card") {
    ZStack {
        Color(hex: "#F5F5F5")
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                ForEach(CommunityPost.mockPosts.prefix(3)) { post in
                    CommunityPostCard(
                        post: post,
                        onLikeTapped: {},
                        onCommentTapped: {},
                        onShareTapped: {}
                    )
                }
            }
            .padding(16)
        }
    }
}
