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

    init(initialGame: DailyGame, onComplete: @escaping (GameResult) -> Void, onPlayAgain: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.initialGame = initialGame
        self.onComplete = onComplete
        self.onPlayAgain = onPlayAgain
        self.onDismiss = onDismiss
        _currentGameId = State(initialValue: initialGame.id)

        // Initialize view model with completion handler
        _viewModel = StateObject(wrappedValue: GeoGameViewModel(
            gameData: initialGame,
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            // Layer 1: Full-screen 3D satellite map (always visible, orbiting)
            GeoGameMapView(viewModel: viewModel)

            // Layer 2: Floating card at bottom
            VStack {
                Spacer()
                GeoGameFloatingCard(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Layer 3: Top overlay (close button + phase indicator)
            VStack {
                topOverlay
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Set callbacks
            viewModel.onPlayAgain = {
                // Call the external play again handler to get new game
                self.onPlayAgain()
            }
            viewModel.onDismiss = {
                // Close the game modal
                self.onDismiss()
            }
        }
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        HStack {
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

            // Phase indicator
            if viewModel.gameState.phase != .loading && viewModel.gameState.phase != .result {
                phaseIndicator
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)  // Account for status bar
    }

    private var phaseIndicator: some View {
        HStack(spacing: 6) {
            Text("Phase")
                .font(.system(size: 13, weight: .medium))
            Text("\(currentPhaseNumber) of 2")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
    }

    private var currentPhaseNumber: Int {
        switch viewModel.gameState.phase {
        case .phase1Location, .transition:
            return 1
        case .phase2Price:
            return 2
        default:
            return 1
        }
    }
}

#Preview {
    GeoGameContainerView(
        initialGame: GeoGameDataService.mockGames[0],
        onComplete: { result in
            print("Game completed with \(result.pointsEarned) points")
        },
        onPlayAgain: {
            print("Play again tapped")
        },
        onDismiss: {
            print("Dismiss tapped")
        }
    )
}
