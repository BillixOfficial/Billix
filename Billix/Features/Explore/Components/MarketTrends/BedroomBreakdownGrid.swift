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
    let selectedBedroomTypes: Set<BedroomType>
    let onBedroomTap: (BedroomType) -> Void

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
                    let bedroomType = mapBedroomCountToType(stat.bedroomCount)

                    BedroomStatCard(
                        stat: stat,
                        bedroomType: bedroomType,
                        isSelected: selectedBedroomTypes.contains(bedroomType),
                        onTap: { onBedroomTap(bedroomType) }
                    )
                }
            }
        }
    }

    private func mapBedroomCountToType(_ count: Int) -> BedroomType {
        switch count {
        case 0: return .studio
        case 1: return .oneBed
        case 2: return .twoBed
        case 3: return .threeBed
        case 4: return .fourBed
        case 5: return .fiveBed
        default: return .average
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
        ],
        selectedBedroomTypes: [.studio, .twoBed],
        onBedroomTap: { type in
            print("Tapped: \(type.rawValue)")
        }
    )
    .padding()
    .background(Color.billixCreamBeige)
}
