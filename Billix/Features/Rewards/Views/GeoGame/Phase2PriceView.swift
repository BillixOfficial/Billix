//
//  Phase2PriceView.swift
//  Billix
//
//  Created by Claude Code
//  Phase 2: Price estimation with custom slider
//

import SwiftUI

struct Phase2PriceView: View {

    @ObservedObject var viewModel: GeoGameViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header with Phase 1 badge
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💰 PRICE CHECK")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)

                    Text("How much does it cost?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Phase 1 points badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("+\(viewModel.gameState.phase1Points)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.billixMoneyGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.billixMoneyGreen.opacity(0.15))
                .cornerRadius(20)
            }

            // Subject line
            if let question = viewModel.currentQuestion {
                Text("\(question.subject) in \(question.location)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Large price display
            Text(viewModel.formattedGuess)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.billixMoneyGreen)
                .contentTransition(.numericText())

            // Custom Slider
            CustomPriceSlider(value: $viewModel.sliderValue)
                .frame(height: 60)

            // Min/Max labels
            if let question = viewModel.currentQuestion {
                HStack {
                    Text(formatPrice(question.minGuess, category: question.category))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatPrice(question.maxGuess, category: question.category))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Lock in button
            Button(action: {
                viewModel.submitPriceGuess()
            }) {
                Text("LOCK IT IN")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(12)
            }
        }
        .padding(24)
    }

    private func formatPrice(_ price: Double, category: GameCategory) -> String {
        if category == .rent || category == .utility {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}

// MARK: - Custom Price Slider

struct CustomPriceSlider: View {

    @Binding var value: Double
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Filled track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.billixMoneyGreen)
                    .frame(width: geometry.size.width * value, height: 8)

                // Thumb
                Circle()
                    .fill(Color.billixMoneyGreen)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4)
                    .offset(x: (geometry.size.width - 32) * value)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }

                                let newValue = min(max(0, gesture.location.x / (geometry.size.width - 32)), 1.0)

                                // Haptic feedback every 5% change
                                let oldSteps = Int(value * 20)
                                let newSteps = Int(newValue * 20)
                                if oldSteps != newSteps {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }

                                value = newValue
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isDragging = false
                                }
                            }
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            Phase2PriceView(
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
