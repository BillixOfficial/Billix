//
//  MessageBubble.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

// MARK: - Theme

private enum MessageTheme {
    static let sentBubble = Color(hex: "#5B8A6B")
    static let receivedBubble = Color(hex: "#E8ECE9")
    static let sentText = Color.white
    static let receivedText = Color(hex: "#2D3B35")
    static let timestamp = Color(hex: "#8B9A94")
    static let readReceipt = Color(hex: "#5BA4D4")
}

struct MessageBubble: View {
    let message: ChatMessage
    let isSentByCurrentUser: Bool
    let showTimestamp: Bool

    init(message: ChatMessage, currentUserId: UUID?, showTimestamp: Bool = false) {
        self.message = message
        self.isSentByCurrentUser = message.senderId == currentUserId
        self.showTimestamp = showTimestamp
    }

    var body: some View {
        VStack(alignment: isSentByCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isSentByCurrentUser {
                    Spacer(minLength: 60)
                }

                bubbleContent

                if !isSentByCurrentUser {
                    Spacer(minLength: 60)
                }
            }

            // Timestamp and read receipt
            if showTimestamp || message.messageType == .image {
                HStack(spacing: 4) {
                    if isSentByCurrentUser {
                        Spacer()
                    }

                    Text(formatTime(message.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(MessageTheme.timestamp)

                    // Read receipt indicator (for sent messages)
                    if isSentByCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 11))
                            .foregroundColor(message.isRead ? MessageTheme.readReceipt : MessageTheme.timestamp)
                    }

                    if !isSentByCurrentUser {
                        Spacer()
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.messageType {
        case .text:
            textBubble

        case .image:
            imageBubble

        case .system:
            systemMessage
        }
    }

    private var textBubble: some View {
        Text(message.content ?? "")
            .font(.system(size: 16))
            .foregroundColor(isSentByCurrentUser ? MessageTheme.sentText : MessageTheme.receivedText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSentByCurrentUser ? MessageTheme.sentBubble : MessageTheme.receivedBubble)
            .clipShape(ChatBubbleShape(isSentByCurrentUser: isSentByCurrentUser))
    }

    private var imageBubble: some View {
        Group {
            if let imageUrlString = message.imageUrl,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 200, height: 150)

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 220, maxHeight: 300)
                            .clipped()

                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(MessageTheme.timestamp)
                            .frame(width: 200, height: 150)

                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSentByCurrentUser ? MessageTheme.sentBubble : MessageTheme.receivedBubble, lineWidth: 2)
                )
            }
        }
    }

    private var systemMessage: some View {
        Text(message.content ?? "")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(MessageTheme.timestamp)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isSentByCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 8

        var path = Path()

        if isSentByCurrentUser {
            // Sent message - rounded on left, tail on right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailSize))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Received message - tail on left, rounded on right
            path.move(to: CGPoint(x: rect.minX + tailSize, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - tailSize),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + tailSize, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Date Separator

struct DateSeparator: View {
    let date: Date

    var body: some View {
        HStack {
            VStack { Divider() }
            Text(formatDate(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MessageTheme.timestamp)
                .padding(.horizontal, 12)
            VStack { Divider() }
        }
        .padding(.vertical, 12)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(MessageTheme.timestamp)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset(for: index))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MessageTheme.receivedBubble)
        .clipShape(ChatBubbleShape(isSentByCurrentUser: false))
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                animationOffset = -4
            }
        }
        .onDisappear {
            // Stop the repeating animation when view disappears
            animationOffset = 0
        }
    }

    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        return sin((animationOffset + CGFloat(delay)) * .pi) * 4
    }
}

// MARK: - Previews

#if DEBUG
struct MessageBubble_Previews: PreviewProvider {
    static let currentUserId = UUID()

    static var previews: some View {
        VStack(spacing: 8) {
            MessageBubble(
                message: ChatMessage(
                    id: UUID(),
                    conversationId: UUID(),
                    senderId: currentUserId,
                    messageType: .text,
                    content: "Hey! Thanks for helping with my electric bill.",
                    imageUrl: nil,
                    isRead: true,
                    createdAt: Date()
                ),
                currentUserId: currentUserId,
                showTimestamp: true
            )

            MessageBubble(
                message: ChatMessage(
                    id: UUID(),
                    conversationId: UUID(),
                    senderId: UUID(),
                    messageType: .text,
                    content: "No problem! Happy to help out.",
                    imageUrl: nil,
                    isRead: false,
                    createdAt: Date()
                ),
                currentUserId: currentUserId,
                showTimestamp: true
            )

            HStack {
                TypingIndicatorView()
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(hex: "#F7F9F8"))
    }
}
#endif
