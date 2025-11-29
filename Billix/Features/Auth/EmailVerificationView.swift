//
//  EmailVerificationView.swift
//  Billix
//
//  Created by Claude Code on 11/28/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService

    // Animation states
    @State private var letterOffset: CGFloat = 200
    @State private var letterOpacity: Double = 0
    @State private var mailboxRotation: Double = 0
    @State private var flagUp: Bool = false
    @State private var showCheckmark: Bool = false
    @State private var confettiTrigger: Int = 0

    // Resend cooldown
    @State private var resendCooldown: Int = 0
    @State private var isResending: Bool = false
    @State private var showResendSuccess: Bool = false

    // Timer for animation loop
    @State private var animationTimer: Timer?

    var body: some View {
        ZStack {
            // Background gradient (same as onboarding)
            LinearGradient(
                colors: [Color(hex: "1B4332"), Color(hex: "2D6A4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Animated mailbox
                mailboxAnimation
                    .frame(height: 200)

                // Title
                Text("Check Your Inbox")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                // Subtitle with email
                VStack(spacing: 8) {
                    Text("We sent a verification link to")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))

                    Text(authService.pendingVerificationEmail ?? "your email")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Waiting indicator
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)

                    Text("Waiting for you to verify...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Resend button
                    Button {
                        Task {
                            await resendEmail()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1B4332")))
                            } else {
                                Image(systemName: "envelope.arrow.triangle.branch")
                                Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend Email")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "1B4332"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            resendCooldown > 0 ? Color.white.opacity(0.5) : Color.white
                        )
                        .cornerRadius(28)
                    }
                    .disabled(resendCooldown > 0 || isResending)

                    // Back to login button
                    Button {
                        authService.cancelEmailVerification()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Use a different email")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }

            // Success feedback
            if showResendSuccess {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Verification email sent!")
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 160)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Confetti overlay
            if showCheckmark {
                ConfettiOverlay()
            }
        }
        .onAppear {
            startAnimationLoop()
            startPollingForVerification()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }

    // MARK: - Mailbox Animation

    private var mailboxAnimation: some View {
        ZStack {
            // Mailbox base
            VStack(spacing: 0) {
                // Flag
                HStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 8, height: 30)
                        .rotationEffect(.degrees(flagUp ? 0 : 90), anchor: .bottom)
                        .offset(x: 40, y: flagUp ? -15 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: flagUp)
                }
                .frame(height: 30)

                // Mailbox body
                ZStack {
                    // Main box
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4A90A4"), Color(hex: "357A8C")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                    // Slot
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 60, height: 8)
                        .offset(y: -20)

                    // Mailbox number
                    Text("B")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: 10)
                }
                .rotationEffect(.degrees(mailboxRotation))

                // Post
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B6914"), Color(hex: "6B5010")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 12, height: 50)
            }

            // Animated letter
            Image(systemName: "envelope.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 5)
                .offset(x: letterOffset, y: -50 + (200 - letterOffset) * 0.3)
                .rotationEffect(.degrees(Double(letterOffset) * 0.1 - 10))
                .opacity(letterOpacity)
        }
    }

    // MARK: - Animation Logic

    private func startAnimationLoop() {
        // Initial animation
        runLetterAnimation()

        // Loop every 4 seconds
        animationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            runLetterAnimation()
        }
    }

    private func runLetterAnimation() {
        // Reset
        letterOffset = 200
        letterOpacity = 0
        flagUp = false
        mailboxRotation = 0

        // Animate letter flying in
        withAnimation(.easeOut(duration: 0.8)) {
            letterOffset = 0
            letterOpacity = 1
        }

        // Letter drops into mailbox
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                letterOpacity = 0
            }

            // Shake mailbox
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                mailboxRotation = 5
            }
        }

        // Flag goes up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                mailboxRotation = 0
                flagUp = true
            }
        }
    }

    // MARK: - Verification Polling

    private func startPollingForVerification() {
        // Poll every 3 seconds to check if user verified
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            Task {
                let isVerified = await authService.checkEmailVerification()
                if isVerified {
                    timer.invalidate()
                    await MainActor.run {
                        showSuccessAnimation()
                    }
                }
            }
        }
    }

    private func showSuccessAnimation() {
        withAnimation {
            showCheckmark = true
        }

        // Auto transition after confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // AuthService will handle the transition via signedIn event
        }
    }

    // MARK: - Resend Logic

    private func resendEmail() async {
        guard let email = authService.pendingVerificationEmail else { return }

        isResending = true

        do {
            try await authService.resendVerificationEmail(email: email)

            isResending = false
            showResendSuccess = true
            resendCooldown = 60

            // Start countdown using Task
            startResendCooldown()

            // Hide success message
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showResendSuccess = false
            }
        } catch {
            isResending = false
        }
    }

    private func startResendCooldown() {
        Task { @MainActor in
            while resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                resendCooldown -= 1
            }
        }
    }
}

// MARK: - Confetti Overlay

struct ConfettiOverlay: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            // Success checkmark
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(confettiPieces.isEmpty ? 0 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: confettiPieces.count)

                Text("Email Verified!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .opacity(confettiPieces.isEmpty ? 0 : 1)
            }

            // Confetti pieces
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }

    private func generateConfetti() {
        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.orange].randomElement()!,
                x: CGFloat.random(in: -200...200),
                delay: Double(i) * 0.02
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var offset: CGFloat = -400
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(x: piece.x, y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0).delay(piece.delay)) {
                    offset = 600
                    rotation = Double.random(in: 0...720)
                }
            }
    }
}

// MARK: - Preview

#Preview {
    EmailVerificationView()
        .environmentObject(AuthService.shared)
}
