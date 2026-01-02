//
//  SwapChatService.swift
//  Billix
//
//  Bill Swap Chat Service - Realtime messaging for swaps
//

import Foundation
import Supabase
import Realtime
import Combine

// MARK: - Realtime Swap Message Payload

private struct RealtimeSwapChatPayload: Codable {
    let id: String
    let swapId: String
    let senderUserId: String
    let message: String
    let isSystemMessage: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case swapId = "swap_id"
        case senderUserId = "sender_user_id"
        case message
        case isSystemMessage = "is_system_message"
        case createdAt = "created_at"
    }

    func toSwapChatMessage() -> SwapChatMessage? {
        guard let id = UUID(uuidString: id),
              let swapId = UUID(uuidString: swapId),
              let senderId = UUID(uuidString: senderUserId) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAt) ?? Date()

        return SwapChatMessage(
            id: id,
            swapId: swapId,
            senderUserId: senderId,
            message: message,
            isSystemMessage: isSystemMessage,
            createdAt: date
        )
    }
}

// MARK: - Swap Chat Error

enum SwapChatError: LocalizedError {
    case notAuthenticated
    case chatNotEnabled
    case messageTooLong
    case invalidContent
    case sendFailed
    case subscriptionFailed
    case swapNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to use chat"
        case .chatNotEnabled:
            return "Chat is only available after the swap is accepted"
        case .messageTooLong:
            return "Message cannot exceed 300 characters"
        case .invalidContent:
            return "Message contains invalid content (links not allowed)"
        case .sendFailed:
            return "Failed to send message. Please try again."
        case .subscriptionFailed:
            return "Failed to connect to chat. Please try again."
        case .swapNotFound:
            return "Swap not found"
        }
    }
}

// MARK: - Private Codable Payloads

private struct SendChatMessagePayload: Codable {
    let swapId: String
    let senderUserId: String
    let message: String
    let isSystemMessage: Bool

    enum CodingKeys: String, CodingKey {
        case swapId = "swap_id"
        case senderUserId = "sender_user_id"
        case message
        case isSystemMessage = "is_system_message"
    }
}

private struct FlagMessagePayload: Codable {
    let isFlagged: Bool

    enum CodingKeys: String, CodingKey {
        case isFlagged = "is_flagged"
    }
}

// MARK: - Swap Chat Service

@MainActor
class SwapChatService: ObservableObject {
    static let shared = SwapChatService()

    // MARK: - Published Properties
    @Published var messages: [SwapChatMessage] = []
    @Published var isLoading = false
    @Published var error: SwapChatError?
    @Published var isConnected = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentSwapId: UUID?
    private var realtimeChannel: RealtimeChannelV2?

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    private init() {}

    deinit {
        Task { @MainActor in
            await disconnect()
        }
    }

    // MARK: - Chat Eligibility Check

    /// Check if chat is enabled for a swap (must be accepted or later)
    func isChatEnabled(for swap: BillSwap) -> Bool {
        let chatEnabledStatuses: [BillSwapStatus] = [
            .acceptedPendingFee,
            .locked,
            .awaitingProof,
            .completed,
            .failed,
            .disputed
        ]
        return chatEnabledStatuses.contains(swap.status)
    }

    // MARK: - Connect to Swap Chat

    /// Connect to the realtime channel for a swap's chat
    func connect(to swapId: UUID) async throws {
        guard currentUserId != nil else {
            throw SwapChatError.notAuthenticated
        }

        // Verify swap exists and user is a participant
        let swap = try await fetchSwap(swapId)
        guard isChatEnabled(for: swap) else {
            throw SwapChatError.chatNotEnabled
        }

        // Disconnect from any existing channel
        await disconnect()

        currentSwapId = swapId
        isLoading = true
        error = nil

        do {
            // Load existing messages
            try await loadMessages(for: swapId)

            // Subscribe to realtime updates
            try await subscribeToMessages(for: swapId)

            isConnected = true
        } catch {
            self.error = .subscriptionFailed
            throw SwapChatError.subscriptionFailed
        }

        isLoading = false
    }

