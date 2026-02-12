//
//  TrustBadgeView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Reusable trust badge components for displaying user trust status
//

import SwiftUI

// MARK: - Badge Size

enum TrustBadgeSize {
    case small      // For list items, compact views
    case medium     // For cards, standard displays
    case large      // For profile headers, featured displays
    case xlarge     // For profile page hero

    var iconSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 24
        case .xlarge: return 36
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 36
        case .large: return 56
        case .xlarge: return 80
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        case .xlarge: return 18
        }
    }

    var scoreSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 11
        case .large: return 14
        case .xlarge: return 20
        }
    }
}

// MARK: - Badge Style

enum TrustBadgeStyle {
    case iconOnly       // Just the badge icon
    case compact        // Icon with level name
    case standard       // Icon, name, and score
    case detailed       // Full display with description
}

// MARK: - Trust Badge View

struct TrustBadgeView: View {
    let badgeLevel: BillixBadgeLevel
    let score: Int?
    let size: TrustBadgeSize
    let style: TrustBadgeStyle

    init(
        badgeLevel: BillixBadgeLevel,
        score: Int? = nil,
        size: TrustBadgeSize = .medium,
        style: TrustBadgeStyle = .compact
    ) {
        self.badgeLevel = badgeLevel
        self.score = score
        self.size = size
        self.style = style
    }

    var body: some View {
        switch style {
        case .iconOnly:
            iconOnlyBadge
        case .compact:
            compactBadge
        case .standard:
            standardBadge
        case .detailed:
            detailedBadge
        }
    }

    // MARK: - Icon Only

    private var iconOnlyBadge: some View {
        ZStack {
            Circle()
                .fill(badgeLevel.gradient)
                .frame(width: size.badgeSize, height: size.badgeSize)

            Image(systemName: badgeLevel.icon)
                .font(.system(size: size.iconSize))
                .foregroundColor(.white)
        }
    }

    // MARK: - Compact

    private var compactBadge: some View {
        HStack(spacing: 6) {
            iconOnlyBadge

            Text(badgeLevel.displayName)
                .font(.system(size: size.fontSize, weight: .semibold))
                .foregroundColor(badgeLevel.color)
        }
    }

    // MARK: - Standard

    private var standardBadge: some View {
        HStack(spacing: 8) {
            iconOnlyBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(badgeLevel.displayName)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(.white)

                if let score = score {
                    Text("\(score) pts")
                        .font(.system(size: size.scoreSize))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Detailed

    private var detailedBadge: some View {
        VStack(spacing: 8) {
            iconOnlyBadge

            VStack(spacing: 2) {
                Text(badgeLevel.displayName)
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(.white)

                Text(badgeLevel.description)
                    .font(.system(size: size.scoreSize))
                    .foregroundColor(.gray)

                if let score = score {
                    Text("\(score) / 1000")
                        .font(.system(size: size.scoreSize, weight: .medium))
                        .foregroundStyle(badgeLevel.gradient)
                }
            }
        }
    }
}

// MARK: - Trust Badge Chip

/// A pill-shaped badge for inline use
struct TrustBadgeChip: View {
    let badgeLevel: BillixBadgeLevel
    let showScore: Bool

    @StateObject private var scoreService = BillixScoreService.shared

    init(badgeLevel: BillixBadgeLevel, showScore: Bool = false) {
        self.badgeLevel = badgeLevel
        self.showScore = showScore
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeLevel.icon)
                .font(.system(size: 10))

            Text(badgeLevel.displayName)
                .font(.system(size: 10, weight: .semibold))

            if showScore {
                Text("•")
                    .font(.system(size: 8))
                Text("\(scoreService.overallScore)")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundColor(badgeLevel.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeLevel.color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - User Trust Header

/// Header view showing user avatar with trust badge overlay
struct UserTrustHeader: View {
    let userName: String
    let avatarURL: URL?
    let badgeLevel: BillixBadgeLevel
    let score: Int

    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        HStack(spacing: 16) {
            // Avatar with badge overlay
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                if let url = avatarURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(badgeLevel.gradient.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(primaryText)
                        )
                }

                // Badge overlay
                TrustBadgeView(badgeLevel: badgeLevel, size: .small, style: .iconOnly)
                    .offset(x: 4, y: 4)
            }

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryText)

                TrustBadgeChip(badgeLevel: badgeLevel, showScore: true)
            }

            Spacer()
        }
    }
}

// MARK: - Mini Score Indicator

/// A minimal score indicator for tight spaces
struct MiniScoreIndicator: View {
    let score: Int
    let badgeLevel: BillixBadgeLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeLevel.gradient)
                .frame(width: 8, height: 8)

