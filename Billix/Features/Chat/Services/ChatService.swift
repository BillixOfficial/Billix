//
//  ChatService.swift
//  Billix
//
//  Created by Billix Team
//  Real-time messaging service for peer-to-peer chat using Supabase Realtime
//

import Foundation
import Supabase
import Realtime
import Combine
import UIKit

// MARK: - Chat Error

enum ChatError: LocalizedError {
    case notAuthenticated
    case sendFailed
    case subscriptionFailed
    case conversationNotFound
    case userNotFound
    case userBlocked
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to use chat"
        case .sendFailed:
            return "Failed to send message. Please try again."
        case .subscriptionFailed:
            return "Failed to connect to chat. Please try again."
        case .conversationNotFound:
            return "Conversation not found"
        case .userNotFound:
            return "User not found"
        case .userBlocked:
            return "You cannot message this user"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}

// MARK: - Realtime Message Payload

private struct RealtimeChatPayload: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let messageType: String
    let content: String?
    let imageUrl: String?
    let isRead: Bool
    let createdAt: String

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

    func toChatMessage() -> ChatMessage? {
        guard let id = UUID(uuidString: id),
              let convId = UUID(uuidString: conversationId),
              let sender = UUID(uuidString: senderId),
              let type = MessageType(rawValue: messageType) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAt) ?? Date()

        return ChatMessage(
            id: id,
            conversationId: convId,
            senderId: sender,
            messageType: type,
            content: content,
            imageUrl: imageUrl,
            isRead: isRead,
            createdAt: date
        )
    }
}

// MARK: - Chat Service

@MainActor
class ChatService: ObservableObject {

    // MARK: - Singleton
    static let shared = ChatService()

    // MARK: - Published Properties
    @Published var conversations: [ConversationWithDetails] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: ChatError?
    @Published var typingUsers: Set<UUID> = []
    @Published var isConnected = false
    @Published var totalUnreadCount = 0

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentConversationId: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    private var typingTimer: Timer?
    private var realtimeTasks: [Task<Void, Never>] = []

    // MARK: - Constants
    private let maxMessagesInMemory = 100

    // MARK: - Current User
    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    // MARK: - Initialization
    private init() {}

    deinit {
        // Cancel all realtime tasks immediately (sync)
        for task in realtimeTasks {
            task.cancel()
        }
        // Cleanup channel asynchronously
        Task { @MainActor in
            await disconnect()
        }
    }

    // MARK: - Search Users by Handle

    /// Search for users by their handle
    func searchUsers(query: String) async throws -> [ChatParticipant] {
        guard currentUserId != nil else {
            throw ChatError.notAuthenticated
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "@", with: "")
        guard !trimmedQuery.isEmpty else { return [] }

        let results: [ChatParticipant] = try await supabase
            .from("profiles")
            .select("user_id, handle, display_name")
            .ilike("handle", pattern: "%\(trimmedQuery)%")
            .neq("user_id", value: currentUserId!.uuidString)
            .limit(20)
            .execute()
            .value

        // Filter out users without handles
        return results.filter { $0.handle != nil }
    }

    /// Find a user by exact handle
    func findUserByHandle(_ handle: String) async throws -> ChatParticipant? {
        let normalizedHandle = handle.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "@", with: "")

        let results: [ChatParticipant] = try await supabase
            .from("profiles")
            .select("user_id, handle, display_name")
            .eq("handle", value: normalizedHandle)
            .limit(1)
            .execute()
            .value

