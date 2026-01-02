//
//  SwapChatMessage.swift
//  Billix
//
//  Bill Swap In-Swap Chat Message Model
//

import Foundation

// MARK: - Swap Chat Constants

enum SwapChatConstants {
    static let maxMessageLength = 300
    static let rateLimitSeconds: TimeInterval = 1.0
    static let maxMessagesPerMinute = 10
}

// MARK: - Swap Chat Message

struct SwapChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let swapId: UUID
    let senderUserId: UUID
    let message: String
    let isSystemMessage: Bool
    let createdAt: Date

    // Transient (not from DB)
    var senderDisplayName: String?
    var senderHandle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case senderUserId = "sender_user_id"
        case message
        case isSystemMessage = "is_system_message"
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Is this message from the current user?
    func isSentByCurrentUser(_ currentUserId: UUID) -> Bool {
        senderUserId == currentUserId
    }

    /// Formatted timestamp
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Formatted date for grouping
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: createdAt)
        }
    }

    // MARK: - Alias Properties (for view compatibility)

    /// Alias for message (used by views)
    var messageText: String { message }

    /// Alias for isSystemMessage (used by views)
    var isSystem: Bool { isSystemMessage }

    /// Whether this message has been flagged for review
    var isFlagged: Bool { false }
}

// MARK: - Message Group (for date grouping)

struct SwapChatMessageGroup: Identifiable {
    let id = UUID()
    let date: Date
    let messages: [SwapChatMessage]
}

// MARK: - Send Message Request

struct SendSwapMessageRequest: Codable {
    let swapId: UUID
    let message: String

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case message
    }

    // MARK: - Validation

    /// Maximum message length
    static let maxLength = 300

    /// Check if message is valid
    var isValid: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        message.count <= Self.maxLength &&
        !containsExternalLink
    }

    /// Check for external links
    var containsExternalLink: Bool {
        let pattern = "https?://[^\\s]+"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(message.startIndex..., in: message)
        return regex?.firstMatch(in: message, options: [], range: range) != nil
    }
}

// MARK: - System Message Templates

enum SwapSystemMessage {
    static func swapAccepted(byUserName: String) -> String {
        "\(byUserName) accepted the swap"
    }

    static func feePaid(byUserName: String) -> String {
        "\(byUserName) paid the swap fee"
    }

    static func feeWaived(byUserName: String) -> String {
        "\(byUserName) waived the fee with points"
    }

    static func proofUploaded(byUserName: String) -> String {
        "\(byUserName) uploaded payment proof"
    }

    static func proofAccepted(byUserName: String) -> String {
        "\(byUserName) accepted the payment proof"
    }

    static func proofRejected(byUserName: String, reason: String) -> String {
        "\(byUserName) rejected the proof: \(reason)"
    }

    static func swapCompleted() -> String {
        "Swap completed successfully! Both parties earned 100 points."
    }

    static func disputeFiled(byUserName: String) -> String {
        "\(byUserName) filed a dispute"
    }
}
