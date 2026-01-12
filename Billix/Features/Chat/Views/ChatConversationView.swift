//
//  ChatConversationView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI
import PhotosUI

// MARK: - Theme

private enum ChatTheme {
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let info = Color(hex: "#5BA4D4")
    static let inputBackground = Color(hex: "#FFFFFF")
    static let inputBorder = Color(hex: "#E0E5E3")
}

struct ChatConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatConversationViewModel
    @FocusState private var isInputFocused: Bool

    init(conversationId: UUID, otherParticipant: ChatParticipant?) {
        _viewModel = StateObject(wrappedValue: ChatConversationViewModel(
            conversationId: conversationId,
            otherParticipant: otherParticipant
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            // Input bar
            inputBar
        }
        .background(ChatTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerView
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.showBlockOptions = true
                    } label: {
                        Label("Block Options", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(ChatTheme.accent)
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            Task {
                await viewModel.onDisappear()
            }
        }
        .photosPicker(
            isPresented: $viewModel.showImagePicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadImage()
            }
        }
        .sheet(isPresented: .constant(viewModel.selectedImage != nil)) {
            imagePreviewSheet
        }
        .confirmationDialog(
            "Block Options",
            isPresented: $viewModel.showBlockOptions,
            titleVisibility: .visible
        ) {
            if viewModel.canBlock {
                Button("Block User", role: .destructive) {
                    Task { await viewModel.blockUser() }
                }
            }
            Button("Mute Notifications") {
                Task { await viewModel.muteUser() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if !viewModel.canBlock, let reason = viewModel.blockReason {
                Text(reason)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 10) {
            if let participant = viewModel.otherParticipant {
                AvatarView(url: nil, size: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(participant.displayLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ChatTheme.primaryText)

                    if !participant.formattedHandle.isEmpty {
                        Text(participant.formattedHandle)
                            .font(.system(size: 12))
                            .foregroundColor(ChatTheme.info)
                    }
                }
            }
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.groupedMessages, id: \.date) { group in
                        DateSeparator(date: group.date)

                        ForEach(Array(group.messages.enumerated()), id: \.element.id) { index, message in
                            let showTimestamp = shouldShowTimestamp(
                                message: message,
                                previousMessage: index > 0 ? group.messages[index - 1] : nil
                            )

                            MessageBubble(
                                message: message,
                                currentUserId: viewModel.currentUserId,
                                showTimestamp: showTimestamp
                            )
                        }
                    }

                    // Typing indicator
                    if viewModel.isOtherUserTyping {
                        HStack {
                            TypingIndicatorView()
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    // Anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private func shouldShowTimestamp(message: ChatMessage, previousMessage: ChatMessage?) -> Bool {
        guard let previous = previousMessage else { return true }

        // Show timestamp if sender changed
        if message.senderId != previous.senderId { return true }

        // Show timestamp if more than 5 minutes apart
        let interval = message.createdAt.timeIntervalSince(previous.createdAt)
        return interval > 300
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                // Camera button
                Button {
                    viewModel.showImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ChatTheme.info)
                }
                .padding(.bottom, 8)

                // Text input
                HStack(alignment: .bottom) {
                    TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundColor(ChatTheme.primaryText)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .onChange(of: viewModel.messageText) { _, newValue in
                            if !newValue.isEmpty {
                                viewModel.startTyping()
                            } else {
                                viewModel.stopTyping()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(ChatTheme.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ChatTheme.inputBorder, lineWidth: 1)
                )
                .cornerRadius(20)

                // Send button
                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.canSend ? ChatTheme.accent : ChatTheme.secondaryText.opacity(0.5))
                }
                .disabled(!viewModel.canSend || viewModel.isSending)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ChatTheme.cardBackground)
        }
    }

    // MARK: - Image Preview Sheet

    private var imagePreviewSheet: some View {
        NavigationView {
            VStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }

                Spacer()

                // Send button
                Button {
                    Task {
                        await viewModel.sendImage()
                    }
                } label: {
                    HStack {
                        if viewModel.isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(viewModel.isSending ? "Sending..." : "Send Image")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ChatTheme.accent)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSending)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Send Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.clearSelectedImage()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ChatConversationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatConversationView(
                conversationId: UUID(),
                otherParticipant: ChatParticipant(
                    userId: UUID(),
                    handle: "savingsking",
                    displayName: "John Smith"
                )
            )
        }
    }
}
#endif
