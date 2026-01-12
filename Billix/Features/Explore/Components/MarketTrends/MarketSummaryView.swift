//
//  MarketSummaryView.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Summary tab content combining market health, stats, and description
//

import SwiftUI

struct MarketSummaryView: View {
    let marketData: MarketTrendsData
    let marketHealth: MarketHealth

    var body: some View {
        VStack(spacing: 16) {
            // Market health indicator
            MarketHealthCard(health: marketHealth)

            // Price range stats
            PriceRangeStatsCard(
                lowRent: marketData.lowRent,
                averageRent: marketData.averageRent,
                highRent: marketData.highRent
            )

            // Textual summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Market Overview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(marketSummaryText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    private var marketSummaryText: String {
        let changeDirection = marketData.yearOverYearChange >= 0 ? "increased" : "decreased"
        let changeAmount = abs(marketData.yearOverYearChange)

        return """
        The average rent in \(marketData.location) is $\(Int(marketData.averageRent))/mo, \
        which has \(changeDirection) by \(String(format: "%.1f", changeAmount))% over the past year. \
        Rent prices range from $\(Int(marketData.lowRent)) to $\(Int(marketData.highRent)), \
        reflecting a diverse housing market with options across multiple price points.
        """
    }
}

// MARK: - Preview

#Preview("Market Summary View - Hot Market") {
    MarketSummaryView(
        marketData: MarketTrendsMockData.generateMarketData(location: "Brooklyn, NY"),
        marketHealth: .hot
    )
    .padding(20)
    .background(Color.billixCreamBeige)
}

#Preview("Market Summary View - Cool Market") {
    let mockData = MarketTrendsData(
        location: "Detroit, MI",
        averageRent: 980,
        rentChange12Month: -4.2,
        lowRent: 450,
        highRent: 2200,
        bedroomStats: [],
        lastUpdated: Date()
    )

    MarketSummaryView(
        marketData: mockData,
        marketHealth: .cool
    )
    .padding(20)
    .background(Color.billixCreamBeige)
}
