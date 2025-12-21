//
//  SessionGameContainerView.swift
//  Billix
//
//  Created by Claude Code
//  Container view for full session-based gameplay (30 questions, 10 locations)
//

import SwiftUI

struct SessionGameContainerView: View {
    let session: GameSession
    let partId: UUID
    let onComplete: (GameSession) -> Void

    @StateObject private var viewModel: GeoGameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExitWarning = false

    init(session: GameSession, partId: UUID, onComplete: @escaping (GameSession) -> Void) {
        self.session = session
        self.partId = partId
        self.onComplete = onComplete

        // Initialize ViewModel with the 30-question session
        _viewModel = StateObject(wrappedValue: GeoGameViewModel(
            session: session,
            onComplete: { _ in } // We'll handle completion differently
        ))
    }

    var body: some View {
        ZStack {
            // Layer 1: Full-screen 3D satellite map
            GeoGameMapView(viewModel: viewModel)

            // Layer 2: Floating card at bottom (only if not game over)
            if !viewModel.session.isGameOver {
                VStack {
                    Spacer()
                    GeoGameFloatingCard(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea()
            }

            // Layer 3: Game over screen (if applicable)
            if viewModel.session.isGameOver {
                GeoGameOverView(
                    session: viewModel.session,
                    onPlayAgain: {
                        // Return to part selection for replay
                        onComplete(viewModel.session)
                        dismiss()
                    },
                    onDismiss: {
                        // Return session for progress tracking
                        onComplete(viewModel.session)
                        dismiss()
                    }
                )
                .transition(.opacity)
            }

            // Layer 4: Top bar with health, combo, score, progress
            if !viewModel.session.isGameOver {
                VStack {
                    HStack {
                        // Health hearts (with extra left padding to avoid X button)
                        HStack(spacing: 6) {
                            ForEach(0..<3) { index in
                                Image(systemName: index < viewModel.session.health ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(index < viewModel.session.health ? .red : .gray.opacity(0.3))
                            }
                        }
                        .padding(.leading, 70) // Extra padding to avoid X button overlap

                        Spacer()

                        // Question progress (e.g., "12/30")
                        Text("\(viewModel.session.currentQuestionIndex + 1)/30")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )

                        Spacer()

                        // Combo multiplier (if active)
                        if viewModel.session.comboStreak > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.billixPrizeOrange)

                                Text("\(viewModel.session.comboStreak)x")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                        }

                        Spacer()

                        // Score
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.billixArcadeGold)

                            Text("\(viewModel.session.totalPoints)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 60)

                    Spacer()
                }
            }

            // Layer 5: Close button (top-left)
            VStack {
                HStack {
                    Button(action: {
                        // Don't show warning if game is legitimately over
                        if viewModel.session.isGameOver || viewModel.session.health == 0 {
                            onComplete(viewModel.session)
                            dismiss()
                        } else {
                            // Show warning if mid-game
                            showExitWarning = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }

                Spacer()
            }
        }
        .background(Color.black)
        .statusBarHidden()
        .alert("Exit Game?", isPresented: $showExitWarning) {
            // Industry best practice: Destructive action on the left
            Button("Exit Anyway", role: .destructive) {
                onComplete(viewModel.session)
                dismiss()
            }

            // Safe action on the right (default)
            Button("Keep Playing", role: .cancel) {
                // Do nothing - just dismiss alert
            }
        } message: {
            let questionsAnswered = viewModel.session.currentQuestionIndex + 1
            let questionsCorrect = viewModel.session.questionsCorrect

            Text("You've answered \(questionsAnswered)/30 questions (\(questionsCorrect) correct).\n\nIf you exit now, your progress will NOT be saved. You must either lose all health or complete all 30 questions to save your attempt.")
        }
    }
}

// MARK: - Preview

#Preview("Session Game - 30 Questions") {
    // Use mock questions from GeoGameDataService
    let mockSession = GameSession(
        questions: GeoGameDataService.mockQuestions,
        currentQuestionIndex: 0,
        health: 3,
        totalPoints: 0,
        questionsCorrect: 0,
        comboStreak: 0
    )

    SessionGameContainerView(
        session: mockSession,
        partId: UUID(),
        onComplete: { _ in }
    )
}
