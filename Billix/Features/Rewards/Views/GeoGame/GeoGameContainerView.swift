//
//  GeoGameContainerView.swift
//  Billix
//
//  Created by Claude Code
//  Main orchestrator view for the geo-economic game
//

import SwiftUI

struct GeoGameContainerView: View {

    let initialGame: DailyGame
    let onComplete: (GameResult) -> Void
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel: GeoGameViewModel
    @State private var currentGameId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var showTutorialManually = false

    init(initialGame: DailyGame, onComplete: @escaping (GameResult) -> Void, onPlayAgain: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.initialGame = initialGame
        self.onComplete = onComplete
        self.onPlayAgain = onPlayAgain
        self.onDismiss = onDismiss
        _currentGameId = State(initialValue: initialGame.id)

        // Initialize view model with 12-question session instead of single game
        _viewModel = StateObject(wrappedValue: GeoGameViewModel(
            session: GeoGameDataService.generateGameSession(),
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            // Layer 1: Full-screen 3D satellite map (always visible, orbiting)
            GeoGameMapView(viewModel: viewModel)

            // Layer 2: Floating card at bottom (only if not game over)
            if viewModel.questionPhase != .gameOver {
                VStack {
                    Spacer()
                    GeoGameFloatingCard(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }

            // Layer 3: Game Over screen
            if viewModel.questionPhase == .gameOver {
                GeoGameOverView(
                    session: viewModel.session,
                    onPlayAgain: {
                        viewModel.resetGame()
                    },
                    onDismiss: {
                        onDismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }

            // Layer 4: Top overlay (close button + game stats)
            VStack {
                topOverlay
                Spacer()
            }

            // Layer 5: Heart lost animation (center screen)
            if viewModel.showHeartLostAnimation {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                HeartLostAnimation(
                    onComplete: {
                        viewModel.dismissHeartLostAnimation()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Set callbacks
            viewModel.onPlayAgain = {
                // Reset game with new session
                viewModel.resetGame()
            }
            viewModel.onDismiss = {
                // Close the game modal
                self.onDismiss()
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

    // MARK: - Top Overlay

    private var topOverlay: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Close button
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }

                Spacer()

                // Health bar (combo moved to floating card header)
                if viewModel.questionPhase != .gameOver && viewModel.questionPhase != .loading {
                    HealthBarView(currentHealth: viewModel.session.health)
                }

                // Help icon
                Button(action: {
                    showTutorialManually = true
                }) {
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
        .padding(.top, 56)
    }
}

struct GeoGameContainerView_Previews: PreviewProvider {
    static var previews: some View {
        GeoGameContainerView(
        initialGame: GeoGameDataService.mockGames[0],
        onComplete: { result in
        },
        onPlayAgain: {
        },
        onDismiss: {
        }
        )
    }
}
