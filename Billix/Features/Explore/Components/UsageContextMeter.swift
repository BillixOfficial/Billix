//
//  UsageContextMeter.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Usage level indicator (Low/Med/High) for bill comparison
//

import SwiftUI

/// Usage level for bills
enum UsageLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .billixMoneyGreen
        case .medium: return .billixGoldenAmber
        case .high: return .billixStreakOrange
        }
    }

    var fillPercentage: CGFloat {
        switch self {
        case .low: return 0.33
        case .medium: return 0.66
        case .high: return 1.0
        }
    }

    var icon: String {
        switch self {
        case .low: return "leaf.fill"
        case .medium: return "gauge.medium"
        case .high: return "flame.fill"
        }
    }
}

/// Visual meter showing usage context (Low/Med/High)
struct UsageContextMeter: View {

    // MARK: - Properties

    let level: UsageLevel
    let showLabel: Bool

    // MARK: - Initialization

    init(level: UsageLevel, showLabel: Bool = true) {
        self.level = level
        self.showLabel = showLabel
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: level.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(level.color)

            // Meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(level.color)
                        .frame(
                            width: geometry.size.width * level.fillPercentage,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Label
            if showLabel {
                Text(level.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(level.color)
                    .frame(width: 60, alignment: .leading)
            }
        }
    }
}

// MARK: - Compact Variant

/// Compact usage meter (icon + bar only)
struct CompactUsageMeter: View {
    let level: UsageLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(level.color)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(level.color)
                        .frame(
                            width: geometry.size.width * level.fillPercentage,
                            height: 6
                        )
                }
            }
            .frame(width: 50, height: 6)
        }
    }
}

// MARK: - Previews

struct UsageContextMeter_Usage_Context_Meter___All_Levels_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 12) {
        Text("Standard Meters")
        .font(.headline)
        
        UsageContextMeter(level: .low)
        UsageContextMeter(level: .medium)
        UsageContextMeter(level: .high)
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("Without Labels")
        .font(.headline)
        
        UsageContextMeter(level: .low, showLabel: false)
        UsageContextMeter(level: .medium, showLabel: false)
        UsageContextMeter(level: .high, showLabel: false)
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("Compact Variant")
        .font(.headline)
        
        CompactUsageMeter(level: .low)
        CompactUsageMeter(level: .medium)
        CompactUsageMeter(level: .high)
        }
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}

struct UsageContextMeter_Usage_Meter___In_Card_Context_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        // Simulated bill card
        VStack(alignment: .leading, spacing: 12) {
        Text("DTE Energy")
        .font(.headline)
        
        Text("Electric • Residential")
        .font(.caption)
        .foregroundColor(.secondary)
        
        UsageContextMeter(level: .medium)
        
        Text("$145 - $165")
        .font(.title3)
        .bold()
        }
        .padding()
        .background(
        RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(radius: 4)
        )
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
