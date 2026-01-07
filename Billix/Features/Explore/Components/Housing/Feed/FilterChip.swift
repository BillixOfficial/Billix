//
//  FilterChip.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Reusable filter chip component
//

import SwiftUI

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(label)
                    .font(.system(size: 14, weight: .medium))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.billixDarkTeal : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.billixDarkTeal, lineWidth: isSelected ? 0 : 1.5)
            )
            .foregroundColor(isSelected ? .white : .billixDarkTeal)
        }
        .accessibilityLabel("Filter by \(label)")
        .accessibilityHint("Tap to change \(label) filter")
    }
}

#Preview("Filter Chips") {
    HStack(spacing: 12) {
        FilterChip(label: "All", icon: "house.fill", isSelected: false, action: {})
        FilterChip(label: "2+ Beds", icon: "bed.double.fill", isSelected: true, action: {})
        FilterChip(label: "Price", icon: "dollarsign.circle.fill", isSelected: false, action: {})
    }
    .padding()
    .background(Color.billixCreamBeige)
}
