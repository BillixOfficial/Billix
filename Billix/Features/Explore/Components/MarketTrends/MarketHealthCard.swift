//
//  MarketHealthCard.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Traffic light indicator for market health
//

import SwiftUI

struct MarketHealthCard: View {
    let health: MarketHealth

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(health.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: health.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(health.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(health.label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(health.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
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

// MARK: - Preview

#Preview("Market Health Card - Hot") {
    VStack(spacing: 16) {
        MarketHealthCard(health: .hot)
        MarketHealthCard(health: .moderate)
        MarketHealthCard(health: .cool)
    }
    .padding(20)
    .background(Color(hex: "F8F9FA"))
}
