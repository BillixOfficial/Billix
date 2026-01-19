//
//  BedroomListView.swift
//  Billix
//
//  Created by Claude Code on 1/14/26.
//  Horizontal grid for bedroom statistics (stock chart style)
//

import SwiftUI

struct BedroomListView: View {
    let stats: [BedroomStats]
    let selectedBedroomTypes: Set<BedroomType>
    let onBedroomTap: (BedroomType) -> Void

    // 3-column grid layout (like Open | High | Low)
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(stats) { stat in
                let bedroomType = mapBedroomCountToType(stat.bedroomCount)
                let isSelected = selectedBedroomTypes.contains(bedroomType)

                Button {
                    onBedroomTap(bedroomType)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        // Label with color dot
                        HStack(spacing: 6) {
                            Circle()
                                .fill(bedroomType.chartColor)
                                .frame(width: 8, height: 8)

                            Text(bedroomType.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        // Price (large)
                        Text("$\(Int(stat.averageRent))/mo")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        // Change indicator
                        HStack(spacing: 3) {
                            Image(systemName: stat.rentChange >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 9))
                            Text("\(abs(stat.rentChange), specifier: "%.1f")%")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(stat.rentChange >= 0 ? .billixMoneyGreen : .billixStreakOrange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 72)  // Fixed height for all cards
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? bedroomType.chartColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
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
        default: return .studio
        }
    }
}
