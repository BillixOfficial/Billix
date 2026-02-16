//
//  LeaderboardCardViews.swift
//  Billix
//
//  Created by Claude Code on 2/15/26.
//  Leaderboard redesign: individual user cards, notched container, crown badge
//

import SwiftUI

// MARK: - Notched Rectangle Shape

/// A rounded rectangle with a wavy top edge inspired by Duolingo's leaderboard container.
/// The top edge dips down on both sides and rises to a smooth center bump, creating an
/// organic wave shape. A small dot sits at the peak of the center bump.
struct NotchedRectangle: Shape {
    /// How far the sides dip below the center bump peak
    var dipDepth: CGFloat = 14
    var cornerRadius: CGFloat = 20
    /// Left Bezier control point X as fraction of width (0–0.5)
    var leftCPx: CGFloat = 0.25
    /// Left Bezier control point Y as multiplier of dipDepth (1.0 = at dip level, 0 = at peak)
    var leftCPy: CGFloat = 1.0
    /// Right-of-center control point X as fraction of width (0–0.5, measured from center)
    var rightCPx: CGFloat = 0.35
    /// Right-of-center control point Y as multiplier of dipDepth
    var rightCPy: CGFloat = 0.0

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(dipDepth, cornerRadius) }
        set {
            dipDepth = newValue.first
            cornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cr = cornerRadius
        let centerX = w / 2

        var path = Path()

        // Start at top-left, at the dipped level (after corner radius)
        path.move(to: CGPoint(x: 0, y: dipDepth + cr))

        // Top-left corner arc
        path.addArc(
            center: CGPoint(x: cr, y: dipDepth + cr),
            radius: cr,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Wavy top edge: left corner → center peak
        path.addCurve(
            to: CGPoint(x: centerX, y: 0),
            control1: CGPoint(x: w * leftCPx, y: dipDepth * leftCPy),
            control2: CGPoint(x: w * rightCPx, y: dipDepth * rightCPy)
        )

        // Center peak → right corner (mirrored)
        path.addCurve(
            to: CGPoint(x: w - cr, y: dipDepth),
            control1: CGPoint(x: w * (1 - rightCPx), y: dipDepth * rightCPy),
            control2: CGPoint(x: w * (1 - leftCPx), y: dipDepth * leftCPy)
        )

        // Top-right corner arc
        path.addArc(
            center: CGPoint(x: w - cr, y: dipDepth + cr),
            radius: cr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right side
        path.addLine(to: CGPoint(x: w, y: h - cr))

        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: w - cr, y: h - cr),
            radius: cr,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom side
        path.addLine(to: CGPoint(x: cr, y: h))

        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: cr, y: h - cr),
            radius: cr,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Hexagon Shape (for Crown Badge)

/// A regular flat-top hexagon using 6 vertices at 60-degree intervals.
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = Angle.degrees(Double(i) * 60 - 90)
            let point = CGPoint(
                x: center.x + radius * cos(CGFloat(angle.radians)),
                y: center.y + radius * sin(CGFloat(angle.radians))
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Crown Badge

/// Golden hexagonal badge with crown icon for rank #1.
struct CrownBadge: View {
    var body: some View {
        ZStack {
            HexagonShape()
                .fill(
                    LinearGradient(
                        colors: [.billixLeaderGold, .billixArcadeGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: Color.billixLeaderGold.opacity(0.5), radius: 6, x: 0, y: 2)

            Image(systemName: "crown.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Leaderboard User Card

/// Individual card for each leaderboard user.
struct LeaderboardUserCard: View {
    let entry: LeaderboardEntry
    let isTeaser: Bool

    init(entry: LeaderboardEntry, isTeaser: Bool = false) {
        self.entry = entry
        self.isTeaser = isTeaser
    }

    private var isTopThree: Bool { entry.rank <= 3 }
    private var isFirst: Bool { entry.rank == 1 }

    private var rankCircleColor: Color {
        if isTopThree {
            return entry.rankBadgeColor
        }
        return Color.billixMoneyGreen.opacity(0.15)
    }

    private var rankTextColor: Color {
        if isTopThree {
            return .white
        }
        return .gray
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank circle
            ZStack {
                Circle()
                    .fill(rankCircleColor)
                    .frame(width: 32, height: 32)

                Text("\(entry.rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(rankTextColor)
            }

            // Avatar circle with initials
            Circle()
                .fill(entry.rankBadgeColor.opacity(0.2))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(entry.avatarInitials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(entry.rankBadgeColor)
                )

            // Name + points stacked
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: entry.isCurrentUser ? .bold : .semibold))
                    .foregroundColor(entry.isCurrentUser ? .billixMoneyGreen : .billixDarkGreen)

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.billixArcadeGold)
                    Text("\(entry.totalPoints) pts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()

            // Crown badge for #1
            if isFirst {
                CrownBadge()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFirst ? Color.billixLeaderGold.opacity(0.4) :
                    entry.isCurrentUser ? Color.billixMoneyGreen.opacity(0.3) :
                    Color.clear,
                    lineWidth: isFirst ? 1.5 : 1
                )
        )
    }
}

// MARK: - Leaderboard Card Teaser (Notched Container)

/// Replaces old LeaderboardTeaser. Shows top 3 users in individual cards inside a wavy sage-green container.
struct LeaderboardCardTeaser: View {
    let topSavers: [LeaderboardEntry]
    let currentUser: LeaderboardEntry?
    var onSeeAll: (() -> Void)?

    // Tuned wave shape values
    private let waveDipDepth: CGFloat = 16
    private let waveCornerRadius: CGFloat = 21
    private let waveLeftCPx: CGFloat = 0.50
    private let waveLeftCPy: CGFloat = 1.14
    private let waveRightCPx: CGFloat = 0.39
    private let waveRightCPy: CGFloat = 0.15

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header (above the container)
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                if topSavers.count > 3 {
                    Button {
                        onSeeAll?()
                    } label: {
                        Text("See all")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixChartBlue)
                    }
                }
            }

            if topSavers.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32))
                        .foregroundColor(.billixMediumGreen.opacity(0.5))
                    Text("No leaderboard data yet")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMediumGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Wavy container with user cards
                ZStack(alignment: .top) {
                    // Wavy background shape
                    NotchedRectangle(
                        dipDepth: waveDipDepth,
                        cornerRadius: waveCornerRadius,
                        leftCPx: waveLeftCPx,
                        leftCPy: waveLeftCPy,
                        rightCPx: waveRightCPx,
                        rightCPy: waveRightCPy
                    )
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.billixBorderGreen.opacity(0.5),
                                    Color.billixMoneyGreen.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            NotchedRectangle(
                                dipDepth: waveDipDepth,
                                cornerRadius: waveCornerRadius,
                                leftCPx: waveLeftCPx,
                                leftCPy: waveLeftCPy,
                                rightCPx: waveRightCPx,
                                rightCPy: waveRightCPy
                            )
                                .stroke(Color.billixBorderGreen.opacity(0.6), lineWidth: 1)
                        )

                    // Small circle at the peak of the wave — matches the page background
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .shadow(color: Color.billixBorderGreen.opacity(0.3), radius: 1, x: 0, y: 0.5)
                        .offset(x: 0, y: 5.5)

                    // User cards — top padding accounts for dip + spacing
                    VStack(spacing: 10) {
                        ForEach(Array(topSavers.prefix(3))) { entry in
                            LeaderboardUserCard(entry: entry, isTeaser: true)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, waveDipDepth + 14)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}
