//
//  ProgressPathConnector.swift
//  Billix
//
//  Created by Claude Code
//  Visual connector between part cards in saga map
//

import SwiftUI

struct ProgressPathConnector: View {
    let isUnlocked: Bool
    let isNextToUnlock: Bool  // For gradient effect
    let height: CGFloat

    init(isUnlocked: Bool, isNextToUnlock: Bool = false, height: CGFloat = 40) {
        self.isUnlocked = isUnlocked
        self.isNextToUnlock = isNextToUnlock
        self.height = height
    }

    private var pathColor: Color {
        if isUnlocked {
            return Color(hex: "#6B2DD6")
        } else if isNextToUnlock {
            return Color(hex: "#6B2DD6").opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dotted vertical line
            Rectangle()
                .fill(pathColor)
                .frame(width: 2, height: height)
                .mask(
                    VStack(spacing: 4) {
                        ForEach(0..<Int(height / 8), id: \.self) { _ in
                            Rectangle()
                                .frame(width: 2, height: 4)
                        }
                    }
                )

            // Optional: Animated flowing dots
            if isUnlocked {
                Circle()
                    .fill(pathColor)
                    .frame(width: 6, height: 6)
                    .offset(y: -height / 2)
                    .opacity(0.6)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview("Progress Path Connector") {
    VStack(spacing: 0) {
        // Sample part card placeholder
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(height: 100)
            .overlay(
                Text("Part 1")
                    .font(.headline)
            )

        // Unlocked connector
        ProgressPathConnector(isUnlocked: true, height: 40)

        // Another part card
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(height: 100)
            .overlay(
                Text("Part 2")
                    .font(.headline)
            )

        // Next to unlock connector (gradient effect)
        ProgressPathConnector(isUnlocked: false, isNextToUnlock: true, height: 40)

        // Locked part card
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.5))
            .frame(height: 100)
            .overlay(
                Text("Part 3 🔒")
                    .font(.headline)
                    .foregroundColor(.gray)
            )

        // Locked connector
        ProgressPathConnector(isUnlocked: false, height: 40)

        // Another locked part
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.5))
            .frame(height: 100)
            .overlay(
                Text("Part 4 🔒")
                    .font(.headline)
                    .foregroundColor(.gray)
            )
    }
    .padding()
    .background(Color.billixLightGreen)
}
