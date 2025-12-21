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
    @State private var isExpanded: Bool = true
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Pill badge positioned at top edge like a tab/handle
            expandCollapsePill

            // Always-visible content (both collapsed and expanded states)
            VStack(spacing: 12) {
                // Question
                Text("Where is the landmark located?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                // Hint
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMoneyGreen)

                    Text("Explore map • Tap Landmark to recenter")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
            .padding(.top, isExpanded ? 16 : 12)

            // ONLY when expanded - options, button, feedback
            if isExpanded {
                // 2x2 Grid of location choices
                locationGrid
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 12)

                // Submit button (appears when selection is made)
                if viewModel.selectedChoice != nil {
                    submitButton
                        .transition(.opacity.combined(with: .offset(y: 10)))
                        .padding(.top, 12)
                }

                // Result feedback (appears after submission)
                if viewModel.gameState.phase == .transition {
                    resultFeedback
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 12)
                } else if !viewModel.gameState.isLocationCorrect && viewModel.gameState.selectedLocation != nil {
                    // Show wrong answer feedback with continue button
                    wrongAnswerFeedback
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 12)
                }

                Color.clear.frame(height: 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, isExpanded ? 16 : 8)  // Minimal padding when collapsed
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.selectedChoice)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.gameState.phase)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward drag to collapse
                    if value.translation.height > 0 && isExpanded {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 50 && isExpanded {
                        // Swipe down threshold reached - collapse
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    dragOffset = 0
                }
        )
    }

    // MARK: - Expand/Collapse Pill Badge

    private var expandCollapsePill: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Text(pillLabel)
                    .font(.system(size: 13, weight: .bold))

                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .offset(y: 0)  // No offset - align with top edge
    }

    private var pillLabel: String {
        return isExpanded ? "Collapse" : "Show options"
    }

    // MARK: - Location Grid

    private var locationGrid: some View {
        let rows = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        // Disable all buttons if they've already submitted an answer
        let hasSubmitted = viewModel.gameState.selectedLocation != nil

        return LazyVGrid(columns: rows, spacing: 12) {
            ForEach(viewModel.locationChoices) { choice in
                LocationChoiceButton(
                    choice: choice,
                    isSelected: viewModel.selectedChoice == choice.displayLabel,
                    isIncorrect: viewModel.gameState.incorrectChoice == choice.displayLabel,
                    isDisabled: hasSubmitted,
                    action: {
                        viewModel.selectLocation(choice.displayLabel)
                    }
                )
            }
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: {
            viewModel.submitLocationGuess()
        }) {
            Text("SUBMIT ANSWER")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.billixMoneyGreen)
                .cornerRadius(12)
        }
    }

    // MARK: - Result Feedback

    private var resultFeedback: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.billixMoneyGreen)
                .cornerRadius(12)
            }
        }
    }

    private var wrongAnswerFeedback: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
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

            // Show Continue button (if still have health)
            if viewModel.session.health > 0 {
                Button(action: {
                    viewModel.continueAfterWrongAnswer()
                }) {
                    HStack {
                        Text("CONTINUE")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(12)
                }
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
            VStack(spacing: 8) {
                // Large label (A, B, C, D)
                Text(choice.displayLabel)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isIncorrect ? .gray : (isSelected ? .billixMoneyGreen : .primary))

                // City name
                Text(choice.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isIncorrect ? .gray.opacity(0.5) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
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
