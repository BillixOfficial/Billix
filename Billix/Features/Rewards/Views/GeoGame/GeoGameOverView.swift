//
//  GeoGameOverView.swift
//  Billix
//
//  Enhanced with industry best practices:
//  - Animated celebrations, star ratings, progressive reveals
//  - Microinteractions, visual polish, psychological hooks
//

import SwiftUI

struct GeoGameOverView: View {

    let session: GameSession
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showStars = false
    @State private var showStats = false
    @State private var animatedAccuracy = 0.0
    @State private var showConfetti = false
    @State private var pulseButton = false

    var didWin: Bool {
        session.hasWon
    }

    var accuracy: Double {
        let total = session.landmarksAttempted + session.pricesAttempted
        guard total > 0 else { return 0 }
        let correct = session.landmarksCorrect + session.pricesCorrect
        return Double(correct) / Double(total)
    }

    // Session-based pass/fail (for 30-question sessions)
    var totalCorrect: Int {
        session.landmarksCorrect + session.pricesCorrect
    }

    var hasPassed: Bool {
        totalCorrect >= 24  // 80% of 30
    }

    var isFullSession: Bool {
        // Full session = 30 questions (10 locations × 3 questions)
        let totalQuestions = session.landmarksAttempted + session.pricesAttempted
        return totalQuestions == 30
    }

    // Star rating based on performance
    var stars: Int {
        if accuracy >= 0.9 { return 3 }
        if accuracy >= 0.7 { return 2 }
        if accuracy >= 0.5 { return 1 }
        return 0
    }

    // Performance tier
    var performanceTier: String {
        if accuracy >= 0.9 { return "MASTER" }
        if accuracy >= 0.7 { return "EXPERT" }
        if accuracy >= 0.5 { return "SKILLED" }
        return "NOVICE"
    }

    var tierColor: Color {
        if accuracy >= 0.9 { return Color(hex: "#FFD700") } // Gold
        if accuracy >= 0.7 { return Color(hex: "#C0C0C0") } // Silver
        if accuracy >= 0.5 { return Color(hex: "#CD7F32") } // Bronze
        return .gray
    }

