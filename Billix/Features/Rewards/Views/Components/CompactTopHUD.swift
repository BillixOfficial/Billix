//
//  CompactTopHUD.swift
//  Billix
//
//  Created by Claude Code
//  Compact top HUD for Price Guessr game
//  Consolidates health bar, timer, progress, score, close button, and help icon
//  36pt height (down from 60pt scattered elements)
//

import SwiftUI

struct CompactTopHUD: View {
    @ObservedObject var viewModel: GeoGameViewModel
    let onClose: () -> Void
    let onHelp: () -> Void

    // Progress text for different game modes
    var progressText: String {
        let currentIndex = viewModel.session.currentQuestionIndex + 1
        let totalQuestions = viewModel.session.questions.count

        // Check if it's a session-based game (30 questions)
        if totalQuestions >= 30 {
            // Session mode: Show location number instead of question number
            // 30 questions = 10 locations × 3 questions each
            let locationNumber = ((currentIndex - 1) / 3) + 1
            return "Loc \(locationNumber)/10"
        } else {
            // Season mode: "Loc 1 • Q 2/3"
            let locationNumber = viewModel.currentLocationNumber
            // Within current location (groups of 3), show question number 1-3
            let questionWithinLocation = ((currentIndex - 1) % 3) + 1

            return "Loc \(locationNumber) • Q \(questionWithinLocation)/3"
        }
    }

    // Timer color logic
    var timerColor: Color {
        if viewModel.timeRemaining <= 5 {
            return .red
        } else if viewModel.timeRemaining <= 10 {
            return .orange
        } else {
            return .billixMoneyGreen
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Close button (left) + Timer & Progress combined (center) + Landmark (right)
            HStack(spacing: 12) {
                // Close button (left)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .accessibilityLabel("Close game")
                .accessibilityHint("Closes the game and returns to the previous screen")

                Spacer()

                // Combined Timer + Progress pill (CENTER - white background)
                HStack(spacing: 12) {
                    // Timer section
                    if viewModel.isTimerActive && viewModel.displayTimeRemaining > 0 {
                        TimerDisplay(
                            displayTime: viewModel.displayTimeRemaining,
                            color: timerColor,
                            isCritical: viewModel.isTimerCritical
                        )
                    }

                    // Divider
                    if viewModel.isTimerActive && viewModel.displayTimeRemaining > 0 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 20)
                    }

                    // Progress section
                    Text(progressText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.billixMoneyGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                )
                .accessibilityLabel("Timer: \(viewModel.displayTimeRemaining) seconds, Progress: \(progressText)")

                Spacer()

                // Landmark button (right, only in Phase 1) OR Help button (other phases)
                if viewModel.gameState.phase == .phase1Location {
                    Button(action: {
                        viewModel.returnToLandmark()
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Landmark")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.billixMoneyGreen)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                    }
                    .accessibilityLabel("Return to landmark")
                } else {
                    // Help button (shown when landmark is not visible)
                    Button(action: onHelp) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Show tutorial")
                    .accessibilityHint("Opens the how to play guide")
                }
            }

            // Row 2: Health bar (full width)
            ContinuousHealthBar(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .padding(.bottom, 8)
    }
}

// MARK: - Timer Display Component

struct TimerDisplay: View {
    let displayTime: Int
    let color: Color
    let isCritical: Bool

    @State private var isPulsing: Bool = false
    @State private var isViewVisible = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            Text("\(displayTime)s")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
        }
        .scaleEffect(isPulsing ? 1.05 : 1.0)
        .onChange(of: isCritical) { _, newValue in
            guard isViewVisible else { return }
            if newValue {
                // Start pulsing animation
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                // Stop pulsing animation
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPulsing = false
                }
            }
        }
        .onAppear {
            isViewVisible = true
            // Initialize pulsing state
            if isCritical {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onDisappear {
            isViewVisible = false
            isPulsing = false
        }
    }
}

// MARK: - Preview

struct CompactTopHUD_Compact_Top_HUD___Session_Mode_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        // Simulated map background
        Color.green.opacity(0.3)
        .ignoresSafeArea()
        
        VStack {
        CompactTopHUD(
        viewModel: {
        let vm = GeoGameViewModel()
        vm.session.totalPoints = 1250
        vm.session.health = 2  // 66%
        return vm
        }(),
        onClose: {},
        onHelp: {}
        )
        
        Spacer()
        }
        }
    }
}

struct CompactTopHUD_Compact_Top_HUD___Season_Mode_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        // Simulated map background
        Color.blue.opacity(0.3)
        .ignoresSafeArea()
        
        VStack {
        CompactTopHUD(
        viewModel: {
        let vm = GeoGameViewModel()
        vm.session.totalPoints = 450
        vm.session.health = 3  // 100%
        return vm
        }(),
        onClose: {},
        onHelp: {}
        )
        
        Spacer()
        }
        }
    }
}
