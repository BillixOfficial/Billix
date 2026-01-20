//
//  MarketContentTabPicker.swift
//  Billix
//
//  Stub implementation - actual component is in Components/MarketTrends/

import SwiftUI

struct MarketContentTabPicker: View {
    @Binding var selectedTab: MarketContentTab

    var body: some View {
        Picker("Content", selection: $selectedTab) {
            ForEach(MarketContentTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
}
