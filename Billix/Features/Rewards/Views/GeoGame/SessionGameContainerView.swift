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
    @State private var showTutorialManually = false

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

            // Layer 2: Minimal bottom deck (only if not game over)
            if !viewModel.session.isGameOver {
                VStack {
                    Spacer()
                    MinimalBottomDeck(viewModel: viewModel)
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

            // Layer 4: Compact top HUD with health, timer, progress, score, help, close button
            if !viewModel.session.isGameOver {
                VStack {
                    CompactTopHUD(
                        viewModel: viewModel,
                        onClose: {
                            // Don't show warning if game is legitimately over
                            if viewModel.session.isGameOver || viewModel.session.health == 0 {
                                onComplete(viewModel.session)
                                dismiss()
                            } else {
                                // Show warning if mid-game
                                showExitWarning = true
                            }
                        },
                        onHelp: {
                            showTutorialManually = true
                        }
                    )
                    Spacer()
                }
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
        .sheet(isPresented: $showTutorialManually) {
            GeoGameHowToPlayView(
                onStart: { showTutorialManually = false },
                onSkip: { showTutorialManually = false },
                onSkipAndDontShowAgain: { showTutorialManually = false },
                onPageChanged: { _ in },
                isLoading: false,
                isManualView: true  // Simple X to close for manual viewing
            )
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
        questionsCorrect: 0
    )

    return SessionGameContainerView(
        session: mockSession,
        partId: UUID(),
        onComplete: { _ in }
    )
}
