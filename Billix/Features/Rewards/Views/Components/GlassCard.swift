//
//  GlassCard.swift
//  Billix
//
//  Created by Claude Code on 11/29/25.
//  Reusable glass-morphism container for modern iOS-style UI
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let borderOpacity: Double
    let backgroundOpacity: Double

    init(
        cornerRadius: CGFloat = 20,
        borderOpacity: Double = 0.3,
        backgroundOpacity: Double = 0.15,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.backgroundOpacity = backgroundOpacity
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Ultra thin material for native blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent white overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(backgroundOpacity))
                }
            )
            .overlay(
                // Subtle border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview("Glass Card") {
    ZStack {
        // Dark teal gradient background (like Price Guessr card)
        LinearGradient(
            colors: [Color(hex: "#1e3d40"), Color(hex: "#2d5a5e")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card Example")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Frosted glass effect with blur")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
            }
            .padding(.horizontal, 20)

            GlassCard(cornerRadius: 16, backgroundOpacity: 0.2) {
                Text("Custom opacity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(16)
            }
            .padding(.horizontal, 20)
        }
    }
}
