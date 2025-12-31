//
//  AssistMessagingService.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Real-time messaging service for Bill Assist negotiation using Supabase Realtime
//

import Foundation
import Supabase
import Realtime
import Combine

// MARK: - Message Insert DTO

private struct AssistMessageInsert: Codable {
    let assistRequestId: String
    let senderId: String
    let messageType: String
    let content: String?
    let termsData: RepaymentTerms?

    enum CodingKeys: String, CodingKey {
        case assistRequestId = "assist_request_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case termsData = "terms_data"
    }
}

// MARK: - Realtime Message Payload

private struct RealtimeMessagePayload: Codable {
    let id: String
    let assistRequestId: String
    let senderId: String
    let messageType: String
    let content: String?
    let termsData: RepaymentTerms?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case assistRequestId = "assist_request_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case termsData = "terms_data"
        case createdAt = "created_at"
    }

    func toAssistMessage() -> AssistMessage? {
        guard let id = UUID(uuidString: id),
              let requestId = UUID(uuidString: assistRequestId),
              let sender = UUID(uuidString: senderId),
              let type = AssistMessageType(rawValue: messageType) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAt) ?? Date()

        return AssistMessage(
            id: id,
            assistRequestId: requestId,
            senderId: sender,
            messageType: type,
            content: content,
            termsData: termsData,
            createdAt: date
        )
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: Equatable {
    let userId: UUID
    let isTyping: Bool
    let timestamp: Date
}

// MARK: - Messaging Error

enum AssistMessagingError: LocalizedError {
    case notAuthenticated
    case sendFailed
    case subscriptionFailed
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to send messages"
        case .sendFailed:
            return "Failed to send message. Please try again."
        case .subscriptionFailed:
            return "Failed to connect to chat. Please try again."
        case .invalidRequest:
            return "Invalid assist request"
        }
    }
}

// MARK: - Assist Messaging Service

@MainActor
class AssistMessagingService: ObservableObject {

    // MARK: - Published Properties
    @Published var messages: [AssistMessage] = []
    @Published var isLoading = false
    @Published var error: AssistMessagingError?
    @Published var typingUsers: Set<UUID> = []
    @Published var isConnected = false

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var currentAssistRequestId: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    private var typingTimer: Timer?

    // MARK: - Current User

    private var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    // MARK: - Initialization

    init() {}

    deinit {
        Task { @MainActor in
            await disconnect()
        }
    }

    // MARK: - Connect to Chat

    /// Connects to the realtime channel for an assist request
    func connect(to assistRequestId: UUID) async throws {
        guard currentUserId != nil else {
            throw AssistMessagingError.notAuthenticated
        }

        // Disconnect from any existing channel
        await disconnect()

        currentAssistRequestId = assistRequestId
        isLoading = true
        error = nil

        do {
            // Load existing messages
            try await loadMessages(for: assistRequestId)

            // Subscribe to realtime updates
            try await subscribeToMessages(for: assistRequestId)

            isConnected = true
        } catch {
            self.error = .subscriptionFailed
            throw AssistMessagingError.subscriptionFailed
        }

        isLoading = false
    }

    /// Disconnects from the current channel
    func disconnect() async {
        if let channel = realtimeChannel {
            await supabase.realtimeV2.removeChannel(channel)
        }
        realtimeChannel = nil
        currentAssistRequestId = nil
        messages = []
        typingUsers = []
        isConnected = false
        typingTimer?.invalidate()
        typingTimer = nil
    }

    // MARK: - Load Messages

