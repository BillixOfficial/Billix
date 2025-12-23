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
        VStack(spacing: 10) {
            // Question split into 2 lines (Item + Location)
            if let question = viewModel.currentQuestion {
                VStack(spacing: 4) {
                    // Line 1: The Item (Product) - Bold, prominent
                    Text(question.subject)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    // Line 2: The Location (Context) - Lighter, secondary
                    Text("in \(question.location)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // MASSIVE price display - the hero of this view
            Text(viewModel.formattedGuess)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.billixMoneyGreen)
                .contentTransition(.numericText())
                .scaleEffect(viewModel.isDraggingSlider ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: viewModel.isDraggingSlider)

            // Custom Slider (Edge-to-edge with minimal padding for wider feel)
            CustomPriceSlider(
                value: $viewModel.sliderValue,
                isDragging: $viewModel.isDraggingSlider
            )
            .frame(height: 32)
            .padding(.horizontal, 4)

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

            // Lock in button (with safe margin above)
            Button(action: {
                viewModel.submitPriceGuess()
            }) {
                Text("LOCK IT IN")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.billixMoneyGreen)
                    .cornerRadius(12)
            }
            .padding(.top, 16)

            // Safe area spacer for home indicator (50px clearance: 34px home bar + 16px padding)
            Spacer()
                .frame(height: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
    @Binding var isDragging: Bool  // Changed from @State to @Binding to communicate with parent

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background (thicker for better touch target)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                // Filled track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.billixMoneyGreen)
                    .frame(width: geometry.size.width * value, height: 12)

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
