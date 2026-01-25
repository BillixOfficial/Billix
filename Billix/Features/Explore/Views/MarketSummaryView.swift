//
//  MarketSummaryView.swift
//  Billix
//
//  Stub implementation - actual component is in Components/MarketTrends/

import SwiftUI

struct MarketSummaryView: View {
    let marketData: MarketTrendsData
    let marketHealth: MarketHealth

    var body: some View {
        VStack(spacing: 16) {
            Text("Market Summary")
                .font(.headline)

            Text("Coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