    // Extract complex gradients to help Swift compiler
    private var backgroundGradient: LinearGradient {
        if didWin {
            return LinearGradient(
                colors: [Color(hex: "#1E3A8A"), Color(hex: "#3B82F6"), Color(hex: "#60A5FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "#7F1D1D"), Color(hex: "#991B1B"), Color(hex: "#B91C1C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var trophyGradient: LinearGradient {
        if didWin {
            return LinearGradient(
                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.white.opacity(0.8), .white.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var trophySection: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColor.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .scaleEffect(showContent ? 1.2 : 0.8)
                .opacity(showContent ? 1 : 0)

            Image(systemName: didWin ? "trophy.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(trophyGradient)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .rotationEffect(.degrees(showContent ? 0 : -180))
                .shadow(color: tierColor.opacity(0.5), radius: 20)
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(didWin ? "VICTORY!" : "GAME OVER")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1 : 0)

            if didWin {
                // Performance tier badge
                Text(performanceTier)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(tierColor)
                            .shadow(color: tierColor.opacity(0.5), radius: 8)
                    )
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1 : 0)
            } else {
                Text("Keep trying - you'll get it!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showContent ? 1 : 0)
            }
        }
    }

    @ViewBuilder
    private var passFailBanner: some View {
        if isFullSession {
            VStack(spacing: 8) {
                if hasPassed {
                    passedBanner
                } else {
                    failedBanner
                }
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1 : 0)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var passedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("PASSED!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("Deep Cuts Unlocked")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Text("\(totalCorrect)/30")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                )
        )
    }

    @ViewBuilder
    private var failedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Need 24/30 to Pass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("Try again to unlock Deep Cuts")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Text("\(totalCorrect)/30")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                )
        )
    }

    var body: some View {
        ZStack {
            // Dynamic gradient background
            backgroundGradient
                .ignoresSafeArea()

            // Confetti particles for wins
            if didWin {
                ConfettiView(isActive: showConfetti, type: .celebration)
            }

            VStack(spacing: 0) {
                Spacer()

                // Main content card
                VStack(spacing: 24) {
                    // Trophy/Icon with glow
                    trophySection

                    // Title and subtitle
                    titleSection

                    // Pass/Fail Banner (for 30-question sessions)
                    passFailBanner

                    // Star rating (only for wins)
                    if didWin {
                        HStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                Image(systemName: index < stars ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(index < stars ? Color(hex: "#FFD700") : .white.opacity(0.3))
                                    .scaleEffect(showStars && index < stars ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.1), value: showStars)
                                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: index < stars ? 8 : 0)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Stats card with animated reveals
                    VStack(spacing: 0) {
                        // Secondary stats
                        VStack(spacing: 16) {
                            AnimatedStatRow(
                                icon: "checkmark.circle.fill",
                                label: "Accuracy",
                                value: String(format: "%.0f%%", animatedAccuracy * 100),
                                color: .billixMoneyGreen,
                                isVisible: showStats
                            )

                            // New: Landmark performance
                            AnimatedStatRow(
                                icon: "mappin.and.ellipse",
                                label: "Landmarks Identified",
                                value: "\(session.landmarksCorrect)/\(session.landmarksAttempted)",
                                color: .blue,
                                isVisible: showStats
                            )

                            // New: Price performance (conditional)
                            if session.pricesAttempted > 0 {
                                AnimatedStatRow(
                                    icon: "dollarsign.circle.fill",
                                    label: "Prices Guessed Correctly",
                                    value: "\(session.pricesCorrect)/\(session.pricesAttempted)",
                                    color: .billixArcadeGold,
                                    isVisible: showStats
                                )
                            }

                            // Health display
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)

                                Text("Final Health")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))

                                Spacer()

                                HStack(spacing: 4) {
                                    ForEach(0..<max(0, session.health), id: \.self) { _ in
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .opacity(showStats ? 1 : 0)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.05))
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .shadow(color: .black.opacity(0.2), radius: 20)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .scaleEffect(showStats ? 1.0 : 0.95)
                .opacity(showStats ? 1 : 0)

                Spacer()

                // Action buttons with psychological hooks
                VStack(spacing: 12) {
                    // Primary CTA - Play Again
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onPlayAgain()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 20))
                            Text(didWin ? "PLAY AGAIN" : "TRY AGAIN")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.billixArcadeGold, Color(hex: "#FFA500"), Color(hex: "#FF6B35")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.billixArcadeGold.opacity(0.4), radius: 12, x: 0, y: 4)
                        .scaleEffect(pulseButton ? 1.05 : 1.0)
                    }

                    // Secondary CTA
                    Button(action: onDismiss) {
                        Text("Back to Rewards")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // 1. Show trophy/icon with bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        // 2. Show stars with delay
        if didWin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showStars = true
                }
                // Trigger confetti
                showConfetti = true
            }
        }

        // 3. Show stats card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showStats = true
            }

            // 4. Animate accuracy count-up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateAccuracy()
            }
        }

        // 6. Pulse the play again button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseButton = true
            }
        }
    }

    private func animateAccuracy() {
        let duration = 0.8
        let steps = 20
        let increment = accuracy / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(i)) {
                animatedAccuracy = min(increment * Double(i), accuracy)
            }
        }
    }
}

// MARK: - Animated Stat Row

struct AnimatedStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Previews

#Preview("Victory") {
    let winSession = GameSession(
        questions: GeoGameDataService.mockQuestions,
        currentQuestionIndex: 12,
        health: 2,
        totalPoints: 2850,
        questionsCorrect: 11
    )

    return GeoGameOverView(
        session: winSession,
        onPlayAgain: {},
        onDismiss: {}
    )
}

#Preview("Loss") {
    let lossSession = GameSession(
        questions: GeoGameDataService.mockQuestions,
        currentQuestionIndex: 6,
        health: 0,
        totalPoints: 1200,
        questionsCorrect: 4
    )

    return GeoGameOverView(
        session: lossSession,
        onPlayAgain: {},
        onDismiss: {}
    )
}
