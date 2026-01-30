//
//  FuzzyRangeBar.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Gradient price range visualizer with blur interaction (hold to reveal)
//

import SwiftUI

/// Fuzzy range bar with blur interaction - privacy-first price visualization
struct FuzzyRangeBar: View {

    // MARK: - Properties

    let minPrice: Double
    let maxPrice: Double
    let highlightMin: Double
    let highlightMax: Double
    let totalRange: ClosedRange<Double>

    @GestureState private var isDetectingLongPress = false
    @State private var isRevealed = false
    @State private var showHint = true

    // MARK: - Computed Properties

    private var normalizedHighlightStart: CGFloat {
        CGFloat((highlightMin - totalRange.lowerBound) / (totalRange.upperBound - totalRange.lowerBound))
    }

    private var normalizedHighlightEnd: CGFloat {
        CGFloat((highlightMax - totalRange.lowerBound) / (totalRange.upperBound - totalRange.lowerBound))
    }

    private var highlightWidth: CGFloat {
        normalizedHighlightEnd - normalizedHighlightStart
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Range Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient (full range)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.billixChartBlue.opacity(0.2),
                                    Color.billixMoneyGreen.opacity(0.2),
                                    Color.billixStreakOrange.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 40)

                    // Highlighted range
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.billixMoneyGreen.opacity(0.6),
                                    Color.billixMoneyGreen.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * highlightWidth,
                            height: 40
                        )
                        .offset(x: geometry.size.width * normalizedHighlightStart)

                    // Price labels (overlay on bar)
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Text("$\(Int(highlightMin)) - $\(Int(highlightMax))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        Spacer()
                    }
                }
                .blur(radius: isRevealed ? 0 : 8)
                .drawingGroup() // GPU acceleration for blur
            }
            .frame(height: 40)

            // Range indicators
            HStack {
                Text("$\(Int(totalRange.lowerBound))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .blur(radius: isRevealed ? 0 : 4)

                Spacer()

                Text("$\(Int(totalRange.upperBound))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .blur(radius: isRevealed ? 0 : 4)
            }

            // Privacy hint
            if showHint && !isRevealed {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12))
                    Text("Hold to reveal range")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.billixPurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.billixPurple.opacity(0.1))
                )
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .updating($isDetectingLongPress) { value, state, _ in
                    state = value
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isRevealed = true
                        showHint = false
                    }

                    // Auto-hide after 2s
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isRevealed = false
                        }
                    }
                }
        )
        .onAppear {
            // Hide hint after 3 seconds if not interacted
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showHint = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Fuzzy Range Bar - Blurred") {
    VStack(spacing: 30) {
        FuzzyRangeBar(
            minPrice: 100,
            maxPrice: 200,
            highlightMin: 140,
            highlightMax: 160,
            totalRange: 80...220
        )
        .padding()

        Text("Hold the bar to reveal")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .background(Color.billixCreamBeige)
}

#Preview("Fuzzy Range Bar - Multiple") {
    ScrollView {
        VStack(spacing: 30) {
            // Electric bill range
            VStack(alignment: .leading, spacing: 8) {
                Text("Electric Bill")
                    .font(.headline)
                FuzzyRangeBar(
                    minPrice: 120,
                    maxPrice: 180,
                    highlightMin: 145,
                    highlightMax: 165,
                    totalRange: 100...200
                )
            }

            // Water bill range
            VStack(alignment: .leading, spacing: 8) {
                Text("Water Bill")
                    .font(.headline)
                FuzzyRangeBar(
                    minPrice: 40,
                    maxPrice: 80,
                    highlightMin: 55,
                    highlightMax: 70,
                    totalRange: 30...100
                )
            }

            // Gas bill range
            VStack(alignment: .leading, spacing: 8) {
                Text("Gas Bill")
                    .font(.headline)
                FuzzyRangeBar(
                    minPrice: 60,
                    maxPrice: 140,
                    highlightMin: 85,
                    highlightMax: 110,
                    totalRange: 50...160
                )
            }
        }
        .padding()
    }
    .background(Color.billixCreamBeige)
}
