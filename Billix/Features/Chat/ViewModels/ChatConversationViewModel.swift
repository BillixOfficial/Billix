//
//  ChatConversationViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class ChatConversationViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isConnected = false
    @Published var otherParticipant: ChatParticipant?
    @Published var isOtherUserTyping = false
    @Published var showImagePicker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var showBlockOptions = false
    @Published var canBlock = true
    @Published var blockReason: String?

    // MARK: - Private Properties
    private let chatService = ChatService.shared
    let conversationId: UUID

    // MARK: - Current User
    var currentUserId: UUID? {
        SupabaseService.shared.currentUserId
    }

    // MARK: - Computed Properties

    var groupedMessages: [(date: Date, messages: [ChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped
            .map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    // MARK: - Initialization

    init(conversationId: UUID, otherParticipant: ChatParticipant? = nil) {
        self.conversationId = conversationId
        self.otherParticipant = otherParticipant

        // Observe messages from ChatService
        Task {
            for await msgs in chatService.$messages.values {
                messages = msgs
            }
        }

        Task {
            for await connected in chatService.$isConnected.values {
                isConnected = connected
            }
        }
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await connect()
        await checkBlockStatus()
    }

    func onDisappear() async {
        await chatService.disconnect()
    }

    // MARK: - Connection

    private func connect() async {
        isLoading = true
        errorMessage = nil

        do {
            try await chatService.connect(to: conversationId)
            messages = chatService.messages
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Sending Messages

    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        messageText = ""

        do {
            try await chatService.sendTextMessage(text)
        } catch {
            messageText = text // Restore message on failure
            errorMessage = error.localizedDescription
            showError = true
        }

        isSending = false
    }

    func sendImage() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        isSending = true
        selectedImage = nil
        selectedPhotoItem = nil

        do {
            try await chatService.sendImageMessage(imageData: imageData)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSending = false
    }

    // MARK: - Image Handling

    func loadImage() async {
        guard let item = selectedPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }

    func clearSelectedImage() {
        selectedImage = nil
        selectedPhotoItem = nil
    }

    // MARK: - Blocking

    private func checkBlockStatus() async {
        guard let participant = otherParticipant else { return }

        let result = await chatService.canBlockUser(participant.id)
        canBlock = result.canBlock
        blockReason = result.reason
    }

    func blockUser() async {
        guard canBlock else {
            errorMessage = blockReason ?? "Cannot block this user"
            showError = true
            return
        }

        do {
            try await chatService.setBlocked(conversationId: conversationId, blocked: true)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func muteUser() async {
        do {
            try await chatService.setMuted(conversationId: conversationId, muted: true)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Typing Indicators

    func startTyping() {
        Task {
            await chatService.sendTypingIndicator()
        }
    }

    func stopTyping() {
        Task {
            await chatService.sendStopTypingIndicator()
        }
    }
}
