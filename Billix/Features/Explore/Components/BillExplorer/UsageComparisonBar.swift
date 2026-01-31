//
//  UsageComparisonBar.swift
//  Billix
//
//  Dual comparison bar showing usage vs area average and min-max range
//

import SwiftUI

struct UsageComparisonBar: View {
    let userValue: Double
    let areaAverage: Double
    let areaMin: Double
    let areaMax: Double
    let unit: String
    let valuePrefix: String  // "$" for money, "" for usage
    var stateCode: String = ""  // e.g., "MI" - if provided, shows "MI Avg" instead of "Area Avg"

    // Computed properties
    private var avgLabel: String {
        stateCode.isEmpty ? "Billix Avg" : "Billix \(stateCode) Avg"
    }

    private var rangeLabel: String {
        stateCode.isEmpty ? "Billix Range" : "Billix \(stateCode) Range"
    }

    private var percentageDiff: Double {
        guard areaAverage > 0 else { return 0 }
        return ((userValue - areaAverage) / areaAverage) * 100
    }

    private var comparisonColor: Color {
        if percentageDiff < -10 {
            return Color(hex: "#4CAF7A")  // Green - significantly below
        } else if percentageDiff > 10 {
            return Color(hex: "#E07A6B")  // Red - significantly above
        } else {
            return Color(hex: "#F5A623")  // Amber - around average
        }
    }

    private var comparisonText: String {
        let absDiff = abs(Int(percentageDiff))
        let avgText = stateCode.isEmpty ? "Billix average" : "Billix \(stateCode) average"
        if percentageDiff < -5 {
            return "\(absDiff)% below \(avgText)"
        } else if percentageDiff > 5 {
            return "\(absDiff)% above \(avgText)"
        } else {
            return "Around \(avgText)"
        }
    }

    private var userPosition: CGFloat {
        guard areaMax > areaMin else { return 0.5 }
        return CGFloat((userValue - areaMin) / (areaMax - areaMin))
    }

    private var avgPosition: CGFloat {
        guard areaMax > areaMin else { return 0.5 }
        return CGFloat((areaAverage - areaMin) / (areaMax - areaMin))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("USAGE COMPARISON")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#8B9A94"))
                .tracking(0.5)

            // Primary comparison bar (You vs Average)
            VStack(alignment: .leading, spacing: 8) {
                // Labels
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))
                        Text("\(valuePrefix)\(formatValue(userValue)) \(unit)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(avgLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))
                        Text("\(valuePrefix)\(formatValue(areaAverage)) \(unit)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#5A6B64"))
                    }
                }

                // Comparison bar
                GeometryReader { geometry in
                    let barWidth = geometry.size.width
                    let userPos = min(max(userPosition, 0), 1) * barWidth
                    let avgPos = min(max(avgPosition, 0), 1) * barWidth

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#E5E9E7"))
                            .frame(height: 8)

                        // Fill to user position
                        RoundedRectangle(cornerRadius: 4)
                            .fill(comparisonColor)
                            .frame(width: userPos, height: 8)

                        // Average marker
                        Circle()
                            .fill(Color(hex: "#5A6B64"))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: avgPos - 6)

                        // User marker (on top)
                        Circle()
                            .fill(comparisonColor)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: comparisonColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(x: userPos - 7)
                    }
                }
                .frame(height: 14)

                // Comparison result
                HStack(spacing: 6) {
                    Image(systemName: percentageDiff < -5 ? "checkmark.circle.fill" : (percentageDiff > 5 ? "exclamationmark.circle.fill" : "equal.circle.fill"))
                        .font(.system(size: 14))
                        .foregroundColor(comparisonColor)

                    Text(comparisonText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(comparisonColor)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value < 1 {
            return String(format: "%.3f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Below average (good)
        UsageComparisonBar(
            userValue: 892,
            areaAverage: 1200,
            areaMin: 400,
            areaMax: 2500,
            unit: "kWh",
            valuePrefix: ""
        )

        // Above average (concerning)
        UsageComparisonBar(
            userValue: 185,
            areaAverage: 120,
            areaMin: 45,
            areaMax: 320,
            unit: "",
            valuePrefix: "$"
        )

        // Around average
        UsageComparisonBar(
            userValue: 48,
            areaAverage: 50,
            areaMin: 25,
            areaMax: 85,
            unit: "therms",
            valuePrefix: ""
        )
    }
    .padding(20)
    .background(Color(hex: "#F7F9F8"))
}
