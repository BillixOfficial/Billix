//
//  SwapChatViewModel.swift
//  Billix
//
//  Swap Chat ViewModel
//

import Foundation
import Combine

@MainActor
class SwapChatViewModel: ObservableObject {
    // MARK: - Services
    private let chatService = SwapChatService.shared

    // MARK: - Published Properties

    @Published var swapId: UUID
    @Published var messages: [SwapChatMessage] = []
    @Published var messageText: String = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: SwapChatError?
    @Published var isConnected = false

    // Partner info
    @Published var partnerName: String = "Partner"
    @Published var partnerAvatarUrl: String?

    // MARK: - Computed Properties

    var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        messageText.count <= SwapChatConstants.maxMessageLength &&
        isConnected &&
        !isSending
    }

    var characterCount: Int {
        messageText.count
    }

    var characterCountText: String {
        "\(characterCount)/\(SwapChatConstants.maxMessageLength)"
    }

    var isOverLimit: Bool {
        characterCount > SwapChatConstants.maxMessageLength
    }

    var groupedMessages: [(date: Date, messages: [SwapChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped
            .map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(swapId: UUID) {
        self.swapId = swapId
        setupBindings()
    }

    private func setupBindings() {
        // Subscribe to chat service messages
        chatService.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.messages = messages
            }
            .store(in: &cancellables)

        chatService.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
            }
            .store(in: &cancellables)

        chatService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }

    // MARK: - Connect

    func connect() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await chatService.connect(to: swapId)
        } catch {
            if let chatError = error as? SwapChatError {
                self.error = chatError
            } else {
                self.error = .subscriptionFailed
            }
        }
    }

    func disconnect() async {
        await chatService.disconnect()
    }

    // MARK: - Send Message

    func sendMessage() async {
        guard canSendMessage else { return }

        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = "" // Clear immediately for better UX

        isSending = true
        defer { isSending = false }

        do {
            try await chatService.sendMessage(text)
        } catch {
            // Restore message if send failed
            messageText = text
            if let chatError = error as? SwapChatError {
                self.error = chatError
            } else {
                self.error = .sendFailed
            }
        }
    }

    // MARK: - Flag Message

    func flagMessage(_ message: SwapChatMessage) async {
        do {
            try await chatService.flagMessage(message.id)
        } catch {
            print("Failed to flag message: \(error)")
        }
    }

    // MARK: - Helpers

    func isMyMessage(_ message: SwapChatMessage) -> Bool {
        message.senderUserId == currentUserId
    }

    func loadPartnerInfo(from swap: BillSwap) async {
        guard let userId = currentUserId else { return }

        let partnerId = swap.initiatorUserId == userId
            ? swap.counterpartyUserId
            : swap.initiatorUserId

        guard let partnerId = partnerId else { return }

        // Fetch partner profile
        do {
            let supabase = SupabaseService.shared.client
            struct Profile: Codable {
                let displayName: String?
                let handle: String?
                let avatarUrl: String?

                enum CodingKeys: String, CodingKey {
                    case displayName = "display_name"
                    case handle
                    case avatarUrl = "avatar_url"
                }
            }

            let profile: Profile = try await supabase
                .from("profiles")
                .select("display_name, handle, avatar_url")
                .eq("id", value: partnerId.uuidString)
                .single()
                .execute()
                .value

            partnerName = profile.displayName ?? profile.handle ?? "Partner"
            partnerAvatarUrl = profile.avatarUrl
        } catch {
            print("Failed to load partner info: \(error)")
        }
    }
}

