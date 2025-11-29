//
//  GeoGameResultView.swift
//  Billix
//
//  Created by Claude Code
//  Final results screen with score breakdown
//

import SwiftUI

struct GeoGameResultView: View {

    @ObservedObject var viewModel: GeoGameViewModel
    @State private var showBreakdown: Bool = false
    @State private var animatedPoints: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            // Animated point count
            VStack(spacing: 4) {
                Text("\(animatedPoints)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
                    .contentTransition(.numericText())

                Text("POINTS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Score breakdown
            if showBreakdown {
                VStack(spacing: 12) {
                    PointRow(
                        icon: "checkmark.circle.fill",
                        label: "Location ID",
                        points: viewModel.gameState.phase1Points
                    )
                    .transition(.opacity.combined(with: .offset(y: -10)))

                    PointRow(
                        icon: "dollarsign.circle.fill",
                        label: "Price Estimate",
                        points: viewModel.gameState.phase2Points
                    )
                    .transition(.opacity.combined(with: .offset(y: -10)))
                    .delay(0.1)
                }
            }

            Divider()
                .padding(.vertical, 8)

            // Price comparison
            VStack(spacing: 12) {
                Text("Actual Price")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(formatPrice(viewModel.gameData.actualPrice))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                if let guess = viewModel.gameState.priceGuess {
                    HStack(spacing: 6) {
                        Text("Your Guess:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text(formatPrice(guess))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("·")
                            .foregroundColor(.secondary)

                        if let accuracy = viewModel.accuracyDescription {
                            Text(accuracy)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                }
            }

            // Economic context
            if let context = viewModel.gameData.economicContext {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.billixArcadeGold)

                    Text(context)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(16)
                .background(Color.billixArcadeGold.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()
                .frame(maxHeight: 40)

            // Action buttons
            VStack(spacing: 12) {
                // Play Again button
                Button(action: {
                    viewModel.onPlayAgain?()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("PLAY AGAIN")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(12)
                }

                // Done button
                Button(action: {
                    viewModel.completeGame()
                }) {
                    Text("DONE")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.billixMoneyGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.billixMoneyGreen.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .onAppear {
            animateResults()
        }
    }

    // MARK: - Animation

    private func animateResults() {
        // Delay before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Animate point count-up
            let totalPoints = viewModel.gameState.totalPoints
            let duration: TimeInterval = 1.2
            let steps = 30
            let increment = totalPoints / steps

            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(i)) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        animatedPoints = min(increment * i, totalPoints)
                    }
                }
            }

            // Show breakdown after count-up
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showBreakdown = true
                }
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                generator.impactOccurred()
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if viewModel.gameData.category == .rent {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}

// MARK: - Point Row

struct PointRow: View {

    let icon: String
    let label: String
    let points: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.billixMoneyGreen)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text("+\(points)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.billixMoneyGreen)
        }
    }
}

// MARK: - View Extension for Delays

extension View {
    func delay(_ delay: Double) -> some View {
        self.modifier(DelayModifier(delay: delay))
    }
}

struct DelayModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation {
                        isVisible = true
                    }
                }
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
                    vm.gameState.phase1Points = 500
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
