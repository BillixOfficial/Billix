//
//  TickerHeaderView.swift
//  Billix
//
//  Stub implementation - actual component is in Components/MarketTrends/

import SwiftUI

struct TickerHeaderView: View {
    let averageRent: Double
    let changePercent: Double
    let lowRent: Double
    let highRent: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("$\(Int(averageRent))")
                .font(.system(size: 32, weight: .bold))
            Text("Average Rent")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
