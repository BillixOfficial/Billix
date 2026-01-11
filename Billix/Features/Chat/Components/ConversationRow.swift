//
//  ConversationRow.swift
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
    static let previewText = Color(hex: "#6D7A73")
    static let accent = Color(hex: "#2D6B4D")
    static let info = Color(hex: "#3B8BC4")
    static let unreadBadge = Color(hex: "#DC4B3E")
}

struct ConversationRow: View {
    let conversation: ConversationWithDetails

    var body: some View {
        HStack(spacing: 14) {
            // Avatar (using placeholder since avatarUrl was removed)
            AvatarView(url: nil, size: 54)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(conversation.otherParticipant.displayLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ChatTheme.primaryText)
                        .lineLimit(1)

                    Spacer()

                    // Timestamp
                    if let lastMessageAt = conversation.conversation.lastMessageAt {
                        Text(formatTimestamp(lastMessageAt))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ChatTheme.secondaryText)
                    }
                }

                HStack(spacing: 6) {
                    // Handle
                    if !conversation.otherParticipant.formattedHandle.isEmpty {
                        Text(conversation.otherParticipant.formattedHandle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ChatTheme.info)
                    }

                    // Preview
                    if let preview = conversation.conversation.lastMessagePreview {
                        if !conversation.otherParticipant.formattedHandle.isEmpty {
                            Text("·")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ChatTheme.secondaryText)
                        }
                        Text(preview)
                            .font(.system(size: 15))
                            .foregroundColor(ChatTheme.previewText)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Unread badge
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(ChatTheme.unreadBadge)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(ChatTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
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
            AvatarView(url: nil, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ChatTheme.primaryText)

                if !user.formattedHandle.isEmpty {
                    Text(user.formattedHandle)
                        .font(.system(size: 14))
                        .foregroundColor(ChatTheme.info)
                }
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
                    userId: UUID(),
                    handle: "savingsking",
                    displayName: "John Smith"
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
                    userId: UUID(),
                    handle: "billhelper",
                    displayName: "Jane Doe"
                ),
                unreadCount: 0
            ))
        }
        .padding()
        .background(ChatTheme.background)
    }
}
#endif
