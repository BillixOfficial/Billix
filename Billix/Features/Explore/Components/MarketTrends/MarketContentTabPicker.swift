//
//  MarketContentTabPicker.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Segmented control for Summary/Breakdown tab switching
//

import SwiftUI

struct MarketContentTabPicker: View {
    @Binding var selectedTab: MarketContentTab

    var body: some View {
        Picker("Content", selection: $selectedTab) {
            ForEach(MarketContentTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.vertical, -4)  // Reduce vertical height by ~30-40%
    }
}

// MARK: - Preview

private struct MarketContentTabPicker_Preview: View {
    @State private var selectedTab: MarketContentTab = .summary

    var body: some View {
        VStack(spacing: 20) {
            MarketContentTabPicker(selectedTab: $selectedTab)

            Text("Selected: \(selectedTab.rawValue)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(hex: "F8F9FA"))
    }
}

struct MarketContentTabPicker_Market_Content_Tab_Picker_Previews: PreviewProvider {
    static var previews: some View {
        MarketContentTabPicker_Preview()
    }
}
