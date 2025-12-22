//
//  Phase1LocationView.swift
//  Billix
//
//  Created by Claude Code
//  Phase 1: Location identification with 2x2 grid
//

import SwiftUI

struct Phase1LocationView: View {

    @ObservedObject var viewModel: GeoGameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // 2x2 Grid of location choices
            locationGrid

            // Result feedback (appears after submission)
            // Show feedback based on phase (.transition is used for both correct and wrong answers)
            if viewModel.gameState.phase == .transition {
                if viewModel.gameState.isLocationCorrect {
                    resultFeedback
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 8)
                } else {
                    wrongAnswerFeedback
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 8)
                }

                // Safe area spacer ONLY when feedback is showing
                Spacer()
                    .frame(height: 30)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.selectedChoice)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.gameState.phase)
    }

    // MARK: - Location Grid

    private var locationGrid: some View {
        let rows = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]

        // Disable all buttons if they've already submitted OR if in feedback phase
        let hasSubmitted = viewModel.gameState.selectedLocation != nil
        let isInFeedbackPhase = (viewModel.gameState.phase == .transition)

        return LazyVGrid(columns: rows, spacing: 8) {
            ForEach(viewModel.locationChoices) { choice in
                LocationChoiceButton(
                    choice: choice,
                    isSelected: viewModel.selectedChoice == choice.displayLabel,
                    isIncorrect: viewModel.gameState.incorrectChoice == choice.displayLabel,
                    isDisabled: hasSubmitted || isInFeedbackPhase,
                    action: {
                        viewModel.selectLocation(choice.displayLabel)
                        // Auto-submit after 0.5s delay for visual feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !hasSubmitted && !isInFeedbackPhase {
                                viewModel.submitLocationGuess()
                            }
                        }
                    }
                )
            }
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Result Feedback

    private var resultFeedback: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.billixMoneyGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text("CORRECT!")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 6) {
                        Text("+\(viewModel.gameState.phase1Points) points")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)

                        if viewModel.gameState.isRetryAttempt {
                            Text("(retry)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.billixMoneyGreen.opacity(0.1))
            .cornerRadius(12)

            // Continue button
            Button(action: {
                viewModel.advanceToNextQuestion()
            }) {
                HStack {
                    Text("CONTINUE")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.billixMoneyGreen)
                .cornerRadius(12)
            }
        }
    }

    private var wrongAnswerFeedback: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("INCORRECT!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)

                    Text("The answer was \(viewModel.correctLocationName)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)

            // Continue button
            Button(action: {
                viewModel.continueAfterWrongAnswer()
            }) {
                HStack {
                    Text("CONTINUE")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Location Choice Button

struct LocationChoiceButton: View {

    let choice: DecoyLocation
    let isSelected: Bool
    let isIncorrect: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // City name (primary, bold, large)
                Text(choice.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isIncorrect ? .gray : (isSelected ? .billixMoneyGreen : .primary))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Small label (A, B, C, D - secondary, grey, small)
                Text(choice.displayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isIncorrect ? .gray.opacity(0.5) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isIncorrect ? Color.gray.opacity(0.1) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isIncorrect ? Color.gray.opacity(0.3) : (isSelected ? Color.billixMoneyGreen : Color.gray.opacity(0.2)),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isIncorrect || isDisabled)
        .opacity((isIncorrect || isDisabled) ? 0.5 : 1.0)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            Phase1LocationView(
                viewModel: GeoGameViewModel(
                    gameData: GeoGameDataService.mockGames[0]
                )
            )
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding()
        }
    }
}
