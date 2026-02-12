//
//  MetricCardView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Reusable metric card for displaying key bill metrics in a grid
struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let backgroundColor: Color

    @State private var appeared = false

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = .billixChartBlue,
        backgroundColor: Color = .white
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.billixDarkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.billixLightGreenText)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Savings Card Variant

struct SavingsMetricCard: View {
    let savings: Double

    @State private var animatedValue: Double = 0
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon with pulse effect
            ZStack {
                Circle()
                    .fill(Color.billixSavingsYellow.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixSavingsYellow)
            }

            Spacer()

            // Animated value
            Text("$\(Int(animatedValue))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.billixMoneyGreen)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 2) {
                Text("Potential Savings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                Text("per month")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.billixLightGreenText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
            // Animate the number
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animatedValue = savings
            }
        }
    }
}

// MARK: - Health Score Card Variant

struct HealthScoreCard: View {
    let score: Int // 0-100
    let status: String // "Great", "Good", "Fair", "Poor"

    @State private var animatedProgress: Double = 0
    @State private var appeared = false

    var scoreColor: Color {
        switch score {
        case 80...100: return .billixMoneyGreen
        case 60..<80: return .billixChartBlue
        case 40..<60: return .billixSavingsYellow
        default: return .billixVotePink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color.billixBorderGreen, lineWidth: 4)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
            }

            Spacer()

            // Status text
            Text(status)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Bill Health")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                Text("Score: \(score)/100")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.billixLightGreenText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                animatedProgress = Double(score) / 100.0
            }
        }
    }
}

// MARK: - Preview

struct MetricCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        SavingsMetricCard(savings: 14.50)
        
        HealthScoreCard(score: 72, status: "Good")
        
        MetricCardView(
        title: "Provider",
        value: "DTE Energy",
        subtitle: "Electric",
        icon: "bolt.fill",
        iconColor: .billixChartBlue
        )
        
        MetricCardView(
        title: "Due Date",
        value: "Dec 15",
        subtitle: "19 days left",
        icon: "calendar",
        iconColor: .billixMoneyGreen
        )
        }
        .padding()
        }
        .background(Color.billixLightGreen)
    }
}
