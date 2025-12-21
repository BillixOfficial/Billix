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
            // Session mode: "Q 12/30"
            return "Q \(currentIndex)/\(totalQuestions)"
        } else {
            // Season mode: "Loc 1 • Q 2/3"
            let locationNumber = viewModel.currentLocationNumber
            // Within current location (groups of 3), show question number 1-3
            let questionWithinLocation = ((currentIndex - 1) % 3) + 1

            return "Loc \(locationNumber) • Q \(questionWithinLocation)/3"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Close button (left edge)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close game")
            .accessibilityHint("Closes the game and returns to the previous screen")

            // Health bar with integrated timer (center, fills available space)
            ContinuousHealthBar(viewModel: viewModel)
                .frame(minWidth: 200, maxWidth: .infinity)

            // Right side group: Progress + Score + Help
            HStack(spacing: 8) {
                // Progress indicator
                Text(progressText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .accessibilityLabel("Progress: \(progressText)")

                // Score display
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixArcadeGold)

                    Text("\(viewModel.session.totalPoints)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Score: \(viewModel.session.totalPoints) points")

                // Help icon
                Button(action: onHelp) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#00D9FF"))
                        .shadow(color: Color(hex: "#00D9FF").opacity(0.6), radius: 8)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }
                .accessibilityLabel("View tutorial")
                .accessibilityHint("Shows how to play Price Guessr")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 8)
        .background(
            .ultraThinMaterial
                .environment(\.colorScheme, .dark)
        )
    }
}

// MARK: - Preview

#Preview("Compact Top HUD - Session Mode") {
    ZStack {
        // Simulated map background
        Color.green.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            CompactTopHUD(
                viewModel: {
                    let vm = GeoGameViewModel()
                    vm.session.totalQuestions = 30
                    vm.session.totalPoints = 1250
                    vm.session.health = 2  // 66%
                    return vm
                }(),
                onClose: { print("Close tapped") },
                onHelp: { print("Help tapped") }
            )

            Spacer()
        }
    }
}

#Preview("Compact Top HUD - Season Mode") {
    ZStack {
        // Simulated map background
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            CompactTopHUD(
                viewModel: {
                    let vm = GeoGameViewModel()
                    vm.session.totalQuestions = 3
                    vm.session.totalPoints = 450
                    vm.session.health = 3  // 100%
                    return vm
                }(),
                onClose: { print("Close tapped") },
                onHelp: { print("Help tapped") }
            )

            Spacer()
        }
    }
}
