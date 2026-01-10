//
//  FairValueBadge.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Price badge with fair value indicator
//

import SwiftUI

struct FairValueBadge: View {
    let fairValue: FairValue
    let rent: Double

    var body: some View {
        HStack(spacing: 6) {
            Text("$\(Int(rent))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                Image(systemName: fairValue.icon)
                    .font(.system(size: 12))

                Text(fairValue.label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(fairValue.color)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview("Fair Value Badges") {
    VStack(spacing: 16) {
        FairValueBadge(fairValue: .greatDeal, rent: 1850)
        FairValueBadge(fairValue: .fairPrice, rent: 2450)
        FairValueBadge(fairValue: .aboveAverage, rent: 3200)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color(hex: "F8F9FA"), Color(hex: "E9ECEF")],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}
