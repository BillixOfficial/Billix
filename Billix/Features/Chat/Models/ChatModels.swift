//
//  ChatModels.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation

// MARK: - Conversation

struct Conversation: Codable, Identifiable, Equatable {
    let id: UUID
    let participant1Id: UUID
    let participant2Id: UUID
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessagePreview: String?
    let isMutedBy1: Bool
    let isMutedBy2: Bool
    let isBlockedBy1: Bool
    let isBlockedBy2: Bool

    // Joined profile data for the other participant
    var otherParticipant: ChatParticipant?

    enum CodingKeys: String, CodingKey {
        case id
        case participant1Id = "participant_1_id"
        case participant2Id = "participant_2_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
        case isMutedBy1 = "is_muted_by_1"
        case isMutedBy2 = "is_muted_by_2"
        case isBlockedBy1 = "is_blocked_by_1"
        case isBlockedBy2 = "is_blocked_by_2"
    }

    /// Check if current user is participant 1
    func isCurrentUserParticipant1(currentUserId: UUID) -> Bool {
        return participant1Id == currentUserId
    }

    /// Get the other participant's ID
    func getOtherParticipantId(currentUserId: UUID) -> UUID {
        return participant1Id == currentUserId ? participant2Id : participant1Id
    }

    /// Check if conversation is muted for current user
    func isMuted(currentUserId: UUID) -> Bool {
        if participant1Id == currentUserId {
            return isMutedBy1
        } else {
            return isMutedBy2
        }
    }

    /// Check if current user is blocked by the other participant
    func isBlockedByOther(currentUserId: UUID) -> Bool {
        if participant1Id == currentUserId {
            return isBlockedBy2
        } else {
            return isBlockedBy1
        }
    }

    /// Check if current user has blocked the other participant
    func hasBlockedOther(currentUserId: UUID) -> Bool {
        if participant1Id == currentUserId {
            return isBlockedBy1
        } else {
            return isBlockedBy2
        }
    }
}

// MARK: - Chat Participant

struct ChatParticipant: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let handle: String
    let displayName: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case handle
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }

    var formattedHandle: String {
        return "@\(handle)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let messageType: MessageType
    let content: String?
    let imageUrl: String?
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case imageUrl = "image_url"
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    /// Check if message was sent by current user
    func isSentByCurrentUser(currentUserId: UUID) -> Bool {
        return senderId == currentUserId
    }
}

// MARK: - Message Type

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case system = "system"
}

// MARK: - Message Status

enum MessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
}

// MARK: - Conversation with Details

struct ConversationWithDetails: Identifiable, Equatable, Hashable {
    let conversation: Conversation
    let otherParticipant: ChatParticipant
    let unreadCount: Int

    var id: UUID { conversation.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(conversation.id)
    }
}

// MARK: - New Message Request

struct NewMessageRequest: Encodable {
    let conversationId: UUID
    let senderId: UUID
    let messageType: String
    let content: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case imageUrl = "image_url"
    }
}

// MARK: - New Conversation Request

struct NewConversationRequest: Encodable {
    let participant1Id: UUID
    let participant2Id: UUID

    enum CodingKeys: String, CodingKey {
        case participant1Id = "participant_1_id"
        case participant2Id = "participant_2_id"
    }
}

// MARK: - Typing Indicator

struct ChatTypingIndicator: Codable {
    let userId: UUID
    let isTyping: Bool
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isTyping = "is_typing"
        case timestamp
    }
}

// MARK: - Block Check Result

struct BlockCheckResult {
    let canBlock: Bool
    let reason: String?
}
