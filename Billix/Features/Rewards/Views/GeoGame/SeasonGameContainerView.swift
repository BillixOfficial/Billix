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
            comboStreak: 0,
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
                        // Restart the same location
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

            // Layer 4: Top bar with health, combo, score
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
