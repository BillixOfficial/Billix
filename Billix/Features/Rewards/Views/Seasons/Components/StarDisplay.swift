//
//  StarDisplay.swift
//  Billix
//
//  Created by Claude Code
//  Animated star collection display component
//

import SwiftUI

struct StarDisplay: View {
    let starsEarned: Int
    let maxStars: Int
    let size: CGFloat

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(starsEarned: Int, maxStars: Int = 3, size: CGFloat = 24) {
        self.starsEarned = min(starsEarned, maxStars)
        self.maxStars = maxStars
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(0..<maxStars, id: \.self) { index in
                // All stars are FILLED - golden amber for earned, light grey for unearned
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .heavy))
                    .foregroundColor(index < starsEarned ? Color(hex: "#F59E0B") : Color(hex: "#E5E7EB"))
                    .shadow(
                        color: index < starsEarned ? Color(hex: "#F59E0B").opacity(0.4) : .clear,
                        radius: index < starsEarned ? 8 : 0,
                        x: 0,
                        y: 2
                    )
                    .scaleEffect(animationScale(for: index))
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.1),
                        value: appeared
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(starsEarned) out of \(maxStars) stars earned")
        .onAppear {
            appeared = true
        }
    }

    private func animationScale(for index: Int) -> CGFloat {
        if reduceMotion {
            return 1.0
        }
        return appeared && index < starsEarned ? 1.0 : 0.5
    }
}

// MARK: - Preview

#Preview("No Stars") {
    StarDisplay(starsEarned: 0)
        .padding()
}

#Preview("One Star") {
    StarDisplay(starsEarned: 1)
        .padding()
}

#Preview("Two Stars") {
    StarDisplay(starsEarned: 2)
        .padding()
}

#Preview("Three Stars") {
    StarDisplay(starsEarned: 3)
        .padding()
}

#Preview("Large Stars") {
    VStack(spacing: 20) {
        StarDisplay(starsEarned: 3, size: 32)
        StarDisplay(starsEarned: 2, size: 40)
        StarDisplay(starsEarned: 1, size: 48)
    }
    .padding()
}

#Preview("Custom Max Stars") {
    VStack(spacing: 20) {
        StarDisplay(starsEarned: 3, maxStars: 5, size: 28)
        StarDisplay(starsEarned: 5, maxStars: 5, size: 28)
    }
    .padding()
}
