//
//  TrustBadge.swift
//  Billix
//
//  Trust score indicator badge component
//

import SwiftUI

struct TrustBadge: View {
    let score: Int  // 0-100
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var diameter: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 64
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 18
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 4
            case .large: return 5
            }
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: size.lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    trustColor,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: score)

            // Score text
            Text("\(score)")
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(trustColor)
        }
        .frame(width: size.diameter, height: size.diameter)
    }

    private var trustColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .billixMoneyGreen
        } else if score >= 40 {
            return .yellow
        } else if score >= 20 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Trust Badge with Label

struct TrustBadgeWithLabel: View {
    let score: Int
    var size: TrustBadge.BadgeSize = .medium

    var body: some View {
        VStack(spacing: 4) {
            TrustBadge(score: score, size: size)

            Text(trustLevel)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(trustColor)
        }
    }

    private var trustLevel: String {
        if score >= 80 {
            return "Trusted"
        } else if score >= 60 {
            return "Reliable"
        } else if score >= 40 {
            return "Building"
        } else if score >= 20 {
            return "New"
        } else {
            return "Unverified"
        }
    }

    private var trustColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .billixMoneyGreen
        } else if score >= 40 {
            return .yellow
        } else if score >= 20 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Inline Trust Badge

struct InlineTrustBadge: View {
    let score: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trustIcon)
                .font(.caption)

            Text("\(score)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(trustColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trustColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var trustIcon: String {
        if score >= 80 {
            return "checkmark.shield.fill"
        } else if score >= 60 {
            return "shield.fill"
        } else if score >= 40 {
            return "shield.lefthalf.filled"
        } else {
            return "shield"
        }
    }

    private var trustColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .billixMoneyGreen
        } else if score >= 40 {
            return .yellow
        } else if score >= 20 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview

#Preview("Trust Badge") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            TrustBadge(score: 95, size: .large)
            TrustBadge(score: 75, size: .large)
            TrustBadge(score: 50, size: .large)
            TrustBadge(score: 25, size: .large)
        }

        HStack(spacing: 24) {
            TrustBadgeWithLabel(score: 95)
            TrustBadgeWithLabel(score: 75)
            TrustBadgeWithLabel(score: 50)
            TrustBadgeWithLabel(score: 25)
        }

        HStack(spacing: 12) {
            InlineTrustBadge(score: 95)
            InlineTrustBadge(score: 75)
            InlineTrustBadge(score: 50)
            InlineTrustBadge(score: 25)
        }
    }
    .padding()
}
