//
//  SeasonGameContainerView.swift
//  Billix
//
//  Created by Claude Code
//  Wrapper view that adapts season locations to work with existing game engine
//

import SwiftUI

struct SeasonGameContainerView: View {
    let location: SeasonLocation
    let onComplete: (GameSession) -> Void

    @StateObject private var viewModel: GeoGameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExitWarning = false
    @State private var showTutorialManually = false

    init(location: SeasonLocation, onComplete: @escaping (GameSession) -> Void) {
        self.location = location
        self.onComplete = onComplete

        // Convert location to 3 GameQuestions
        let questions = location.toGameQuestions()

        // Create a 3-question session (1 location ID + 2 prices)
        let session = GameSession(
            id: UUID(),
            questions: questions,
            currentQuestionIndex: 0,
            health: 3,
            totalPoints: 0,
            questionsCorrect: 0,
            startedAt: Date(),
            landmarksCorrect: 0,
            landmarksAttempted: 0,
            pricesCorrect: 0,
            pricesAttempted: 0
        )

        // Initialize ViewModel with the session
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
                        // Restart the same location
                        dismiss()
                    },
                    onDismiss: {
                        // Return session for progress tracking
                        onComplete(viewModel.session)

                        // Post notification to dismiss back to rewards
                        NotificationCenter.default.post(
                            name: NSNotification.Name("DismissToRewards"),
                            object: nil
                        )

                        // Small delay to let notification propagate, then dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
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
            let totalQuestions = viewModel.session.questions.count

            Text("You've answered \(questionsAnswered)/\(totalQuestions) questions (\(questionsCorrect) correct).\n\nIf you exit now, your progress will NOT be saved. You must either lose all health or complete all \(totalQuestions) questions to save your attempt.")
        }
        .onChange(of: viewModel.session.isGameOver) { oldValue, newValue in
            // Auto-dismiss and save progress when game is over
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    onComplete(viewModel.session)
                    dismiss()
                }
            }
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

#Preview("Season Game") {
    SeasonGameContainerView(
        location: SeasonLocation(
            id: UUID(),
            seasonPartId: UUID(),
            locationNumber: 1,
            subject: "Manhattan Prices",
            locationName: "Manhattan, NY",
            category: "urban",
            difficulty: "hard",
            locationData: LocationDataJSON(
                landmarkName: "Empire State Building",
                coordinates: CoordinateData(lat: 40.7484, lng: -73.9857),
                landmark: CoordinateData(lat: 40.7484, lng: -73.9857),
                mapRegion: MapRegionDataJSON(pitch: 60, heading: 0, altitude: 1500),
                decoyLocations: [
                    DecoyLocationJSON(id: "A", displayLabel: "A", name: "Chicago, IL", isCorrect: false),
                    DecoyLocationJSON(id: "B", displayLabel: "B", name: "Manhattan, NY", isCorrect: true),
                    DecoyLocationJSON(id: "C", displayLabel: "C", name: "Toronto, Canada", isCorrect: false),
                    DecoyLocationJSON(id: "D", displayLabel: "D", name: "Philadelphia, PA", isCorrect: false)
                ]
            ),
            priceData: PriceDataJSON(
                questions: [
                    PriceQuestion(
                        type: "slider",
                        question: "Cost of a Standard Cappuccino?",
                        actualPrice: 5.75,
                        minGuess: 2.00,
                        maxGuess: 8.00,
                        unit: "each"
                    ),
                    PriceQuestion(
                        type: "slider",
                        question: "Avg Monthly Rent (1-Bed Apartment)?",
                        actualPrice: 4400.00,
                        minGuess: 1000.00,
                        maxGuess: 5000.00,
                        unit: "month"
                    )
                ]
            ),
            createdAt: Date()
        ),
        onComplete: { _ in }
    )
}
