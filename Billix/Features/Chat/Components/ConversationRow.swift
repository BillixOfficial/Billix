//
//  ConversationRow.swift
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
    static let unreadBadge = Color(hex: "#E07A6B")
}

struct ConversationRow: View {
    let conversation: ConversationWithDetails

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarView(
                url: conversation.otherParticipant.avatarUrl,
                size: 52
            )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherParticipant.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ChatTheme.primaryText)
                        .lineLimit(1)

                    Spacer()

                    // Timestamp
                    if let lastMessageAt = conversation.conversation.lastMessageAt {
                        Text(formatTimestamp(lastMessageAt))
                            .font(.system(size: 12))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                }

                HStack {
                    // Handle
                    Text(conversation.otherParticipant.formattedHandle)
                        .font(.system(size: 13))
                        .foregroundColor(ChatTheme.info)

                    // Preview
                    if let preview = conversation.conversation.lastMessagePreview {
                        Text("·")
                            .foregroundColor(ChatTheme.secondaryText)
                        Text(preview)
                            .font(.system(size: 14))
                            .foregroundColor(ChatTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Unread badge
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ChatTheme.unreadBadge)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(ChatTheme.cardBackground)
        .cornerRadius(12)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(ChatTheme.accent.opacity(0.2))

            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(ChatTheme.accent)
        }
    }
}

// MARK: - User Search Row

struct UserSearchRow: View {
    let user: ChatParticipant

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: user.avatarUrl, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ChatTheme.primaryText)

                Text(user.formattedHandle)
                    .font(.system(size: 14))
                    .foregroundColor(ChatTheme.info)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ChatTheme.secondaryText.opacity(0.5))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(ChatTheme.cardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Previews

#if DEBUG
struct ConversationRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ConversationRow(conversation: ConversationWithDetails(
                conversation: Conversation(
                    id: UUID(),
                    participant1Id: UUID(),
                    participant2Id: UUID(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    lastMessageAt: Date(),
                    lastMessagePreview: "Hey, thanks for helping with my bill!",
                    isMutedBy1: false,
                    isMutedBy2: false,
                    isBlockedBy1: false,
                    isBlockedBy2: false
                ),
                otherParticipant: ChatParticipant(
                    id: UUID(),
                    handle: "savingsking",
                    displayName: "John Smith",
                    avatarUrl: nil
                ),
                unreadCount: 3
            ))

            ConversationRow(conversation: ConversationWithDetails(
                conversation: Conversation(
                    id: UUID(),
                    participant1Id: UUID(),
                    participant2Id: UUID(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    lastMessageAt: Date().addingTimeInterval(-86400),
                    lastMessagePreview: "Payment received",
                    isMutedBy1: false,
                    isMutedBy2: false,
                    isBlockedBy1: false,
                    isBlockedBy2: false
                ),
                otherParticipant: ChatParticipant(
                    id: UUID(),
                    handle: "billhelper",
                    displayName: "Jane Doe",
                    avatarUrl: nil
                ),
                unreadCount: 0
            ))
        }
        .padding()
        .background(ChatTheme.background)
    }
}
#endif
