//
//  GeoGameResultView.swift
//  Billix
//
//  Created by Claude Code
//  Simple feedback screen matching landmark style
//

import SwiftUI

struct GeoGameResultView: View {

    @ObservedObject var viewModel: GeoGameViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Success or failure feedback box (matching landmark style)
            feedbackBox

            // Continue button
            Button(action: {
                viewModel.advanceToNextQuestion()
            }) {
                HStack {
                    Text("CONTINUE")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.didLoseHealthOnPrice ? Color.red : Color.billixMoneyGreen)
                .cornerRadius(12)
            }
        }
        .padding(24)
    }

    // MARK: - Feedback Box

    private var feedbackBox: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: viewModel.didLoseHealthOnPrice ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.didLoseHealthOnPrice ? .red : .billixMoneyGreen)

                VStack(alignment: .leading, spacing: 4) {
                    // Main message
                    Text(viewModel.didLoseHealthOnPrice ? "WAY OFF!" : feedbackMessage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.didLoseHealthOnPrice ? .red : .primary)

                    // Actual vs Guess
                    if let question = viewModel.currentQuestion,
                       let guess = viewModel.gameState.priceGuess {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Your guess:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Text(formatPrice(guess, category: question.category))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            HStack(spacing: 6) {
                                Text("Actual price:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Text(formatPrice(question.actualPrice, category: question.category))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.didLoseHealthOnPrice ? .red : .billixMoneyGreen)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background((viewModel.didLoseHealthOnPrice ? Color.red : Color.billixMoneyGreen).opacity(0.1))
            .cornerRadius(12)

            // Points earned (only if didn't lose heart)
            if !viewModel.didLoseHealthOnPrice {
                HStack {
                    Text("+\(viewModel.gameState.phase2Points) points")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)
                    Spacer()
                }
            } else {
                HStack {
                    Text("You lost a heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private var feedbackMessage: String {
        guard let accuracy = viewModel.accuracyDescription else { return "GREAT GUESS!" }

        if accuracy.contains("Bullseye") {
            return "BULLSEYE!"
        } else if accuracy.contains("Close") {
            return "CLOSE!"
        } else {
            return "NICE!"
        }
    }

    private func formatPrice(_ price: Double, category: GameCategory) -> String {
        if category == .rent || category == .utility {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            GeoGameResultView(
                viewModel: {
                    let vm = GeoGameViewModel(gameData: GeoGameDataService.mockGames[0])
                    vm.gameState.phase2Points = 600
                    vm.gameState.priceGuess = 4.25
                    vm.gameState.phase = .result
                    return vm
                }()
            )
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding()
        }
    }
}
