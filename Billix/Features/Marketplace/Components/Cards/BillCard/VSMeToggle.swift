//
//  VSMeToggle.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Toggle between Market comparison and personal "Vs Me" comparison
struct VSMeToggle: View {
    @Binding var isVsMe: Bool

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            toggleOption(title: "Market", isSelected: !isVsMe)
                .onTapGesture {
                    withAnimation(MarketplaceTheme.Animation.quick) {
                        isVsMe = false
                    }
                }

            toggleOption(title: "Vs Me", isSelected: isVsMe)
                .onTapGesture {
                    withAnimation(MarketplaceTheme.Animation.quick) {
                        isVsMe = true
                    }
                }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    private func toggleOption(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                            .fill(MarketplaceTheme.Colors.primary)
                            .matchedGeometryEffect(id: "toggle", in: animation)
                    }
                }
            )
    }
}

struct VSMeToggle_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
        @State private var isVsMe = false
        
        var body: some View {
        VStack(spacing: 20) {
        VSMeToggle(isVsMe: $isVsMe)
        
        Text(isVsMe ? "Showing personal comparison" : "Showing market comparison")
        .font(.caption)
        }
        .padding()
        }
        }
        
        return PreviewWrapper()
    }
}
