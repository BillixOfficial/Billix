//
//  SwapChatView.swift
//  Billix
//
//  Swap Chat View for Bill Swap
//

import SwiftUI

struct SwapChatView: View {
    @StateObject private var viewModel: SwapChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    private let swap: BillSwap

    init(swapId: UUID, swap: BillSwap) {
        _viewModel = StateObject(wrappedValue: SwapChatViewModel(swapId: swapId))
        self.swap = swap
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.groupedMessages, id: \.date) { group in
                                // Date header
                                Text(formatDateHeader(group.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)

                                ForEach(group.messages) { message in
                                    ChatBubble(
                                        message: message,
                                        isMyMessage: viewModel.isMyMessage(message),
                                        onFlag: {
                                            Task { await viewModel.flagMessage(message) }
                                        }
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                ChatInputBar(
                    text: $viewModel.messageText,
                    isFocused: $isInputFocused,
                    characterCount: viewModel.characterCountText,
                    isOverLimit: viewModel.isOverLimit,
                    canSend: viewModel.canSendMessage,
                    isSending: viewModel.isSending,
                    onSend: {
                        Task { await viewModel.sendMessage() }
                    }
                )
            }
            .navigationTitle(viewModel.partnerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(viewModel.partnerName)
                            .font(.headline)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.isConnected ? Color.green : Color.gray)
                                .frame(width: 6, height: 6)

                            Text(viewModel.isConnected ? "Connected" : "Connecting...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .task {
                await viewModel.connect()
                await viewModel.loadPartnerInfo(from: swap)
            }
            .onDisappear {
                Task { await viewModel.disconnect() }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: SwapChatMessage
    let isMyMessage: Bool
    let onFlag: () -> Void

    @State private var showActions = false

    var body: some View {
        HStack {
            if isMyMessage { Spacer(minLength: 60) }

            VStack(alignment: isMyMessage ? .trailing : .leading, spacing: 4) {
                // System message style
                if message.isSystem {
                    Text(message.messageText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    // Regular message
                    Text(message.messageText)
                        .font(.body)
                        .foregroundColor(isMyMessage ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            isMyMessage
                                ? Color.billixMoneyGreen
                                : Color(UIColor.secondarySystemBackground)
                        )
                        .cornerRadius(18)
                        .contextMenu {
                            if !isMyMessage && !message.isFlagged {
                                Button {
                                    onFlag()
                                } label: {
                                    Label("Report Message", systemImage: "flag")
                                }
                            }
                        }

                    // Flagged indicator
                    if message.isFlagged {
                        HStack(spacing: 4) {
                            Image(systemName: "flag.fill")
                            Text("Flagged for review")
                        }
                        .font(.caption2)
                        .foregroundColor(.orange)
                    }

                    // Time
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if !isMyMessage { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let characterCount: String
    let isOverLimit: Bool
    let canSend: Bool
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                // Text field
                VStack(alignment: .trailing, spacing: 2) {
                    TextField("Message...", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($isFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)

                    // Character count
                    Text(characterCount)
                        .font(.caption2)
                        .foregroundColor(isOverLimit ? .red : .secondary)
                        .padding(.trailing, 4)
                }

                // Send button
                Button {
                    onSend()
                } label: {
                    if isSending {
                        ProgressView()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(canSend ? Color.billixMoneyGreen : .gray)
                    }
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Empty Chat State

struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start the conversation with your swap partner")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    SwapChatView(
        swapId: UUID(),
        swap: BillSwap(
            id: UUID(),
            swapType: .twoSided,
            status: .awaitingProof,
            initiatorUserId: UUID(),
            counterpartyUserId: UUID(),
            billAId: UUID(),
            billBId: nil,
            counterOfferAmountCents: nil,
            counterOfferByUserId: nil,
            feeAmountCentsInitiator: 99,
            feeAmountCentsCounterparty: 99,
            feePaidInitiator: true,
            feePaidCounterparty: true,
            pointsWaiverInitiator: false,
            pointsWaiverCounterparty: false,
            acceptDeadline: nil,
            proofDueDeadline: Date().addingTimeInterval(72 * 3600),
            createdAt: Date(),
            updatedAt: Date(),
            acceptedAt: Date(),
            lockedAt: Date(),
            completedAt: nil,
            billA: nil,
            billB: nil,
            initiatorProfile: nil,
            counterpartyProfile: nil
        )
    )
}
