//
//  BedroomBreakdownGrid.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  2x3 grid of bedroom statistics for Market Trends
//

import SwiftUI

struct BedroomBreakdownGrid: View {
    let stats: [BedroomStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(stats) { stat in
                    BedroomStatCard(stat: stat)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Bedroom Breakdown Grid") {
    BedroomBreakdownGrid(
        stats: [
            BedroomStats(bedroomCount: 0, averageRent: 826, rentChange: -2.9, sampleSize: 45),
            BedroomStats(bedroomCount: 1, averageRent: 792, rentChange: 21.6, sampleSize: 67),
            BedroomStats(bedroomCount: 2, averageRent: 1258, rentChange: 8.9, sampleSize: 89),
            BedroomStats(bedroomCount: 3, averageRent: 1349, rentChange: -8.9, sampleSize: 54),
            BedroomStats(bedroomCount: 4, averageRent: 1900, rentChange: 29.8, sampleSize: 32),
            BedroomStats(bedroomCount: 5, averageRent: 2317, rentChange: -17.3, sampleSize: 18)
        ]
    )
    .padding()
    .background(Color.billixCreamBeige)
}
