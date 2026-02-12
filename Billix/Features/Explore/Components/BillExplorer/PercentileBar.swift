//
//  PercentileBar.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Progress bar showing bill percentile comparison
//

import SwiftUI

struct PercentileBar: View {
    let percentile: Int  // 0-100

    private var fillColor: Color {
        if percentile <= 30 {
            return Color(hex: "#10B981")  // Green - low/good
        } else if percentile >= 70 {
            return Color(hex: "#EF4444")  // Red - high
        } else {
            return Color(hex: "#F59E0B")  // Amber - average
        }
    }

    private var backgroundColor: Color {
        return Color(hex: "#E5E7EB")
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(fillColor)
                    .frame(width: geometry.size.width * CGFloat(100 - percentile) / 100)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

struct PercentileBar_Percentile_Bar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 4) {
        Text("Low bill (18th percentile)")
        .font(.caption)
        PercentileBar(percentile: 18)
        }
        
        VStack(alignment: .leading, spacing: 4) {
        Text("Average bill (50th percentile)")
        .font(.caption)
        PercentileBar(percentile: 50)
        }
        
        VStack(alignment: .leading, spacing: 4) {
        Text("High bill (78th percentile)")
        .font(.caption)
        PercentileBar(percentile: 78)
        }
        }
        .padding()
    }
}
