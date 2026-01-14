//
//  BedroomListView.swift
//  Billix
//
//  Created by Claude Code on 1/14/26.
//  Interactive list view for bedroom statistics (replaces card grid)
//

import SwiftUI

struct BedroomListView: View {
    let stats: [BedroomStats]
    let selectedBedroomTypes: Set<BedroomType>
    let onBedroomTap: (BedroomType) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(stats) { stat in
                let bedroomType = mapBedroomCountToType(stat.bedroomCount)
                let isSelected = selectedBedroomTypes.contains(bedroomType)

                Button {
                    onBedroomTap(bedroomType)
                } label: {
                    HStack(spacing: 12) {
                        // Color dot indicator
                        Circle()
                            .fill(bedroomType.chartColor)
                            .frame(width: 12, height: 12)

                        // Label
                        Text(bedroomType.displayName)
                            .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(.primary)

                        Spacer()

                        // Price and trend (right-aligned)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(Int(stat.averageRent))/mo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            // Change indicator
                            HStack(spacing: 4) {
                                Image(systemName: stat.rentChange >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 11))
                                Text("\(abs(stat.rentChange), specifier: "%.1f")%")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(stat.rentChange >= 0 ? .billixMoneyGreen : .billixStreakOrange)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? bedroomType.chartColor.opacity(0.08) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                // Divider (except for last item)
                if stat != stats.last {
                    Divider()
                        .padding(.leading, 40)  // Indent to align with text
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
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