    /// Loads existing messages for an assist request
    private func loadMessages(for assistRequestId: UUID) async throws {
        let loadedMessages: [AssistMessage] = try await supabase
            .from("assist_messages")
            .select()
            .eq("assist_request_id", value: assistRequestId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        messages = loadedMessages
    }

    // MARK: - Subscribe to Realtime

    /// Subscribes to realtime message updates
    private func subscribeToMessages(for assistRequestId: UUID) async throws {
        let channelName = "assist-messages:\(assistRequestId.uuidString)"

        let channel = supabase.realtimeV2.channel(channelName)

        // Subscribe to INSERT events on assist_messages table
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "assist_messages",
            filter: "assist_request_id=eq.\(assistRequestId.uuidString)"
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

    /// Handles a new message from realtime
    private func handleNewMessage(_ action: InsertAction) async {
        do {
            let payload = try action.decodeRecord(as: RealtimeMessagePayload.self, decoder: JSONDecoder())
            if let message = payload.toAssistMessage() {
                // Avoid duplicates
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        } catch {
            print("Failed to decode realtime message: \(error)")
        }
    }

    // MARK: - Send Messages

    /// Sends a text message
    func sendTextMessage(_ text: String) async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .text,
            content: trimmedText,
            termsData: nil
        )
    }

    /// Sends a terms proposal message
    func sendTermsProposal(_ terms: RepaymentTerms) async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .termsProposal,
            content: "Proposed new terms",
            termsData: terms
        )
    }

    /// Sends a terms accepted message
    func sendTermsAccepted(_ terms: RepaymentTerms) async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .termsAccepted,
            content: "Terms accepted",
            termsData: terms
        )
    }

    /// Sends a terms rejected message
    func sendTermsRejected() async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .termsRejected,
            content: "Terms declined",
            termsData: nil
        )
    }

    /// Sends a payment sent notification
    func sendPaymentSentMessage(screenshotUrl: String?) async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        var content = "Payment has been sent"
        if screenshotUrl != nil {
            content += " with screenshot proof"
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .paymentSent,
            content: content,
            termsData: nil
        )
    }

    /// Sends a payment verified notification
    func sendPaymentVerifiedMessage() async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .paymentVerified,
            content: "Payment has been verified",
            termsData: nil
        )
    }

    /// Sends a repayment received notification
    func sendRepaymentReceivedMessage(amount: Double) async throws {
        guard let requestId = currentAssistRequestId,
              let senderId = currentUserId else {
            throw AssistMessagingError.invalidRequest
        }

        let formattedAmount = String(format: "$%.2f", amount)
        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .repaymentReceived,
            content: "Received repayment of \(formattedAmount)",
            termsData: nil
        )
    }

    /// Sends a system message
    func sendSystemMessage(_ text: String, for requestId: UUID) async throws {
        guard let senderId = currentUserId else {
            throw AssistMessagingError.notAuthenticated
        }

        try await insertMessage(
            requestId: requestId,
            senderId: senderId,
            type: .system,
            content: text,
            termsData: nil
        )
    }

    /// Inserts a message into the database
    private func insertMessage(
        requestId: UUID,
        senderId: UUID,
        type: AssistMessageType,
        content: String?,
        termsData: RepaymentTerms?
    ) async throws {
        let messageData = AssistMessageInsert(
            assistRequestId: requestId.uuidString,
            senderId: senderId.uuidString,
            messageType: type.rawValue,
            content: content,
            termsData: termsData
        )

        do {
            try await supabase
                .from("assist_messages")
                .insert(messageData)
                .execute()
        } catch {
            throw AssistMessagingError.sendFailed
        }
    }

    // MARK: - Typing Indicators

    /// Broadcasts that the current user is typing (simplified - no realtime broadcast)
    func sendTypingIndicator() async {
        // Typing indicators are tracked locally only for now
        // Full realtime typing would require additional Supabase Realtime configuration
    }

    /// Broadcasts that the current user stopped typing
    func sendStopTypingIndicator() async {
        typingTimer?.invalidate()
        typingTimer = nil
    }

    // MARK: - Fetch Messages (Without Realtime)

    /// Fetches messages for an assist request without subscribing to realtime
    func fetchMessages(for assistRequestId: UUID) async throws -> [AssistMessage] {
        let loadedMessages: [AssistMessage] = try await supabase
            .from("assist_messages")
            .select()
            .eq("assist_request_id", value: assistRequestId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        return loadedMessages
    }

    // MARK: - Message Count

    /// Gets the unread message count for an assist request
    func getMessageCount(for assistRequestId: UUID) async throws -> Int {
        let messages: [AssistMessage] = try await supabase
            .from("assist_messages")
            .select()
            .eq("assist_request_id", value: assistRequestId.uuidString)
            .execute()
            .value

        return messages.count
    }
}

// MARK: - Message Grouping Extension

extension AssistMessagingService {
    /// Groups messages by date for display
    var groupedMessages: [(date: Date, messages: [AssistMessage])] {
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
extension AssistMessagingService {
    static var preview: AssistMessagingService {
        let service = AssistMessagingService()
        service.messages = [
            AssistMessage(
                id: UUID(),
                assistRequestId: UUID(),
                senderId: UUID(),
                messageType: .text,
                content: "Hi, I'd like to help with your electric bill.",
                termsData: nil,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            AssistMessage(
                id: UUID(),
                assistRequestId: UUID(),
                senderId: UUID(),
                messageType: .text,
                content: "Thank you so much! That would be amazing.",
                termsData: nil,
                createdAt: Date().addingTimeInterval(-3500)
            ),
            AssistMessage(
                id: UUID(),
                assistRequestId: UUID(),
                senderId: UUID(),
                messageType: .termsProposal,
                content: "Proposed new terms",
                termsData: .loanDefault(),
                createdAt: Date().addingTimeInterval(-3400)
            )
        ]
        return service
    }
}
#endif