    /// Disconnect from the current chat
    func disconnect() async {
        if let channel = realtimeChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        realtimeChannel = nil
        currentSwapId = nil
        messages = []
        isConnected = false
    }

    // MARK: - Fetch Swap

    private func fetchSwap(_ swapId: UUID) async throws -> BillSwap {
        let swap: BillSwap = try await supabase
            .from("bill_swaps")
            .select()
            .eq("id", value: swapId.uuidString)
            .single()
            .execute()
            .value

        return swap
    }

    // MARK: - Load Messages

    private func loadMessages(for swapId: UUID) async throws {
        let loadedMessages: [SwapChatMessage] = try await supabase
            .from("swap_chat_messages")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        messages = loadedMessages
    }

    // MARK: - Subscribe to Realtime

    private func subscribeToMessages(for swapId: UUID) async throws {
        let channelName = "swap-chat:\(swapId.uuidString)"

        let channel = supabase.realtimeV2.channel(channelName)

        // Subscribe to INSERT events on swap_chat_messages table
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "swap_chat_messages",
            filter: "swap_id=eq.\(swapId.uuidString)"
        )

        await channel.subscribe()

        realtimeChannel = channel

        // Handle new message insertions
        Task { [weak self] in
            for await insertion in insertions {
                await self?.handleNewMessage(insertion)
            }
        }
    }

    private func handleNewMessage(_ action: InsertAction) async {
        do {
            let payload = try action.decodeRecord(as: RealtimeSwapChatPayload.self, decoder: JSONDecoder())
            if let message = payload.toSwapChatMessage() {
                // Avoid duplicates
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        } catch {
            print("Failed to decode realtime swap message: \(error)")
        }
    }

    // MARK: - Send Message

    /// Send a text message in the swap chat
    func sendMessage(_ text: String) async throws {
        guard let swapId = currentSwapId,
              let senderId = currentUserId else {
            throw SwapChatError.notAuthenticated
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate message
        guard !trimmedText.isEmpty else { return }

        guard trimmedText.count <= SwapChatConstants.maxMessageLength else {
            throw SwapChatError.messageTooLong
        }

        guard !containsExternalLinks(trimmedText) else {
            throw SwapChatError.invalidContent
        }

        let payload = SendChatMessagePayload(
            swapId: swapId.uuidString,
            senderUserId: senderId.uuidString,
            message: trimmedText,
            isSystemMessage: false
        )

        do {
            try await supabase
                .from("swap_chat_messages")
                .insert(payload)
                .execute()
        } catch {
            throw SwapChatError.sendFailed
        }
    }

    /// Send a system message (used internally)
    func sendSystemMessage(_ text: String, swapId: UUID) async throws {
        let payload = SendChatMessagePayload(
            swapId: swapId.uuidString,
            senderUserId: currentUserId?.uuidString ?? UUID().uuidString,
            message: text,
            isSystemMessage: true
        )

        try await supabase
            .from("swap_chat_messages")
            .insert(payload)
            .execute()
    }

    // MARK: - Flag Message

    /// Flag a message for review
    func flagMessage(_ messageId: UUID) async throws {
        let payload = FlagMessagePayload(isFlagged: true)
        try await supabase
            .from("swap_chat_messages")
            .update(payload)
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    // MARK: - Get Message Count

    /// Get total message count for a swap
    func getMessageCount(for swapId: UUID) async throws -> Int {
        let messages: [SwapChatMessage] = try await supabase
            .from("swap_chat_messages")
            .select()
            .eq("swap_id", value: swapId.uuidString)
            .execute()
            .value

        return messages.count
    }

    // MARK: - Helpers

    /// Check if text contains external links
    private func containsExternalLinks(_ text: String) -> Bool {
        // Simple URL detection
        let patterns = [
            "http://",
            "https://",
            "www.",
            ".com",
            ".net",
            ".org",
            ".io"
        ]

        let lowercasedText = text.lowercased()
        return patterns.contains { lowercasedText.contains($0) }
    }

    // MARK: - Message Grouping

    /// Groups messages by date for display
    var groupedMessages: [(date: Date, messages: [SwapChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped
            .map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }
}
