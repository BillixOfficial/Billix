//
//  UpcomingEstimatesZone.swift
//  Billix
//

import SwiftUI

// MARK: - Upcoming Estimates Zone

struct UpcomingEstimatesZone: View {
    let zipCode: String

    @State private var estimates: [UpcomingEstimate] = []
    @State private var isLoading = true

    @StateObject private var weatherService = WeatherService.shared
    private let openAIService = OpenAIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16))
                    .foregroundColor(HomeTheme.info)
                Text("Upcoming").sectionHeader()

                Spacer()

                Text("Next 30 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HomeTheme.secondaryText)
            }

            VStack(spacing: 0) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 30)
                        Spacer()
                    }
                } else if estimates.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: HomeTheme.iconLarge))
                            .foregroundColor(HomeTheme.secondaryText.opacity(0.5))
                        Text("Predictions loading...")
                            .font(.system(size: 13))
                            .foregroundColor(HomeTheme.secondaryText)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(estimates.enumerated()), id: \.offset) { index, estimate in
                        UpcomingEstimateRow(estimate: estimate)

                        if index < estimates.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .padding(14)
            .background(HomeTheme.cardBackground)
            .cornerRadius(HomeTheme.cornerRadius)
            .shadow(color: HomeTheme.shadowColor, radius: HomeTheme.shadowRadius, x: 0, y: 2)

            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Based on regional patterns for \(zipCode)")
                    .font(.system(size: 11))
            }
            .foregroundColor(HomeTheme.secondaryText.opacity(0.7))
        }
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .task {
            await loadEstimates()
        }
    }

    @MainActor
    private func loadEstimates() async {
        isLoading = true

        let weather = weatherService.currentWeather

        do {
            estimates = try await openAIService.generateUpcomingEstimates(
                zipCode: zipCode,
                city: weather?.cityName,
                state: nil,
                temperature: weather?.temperature,
                weatherCondition: weather?.condition,
                weatherForecast: nil,
                billCategories: ["Electric", "Gas", "Internet", "Water"]
            )
        } catch {
            print("❌ Error: Failed to load upcoming estimates: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Upcoming Estimate Row

struct UpcomingEstimateRow: View {
    let estimate: UpcomingEstimate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: estimate.icon)
                .font(.system(size: HomeTheme.iconSmall))
                .foregroundColor(HomeTheme.info)
                .frame(width: 36, height: 36)
                .background(HomeTheme.info.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HomeTheme.primaryText)
                    .lineLimit(2)
                Text(estimate.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(HomeTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