            Text("\(score)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeLevel.color)
        }
    }
}

// MARK: - Score Progress Ring

/// A circular progress indicator for score
struct ScoreProgressRing: View {
    let score: Int
    let maxScore: Int = 1000
    let badgeLevel: BillixBadgeLevel
    let size: CGFloat

    var progress: Double {
        Double(score) / Double(maxScore)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: size * 0.08)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    badgeLevel.gradient,
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 2) {
                Image(systemName: badgeLevel.icon)
                    .font(.system(size: size * 0.25))
                    .foregroundStyle(badgeLevel.gradient)

                Text("\(score)")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Trust Level Comparison

/// Shows comparison between two trust levels (e.g., in swap matching)
struct TrustLevelComparison: View {
    let userBadge: BillixBadgeLevel
    let userScore: Int
    let partnerBadge: BillixBadgeLevel
    let partnerScore: Int

    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        HStack(spacing: 16) {
            // User side
            VStack(spacing: 4) {
                TrustBadgeView(badgeLevel: userBadge, score: userScore, size: .medium, style: .iconOnly)
                Text("You")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
                Text("\(userScore)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(userBadge.color)
            }

            // Comparison indicator
            VStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(secondaryText)

                Text(matchQuality)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(matchColor)
            }

            // Partner side
            VStack(spacing: 4) {
                TrustBadgeView(badgeLevel: partnerBadge, score: partnerScore, size: .medium, style: .iconOnly)
                Text("Partner")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
                Text("\(partnerScore)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(partnerBadge.color)
            }
        }
        .padding()
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(12)
    }

    private var scoreDifference: Int {
        abs(userScore - partnerScore)
    }

    private var matchQuality: String {
        if scoreDifference <= 100 {
            return "Great Match"
        } else if scoreDifference <= 250 {
            return "Good Match"
        } else {
            return "Fair Match"
        }
    }

    private var matchColor: Color {
        if scoreDifference <= 100 {
            return .green
        } else if scoreDifference <= 250 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Preview

struct TrustBadgeView_Trust_Badge_Sizes_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.08).ignoresSafeArea()
        
        VStack(spacing: 30) {
        // Different sizes
        HStack(spacing: 20) {
        TrustBadgeView(badgeLevel: .elite, size: .small, style: .iconOnly)
        TrustBadgeView(badgeLevel: .elite, size: .medium, style: .iconOnly)
        TrustBadgeView(badgeLevel: .elite, size: .large, style: .iconOnly)
        TrustBadgeView(badgeLevel: .elite, size: .xlarge, style: .iconOnly)
        }
        
        // Different styles
        VStack(spacing: 16) {
        TrustBadgeView(badgeLevel: .verified, score: 750, size: .medium, style: .compact)
        TrustBadgeView(badgeLevel: .verified, score: 750, size: .medium, style: .standard)
        TrustBadgeView(badgeLevel: .verified, score: 750, size: .large, style: .detailed)
        }
        
        // Chips
        HStack {
        TrustBadgeChip(badgeLevel: .newcomer)
        TrustBadgeChip(badgeLevel: .trusted, showScore: true)
        TrustBadgeChip(badgeLevel: .elite, showScore: true)
        }
        
        // Progress ring
        ScoreProgressRing(score: 680, badgeLevel: .verified, size: 100)
        
        // Comparison
        TrustLevelComparison(
        userBadge: .verified,
        userScore: 720,
        partnerBadge: .trusted,
        partnerScore: 580
        )
        }
        .padding()
        }
        .preferredColorScheme(.dark)
    }
}