        return results.first
    }

    // MARK: - Conversations

    /// Fetch all conversations for the current user
    func fetchConversations() async throws {
        guard let userId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // Get all conversations where user is a participant
        let convos: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .or("participant_1_id.eq.\(userId.uuidString),participant_2_id.eq.\(userId.uuidString)")
            .order("last_message_at", ascending: false)
            .execute()
            .value

        // Fetch participant details and unread counts for each conversation
        var conversationsWithDetails: [ConversationWithDetails] = []

        for convo in convos {
            let otherParticipantId = convo.getOtherParticipantId(currentUserId: userId)

            // Get profile of the other participant
            if let participant = try? await fetchParticipant(id: otherParticipantId) {
                // Get unread count
                let unread = try await getUnreadCount(for: convo.id)

                conversationsWithDetails.append(ConversationWithDetails(
                    conversation: convo,
                    otherParticipant: participant,
                    unreadCount: unread
                ))
            }
        }

        conversations = conversationsWithDetails
        updateTotalUnreadCount()
    }

    /// Get or create a conversation with a user
    func getOrCreateConversation(with otherUserId: UUID) async throws -> Conversation {
        guard let userId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        guard userId != otherUserId else {
            throw ChatError.userNotFound
        }

        // Check if conversation already exists (in either direction)
        let existing: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .or("and(participant_1_id.eq.\(userId.uuidString),participant_2_id.eq.\(otherUserId.uuidString)),and(participant_1_id.eq.\(otherUserId.uuidString),participant_2_id.eq.\(userId.uuidString))")
            .limit(1)
            .execute()
            .value

        if let conversation = existing.first {
            return conversation
        }

        // Create new conversation
        let newConvo = NewConversationRequest(
            participant1Id: userId,
            participant2Id: otherUserId
        )

        let created: Conversation = try await supabase
            .from("conversations")
            .insert(newConvo)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Fetch participant profile
    private func fetchParticipant(id: UUID) async throws -> ChatParticipant {
        let results: [ChatParticipant] = try await supabase
            .from("profiles")
            .select("user_id, handle, display_name")
            .eq("user_id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        guard let participant = results.first else {
            throw ChatError.userNotFound
        }

        return participant
    }

    // MARK: - Connect to Conversation

    /// Connects to the realtime channel for a conversation
    func connect(to conversationId: UUID) async throws {
        guard currentUserId != nil else {
            throw ChatError.notAuthenticated
        }

        // Disconnect from any existing channel
        await disconnect()

        currentConversationId = conversationId
        isLoading = true
        error = nil

        do {
            // Load existing messages
            try await loadMessages(for: conversationId)

            // Mark messages as read
            try await markAsRead(conversationId: conversationId)

            // Subscribe to realtime updates
            try await subscribeToMessages(for: conversationId)

            isConnected = true
        } catch {
            self.error = .subscriptionFailed
            throw ChatError.subscriptionFailed
        }

        isLoading = false
    }

    /// Disconnects from the current channel
    func disconnect() async {
        // Cancel all realtime listener tasks
        for task in realtimeTasks {
            task.cancel()
        }
        realtimeTasks.removeAll()

        if let channel = realtimeChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        realtimeChannel = nil
        currentConversationId = nil
        messages = []
        typingUsers = []
        isConnected = false
        typingTimer?.invalidate()
        typingTimer = nil
    }

    // MARK: - Load Messages

    /// Loads existing messages for a conversation (limited to most recent)
    private func loadMessages(for conversationId: UUID) async throws {
        let loadedMessages: [ChatMessage] = try await supabase
            .from("chat_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: false)  // Get most recent first
            .limit(maxMessagesInMemory)             // Limit to prevent memory issues
            .execute()
            .value

        // Reverse to get chronological order (oldest first)
        messages = loadedMessages.reversed()
    }

    // MARK: - Subscribe to Realtime

    /// Subscribes to realtime message updates
    private func subscribeToMessages(for conversationId: UUID) async throws {
        let channelName = "chat-messages:\(conversationId.uuidString)"

        let channel = supabase.realtimeV2.channel(channelName)

        // Subscribe to INSERT events on chat_messages table
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages",
            filter: "conversation_id=eq.\(conversationId.uuidString)"
        )

        // Subscribe to UPDATE events (for read receipts)
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "chat_messages",
            filter: "conversation_id=eq.\(conversationId.uuidString)"
        )

        await channel.subscribe()

        realtimeChannel = channel

        // Cancel any existing tasks before creating new ones
        for task in realtimeTasks {
            task.cancel()
        }
        realtimeTasks.removeAll()

        // Handle new message insertions - store task for cleanup
        let insertionTask = Task { [weak self] in
            for await insertion in insertions {
                guard !Task.isCancelled else { return }
                await self?.handleNewMessage(insertion)
            }
        }
        realtimeTasks.append(insertionTask)

        // Handle message updates (read receipts) - store task for cleanup
        let updateTask = Task { [weak self] in
            for await update in updates {
                guard !Task.isCancelled else { return }
                await self?.handleMessageUpdate(update)
            }
        }
        realtimeTasks.append(updateTask)
    }

    /// Handles a new message from realtime
    private func handleNewMessage(_ action: InsertAction) async {
        do {
            let payload = try action.decodeRecord(as: RealtimeChatPayload.self, decoder: JSONDecoder())
            if let message = payload.toChatMessage() {
                // Avoid duplicates
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)

                    // Cap messages to prevent unbounded memory growth
                    if messages.count > maxMessagesInMemory {
                        messages.removeFirst(messages.count - maxMessagesInMemory)
                    }

                    // If this is from the other user, mark as read
                    if message.senderId != currentUserId, let convId = currentConversationId {
                        try? await markAsRead(conversationId: convId)
                    }
                }
            }
        } catch {
            print("Failed to decode realtime message: \(error)")
        }
    }

    /// Handles a message update from realtime
    private func handleMessageUpdate(_ action: UpdateAction) async {
        do {
            let payload = try action.decodeRecord(as: RealtimeChatPayload.self, decoder: JSONDecoder())
            if let updatedMessage = payload.toChatMessage() {
                // Update the message in our local array
                if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    messages[index] = updatedMessage
                }
            }
        } catch {
            print("Failed to decode realtime update: \(error)")
        }
    }

    // MARK: - Send Messages

    /// Sends a text message
    func sendTextMessage(_ text: String) async throws {
        guard let conversationId = currentConversationId,
              let senderId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let messageData = NewMessageRequest(
            conversationId: conversationId,
            senderId: senderId,
            messageType: MessageType.text.rawValue,
            content: trimmedText,
            imageUrl: nil
        )

        do {
            try await supabase
                .from("chat_messages")
                .insert(messageData)
                .execute()
        } catch {
            throw ChatError.sendFailed
        }
    }

    /// Sends an image message
    func sendImageMessage(imageData: Data) async throws {
        guard let conversationId = currentConversationId,
              let senderId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        // Compress image if needed
        let compressedData = compressImage(data: imageData, maxSizeKB: 1024)

        // Upload to storage
        let fileName = "\(conversationId.uuidString)/\(UUID().uuidString).jpg"
        let storagePath = "chat-images/\(fileName)"

        do {
            try await supabase.storage
                .from("chat-images")
                .upload(storagePath, data: compressedData, options: .init(contentType: "image/jpeg"))

            // Get public URL
            let publicUrl = try supabase.storage
                .from("chat-images")
                .getPublicURL(path: storagePath)

            // Send message with image URL
            let messageData = NewMessageRequest(
                conversationId: conversationId,
                senderId: senderId,
                messageType: MessageType.image.rawValue,
                content: nil,
                imageUrl: publicUrl.absoluteString
            )

            try await supabase
                .from("chat_messages")
                .insert(messageData)
                .execute()
        } catch {
            throw ChatError.uploadFailed
        }
    }

    /// Compress image data
    private func compressImage(data: Data, maxSizeKB: Int) -> Data {
        // If already small enough, return as-is
        if data.count <= maxSizeKB * 1024 {
            return data
        }

        // Try to compress with UIImage
        guard let image = UIImage(data: data) else {
            return data
        }

        var quality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: quality) ?? data

        while compressedData.count > maxSizeKB * 1024 && quality > 0.1 {
            quality -= 0.1
            compressedData = image.jpegData(compressionQuality: quality) ?? compressedData
        }

        return compressedData
    }

    // MARK: - Read Receipts

    /// Mark all messages in a conversation as read
    func markAsRead(conversationId: UUID) async throws {
        guard let userId = currentUserId else { return }

        try await supabase
            .from("chat_messages")
            .update(["is_read": true])
            .eq("conversation_id", value: conversationId.uuidString)
            .neq("sender_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()

        // Update local unread count
        await refreshUnreadCount()
    }

    /// Get unread count for a specific conversation
    func getUnreadCount(for conversationId: UUID) async throws -> Int {
        guard let userId = currentUserId else { return 0 }

        struct CountResult: Decodable {
            let count: Int
        }

        let result: [ChatMessage] = try await supabase
            .from("chat_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .neq("sender_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
            .value

        return result.count
    }

    /// Refresh total unread count
    func refreshUnreadCount() async {
        guard let userId = currentUserId else {
            totalUnreadCount = 0
            return
        }

        // Get all conversations
        let convos: [Conversation] = (try? await supabase
            .from("conversations")
            .select()
            .or("participant_1_id.eq.\(userId.uuidString),participant_2_id.eq.\(userId.uuidString)")
            .execute()
            .value) ?? []

        var total = 0
        for convo in convos {
            let count = (try? await getUnreadCount(for: convo.id)) ?? 0
            total += count
        }

        totalUnreadCount = total
    }

    private func updateTotalUnreadCount() {
        totalUnreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Blocking

    /// Check if the current user can block another user
    func canBlockUser(_ otherUserId: UUID) async -> BlockCheckResult {
        guard let userId = currentUserId else {
            return BlockCheckResult(canBlock: false, reason: "Not authenticated")
        }

        // Call the database function
        do {
            let result: Bool = try await supabase
                .rpc("can_block_user", params: [
                    "blocker_id": userId.uuidString,
                    "blocked_id": otherUserId.uuidString
                ])
                .execute()
                .value

            if result {
                return BlockCheckResult(canBlock: true, reason: nil)
            } else {
                return BlockCheckResult(
                    canBlock: false,
                    reason: "You have an active financial transaction with this user. You can mute notifications instead."
                )
            }
        } catch {
            return BlockCheckResult(canBlock: false, reason: "Unable to check block status")
        }
    }

    /// Block or unblock a user in a conversation
    func setBlocked(conversationId: UUID, blocked: Bool) async throws {
        guard let userId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        // Get the conversation first
        let convos: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("id", value: conversationId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let convo = convos.first else {
            throw ChatError.conversationNotFound
        }

        // Determine which field to update
        let field = convo.participant1Id == userId ? "is_blocked_by_1" : "is_blocked_by_2"

        try await supabase
            .from("conversations")
            .update([field: blocked])
            .eq("id", value: conversationId.uuidString)
            .execute()

        // Refresh conversations
        try await fetchConversations()
    }

    /// Mute or unmute a conversation
    func setMuted(conversationId: UUID, muted: Bool) async throws {
        guard let userId = currentUserId else {
            throw ChatError.notAuthenticated
        }

        // Get the conversation first
        let convos: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("id", value: conversationId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let convo = convos.first else {
            throw ChatError.conversationNotFound
        }

        // Determine which field to update
        let field = convo.participant1Id == userId ? "is_muted_by_1" : "is_muted_by_2"

        try await supabase
            .from("conversations")
            .update([field: muted])
            .eq("id", value: conversationId.uuidString)
            .execute()

        // Refresh conversations
        try await fetchConversations()
    }

    // MARK: - Typing Indicators

    /// Send typing indicator (using Realtime broadcast)
    func sendTypingIndicator() async {
        // Simplified - no realtime broadcast for now
        // Full implementation would use Supabase Realtime broadcast
    }

    /// Stop typing indicator
    func sendStopTypingIndicator() async {
        typingTimer?.invalidate()
        typingTimer = nil
    }
}

// MARK: - Message Grouping Extension

extension ChatService {
    /// Groups messages by date for display
    var groupedMessages: [(date: Date, messages: [ChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped
            .map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension ChatService {
    static var preview: ChatService {
        let service = ChatService()
        return service
    }
}
#endif
