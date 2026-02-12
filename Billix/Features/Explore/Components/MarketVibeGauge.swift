//
//  MarketVibeGauge.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Custom gauge showing housing market trend (cooling/heating/neutral)
//

import SwiftUI

/// Housing market trend indicator
enum HousingMarketTrend {
    case cooling    // < -5% change
    case neutral    // -5% to +5% change
    case heating    // > +5% change

    var emoji: String {
        switch self {
        case .cooling: return "❄️"
        case .neutral: return "🌡️"
        case .heating: return "🔥"
        }
    }

    var text: String {
        switch self {
        case .cooling: return "Cooling Down"
        case .neutral: return "Steady"
        case .heating: return "Heating Up"
        }
    }

    var color: Color {
        switch self {
        case .cooling: return .billixChartBlue
        case .neutral: return .billixGoldenAmber
        case .heating: return .billixStreakOrange
        }
    }

    var progress: CGFloat {
        switch self {
        case .cooling: return 0.25
        case .neutral: return 0.5
        case .heating: return 0.75
        }
    }
}

/// Market vibe gauge component for housing marketplace
struct MarketVibeGauge: View {

    // MARK: - Properties

    let trend: HousingMarketTrend
    let metro: String
    let avgRent: Double
    let availability: Int
    let newToday: Int

    @State private var animatedProgress: CGFloat = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Gauge circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 140, height: 140)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [trend.color.opacity(0.6), trend.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // Center emoji and label
                VStack(spacing: 4) {
                    Text(trend.emoji)
                        .font(.system(size: 40))

                    Text(trend.text)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(trend.color)
                }
            }

            // Location label
            Text(metro)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)

            // Stats grid
            HStack(spacing: 24) {
                StatPill(
                    label: "Avg Rent",
                    value: "$\(Int(avgRent))/mo",
                    color: trend.color
                )

                StatPill(
                    label: "Available",
                    value: "\(availability)",
                    color: .billixMoneyGreen
                )

                StatPill(
                    label: "New Today",
                    value: "+\(newToday)",
                    color: .billixGoldenAmber
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = trend.progress
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Previews

struct MarketVibeGauge_Market_Vibe_Gauge___All_Trends_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
        VStack(spacing: 30) {
        MarketVibeGauge(
        trend: .cooling,
        metro: "Metro Detroit",
        avgRent: 1650,
        availability: 234,
        newToday: 12
        )
        
        MarketVibeGauge(
        trend: .neutral,
        metro: "Greater Chicago",
        avgRent: 1900,
        availability: 456,
        newToday: 23
        )
        
        MarketVibeGauge(
        trend: .heating,
        metro: "San Francisco Bay Area",
        avgRent: 3200,
        availability: 89,
        newToday: 5
        )
        }
        .padding()
        }
        .background(Color.billixCreamBeige)
    }
}

struct MarketVibeGauge_Market_Vibe_Gauge___Single_Previews: PreviewProvider {
    static var previews: some View {
        MarketVibeGauge(
        trend: .cooling,
        metro: "Metro Detroit",
        avgRent: 1650,
        availability: 234,
        newToday: 12
        )
        .padding()
        .background(Color.billixCreamBeige)
    }
}
