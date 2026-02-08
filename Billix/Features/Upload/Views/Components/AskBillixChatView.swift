//
//  AskBillixChatView.swift
//  Billix
//
//  Created by Claude Code on 2/3/26.
//

import SwiftUI
import SwiftData

struct AskBillixChatView: View {
    let analysis: BillAnalysis
    let billId: UUID?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AskBillixViewModel
    @FocusState private var isInputFocused: Bool
    @State private var mascotFloating = false
    @State private var coinAtTop = true
    @State private var appeared = false

    init(analysis: BillAnalysis, billId: UUID? = nil) {
        self.analysis = analysis
        self.billId = billId
        self._viewModel = StateObject(wrappedValue: AskBillixViewModel(analysis: analysis, billId: billId))
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                // Error banner
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }

                if viewModel.hasStartedChat {
                    chatContent
                } else {
                    landingContent
                }

                inputBar
            }

        }
        .onAppear {
            // Inject modelContext and load existing session
            viewModel.modelContext = modelContext
            viewModel.loadExistingSession()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
            mascotFloating = true
            let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    coinAtTop.toggle()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Button {
                viewModel.dismissError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.85))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.billixDarkGreen.opacity(0.9),
                Color.billixMoneyGreen.opacity(0.75),
                Color.billixDarkGreen.opacity(0.65)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Ask Billix")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Landing Content

    private var landingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 10)

                // Mascot
                mascotView
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                // Greeting
                VStack(spacing: 6) {
                    Text("Hi \(viewModel.userFirstName)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("What would you like\nto know?")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                Spacer().frame(height: 8)

                // Suggested question pills
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        questionPill(question)
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)

                Spacer().frame(height: 20)
            }
        }
    }

    // MARK: - Mascot View

    private var mascotView: some View {
        ZStack {
            // Outer glass ring
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 130, height: 130)
                .blur(radius: 0.5)

            // Inner glass ring
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 100, height: 100)

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 65
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 10)

            // Piggy + coin
            VStack(spacing: -5) {
                Image("CoinInsert")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .offset(y: 15 + (coinAtTop ? -10 : 8))
                    .animation(.easeInOut(duration: 1.5), value: coinAtTop)

                Image("HoloPiggy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 165, height: 165)
                    .offset(y: -20)
            }
            .offset(y: mascotFloating ? -3 : 3)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: mascotFloating
            )
        }
        .frame(height: 130)
    }

    // MARK: - Question Pill

    private func questionPill(_ text: String) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            viewModel.sendMessage(text)
        } label: {
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if viewModel.isTyping {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if viewModel.isTyping {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { _, isTyping in
                withAnimation(.easeOut(duration: 0.3)) {
                    if isTyping {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Scroll to bottom INSTANTLY when chat loads (no animation)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.hasStartedChat) { _, hasStarted in
                // Scroll to bottom INSTANTLY when messages load from persistence
                if hasStarted && !viewModel.messages.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: AskBillixMessage) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    HStack(spacing: -8) {
                        Image("HoloPiggy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        Text("Billix")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Group {
                    if let attributed = try? AttributedString(
                        markdown: message.content,
                        options: AttributedString.MarkdownParsingOptions(
                            interpretedSyntax: .inlineOnlyPreservingWhitespace
                        )
                    ) {
                        Text(attributed)
                    } else {
                        Text(message.content)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                message.role == .user
                                    ? Color.billixMoneyGreen.opacity(0.6)
                                    : Color.white.opacity(0.18)
                            )
                    )
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: -8) {
                    Image("HoloPiggy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text("Billix")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }

                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        BouncingDot(delay: Double(index) * 0.2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.18))
                )
            }

            Spacer(minLength: 40)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your bill...", text: $viewModel.inputText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.white)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.sendMessage()
                }

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .white.opacity(0.3)
                            : .white
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Bouncing Dot Animation

private struct BouncingDot: View {
    let delay: Double
    @State private var bouncing = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.5))
            .frame(width: 8, height: 8)
            .offset(y: bouncing ? -5 : 0)
            .animation(
                .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: bouncing
            )
            .onAppear {
                bouncing = true
            }
    }
}
