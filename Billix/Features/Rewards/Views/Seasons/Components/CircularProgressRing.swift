//
//  CircularProgressRing.swift
//  Billix
//
//  Created by Claude Code
//  Circular progress ring component for season cards
//

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double  // 0.0 to 1.0
    let colors: [Color]
    let lineWidth: CGFloat

    @State private var animatedProgress: Double = 0

    init(progress: Double, colors: [Color] = [.billixDarkGreen, .billixMoneyGreen], lineWidth: CGFloat = 8) {
        self.progress = progress
        self.colors = colors
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))  // Start from top
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Speedometer Gauge

struct SpeedometerGauge: View {
    let progress: Double          // 0.0 to 1.0
    let currentPoints: Int
    let maxPoints: Int
    let tierColor: Color
    let milestones: [GaugeMilestone]
    var onPigTapped: (() -> Void)? = nil

    // Baked per-badge position overrides
    private static let badgeDistOverrides: [Int: CGFloat] = [1: 41.9, 3: 39.7, 4: 41.7]
    private static let badgeExtraOffX: [Int: CGFloat] = [1: -9.9, 2: -10.6, 4: 10.8]
    private static let badgeExtraOffY: [Int: CGFloat] = [3: 6.7]

    @State private var animatedProgress: Double = 0

    // Arc geometry — 270° horseshoe, gap at bottom
    private let startAngle: Double = 135   // bottom-left
    private let totalSweep: Double = 270   // 135° → 405° (45°)
    private let arcLineWidth: CGFloat = 14
    private let gaugeRadius: CGFloat = 90

    var body: some View {
        ZStack {
            // 1. Gray background track (full 270°)
            ArcShape(startAngle: startAngle, sweepAngle: totalSweep)
                .stroke(
                    Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round)
                )
                .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // 2. Tier-colored progress arc
            ArcShape(startAngle: startAngle, sweepAngle: totalSweep * animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [tierColor, tierColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round)
                )
                .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)
                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProgress)

            // 3. Dense inner tick-mark ring (evenly spaced small ticks)
            let innerTickRadius = gaugeRadius - 20

            EvenTickRingShape(
                startAngle: startAngle,
                totalSweep: totalSweep,
                radius: innerTickRadius,
                tickCount: 45,
                tickLength: 5
            )
            .stroke(Color.gray.opacity(0.25), lineWidth: 0.8)
            .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // Bold milestone ticks at exact milestone positions
            let milestoneFractions = milestones.map { min(max(Double($0.points) / Double(maxPoints), 0), 1) }

            MilestoneTicksShape(
                startAngle: startAngle,
                totalSweep: totalSweep,
                radius: innerTickRadius,
                tickLength: 10,
                fractions: milestoneFractions
            )
            .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
            .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // 4. Milestone number labels (just inside the bold ticks)
            ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                let fraction = Double(milestone.points) / Double(maxPoints)
                let clampedFraction = min(max(fraction, 0), 1)
                let angle = startAngle + totalSweep * clampedFraction

                let labelRadius = innerTickRadius - 16
                let labelPos = pointOnCircle(angle: angle, radius: labelRadius)
                Text(formatPoints(milestone.points))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .offset(x: labelPos.x, y: labelPos.y)
            }

            // 5. Coin milestone badges (outside the arc)
            ForEach(Array(milestones.enumerated()), id: \.offset) { idx, milestone in
                if milestone.coinReward > 0 {
                    let fraction = Double(milestone.points) / Double(maxPoints)
                    let clampedFraction = min(max(fraction, 0), 1)
                    let angle = startAngle + totalSweep * clampedFraction
                    let dist = Self.badgeDistOverrides[idx] ?? 38.8
                    let badgeRadius = gaugeRadius + dist
                    let badgePos = pointOnCircle(angle: angle, radius: badgeRadius)
                    let extraX = Self.badgeExtraOffX[idx] ?? 0
                    let extraY = Self.badgeExtraOffY[idx] ?? 0

                    CoinCallout(
                        reward: milestone.coinReward,
                        angleOnArc: angle,
                        milestoneIndex: idx
                    )
                    .offset(x: badgePos.x + extraX, y: badgePos.y + extraY)
                }
            }

            // 6. Mascot (pig_loading) centered — tappable
            Image("pig_loading")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(y: -4)
                .onTapGesture {
                    if let action = onPigTapped {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        action()
                    }
                }
        }
        .frame(width: 240, height: 220)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }

    // Convert angle + radius to x,y offset from center
    private func pointOnCircle(angle: Double, radius: CGFloat) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: CGFloat(cos(radians)) * radius,
            y: CGFloat(sin(radians)) * radius
        )
    }

    private func formatPoints(_ points: Int) -> String {
        if points >= 1000 {
            let k = Double(points) / 1000.0
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(k))k"
                : String(format: "%.1fk", k)
        }
        return "\(points)"
    }
}

// MARK: - Gauge Milestone Model

struct GaugeMilestone {
    let points: Int
    let coinReward: Int  // 0 = no coin badge shown
}

// MARK: - Arc Shape

private struct ArcShape: Shape {
    let startAngle: Double
    let sweepAngle: Double

    var animatableData: Double {
        get { sweepAngle }
        set { /* read-only for shape, animation handled by parent */ }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(startAngle + sweepAngle),
            clockwise: false
        )
        return path
    }
}

// MARK: - Tick Mark Shape

private struct TickMark: Shape {
    let angle: Double
    let radius: CGFloat
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radians = angle * .pi / 180

        let innerPoint = CGPoint(
            x: center.x + CGFloat(cos(radians)) * (radius - length / 2),
            y: center.y + CGFloat(sin(radians)) * (radius - length / 2)
        )
        let outerPoint = CGPoint(
            x: center.x + CGFloat(cos(radians)) * (radius + length / 2),
            y: center.y + CGFloat(sin(radians)) * (radius + length / 2)
        )

        path.move(to: innerPoint)
        path.addLine(to: outerPoint)
        return path
    }
}

// MARK: - Even Tick Ring Shape (regular small ticks)

private struct EvenTickRingShape: Shape {
    let startAngle: Double
    let totalSweep: Double
    let radius: CGFloat
    let tickCount: Int
    let tickLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        for i in 0..<tickCount {
            let fraction = Double(i) / Double(tickCount - 1)
            let angle = startAngle + totalSweep * fraction
            let radians = angle * .pi / 180

            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(radians)) * (radius - tickLength / 2),
                y: center.y + CGFloat(sin(radians)) * (radius - tickLength / 2)
            )
            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(radians)) * (radius + tickLength / 2),
                y: center.y + CGFloat(sin(radians)) * (radius + tickLength / 2)
            )

            path.move(to: innerPoint)
            path.addLine(to: outerPoint)
        }

        return path
    }
}

// MARK: - Milestone Ticks Shape (bold ticks at exact milestone fractions)

private struct MilestoneTicksShape: Shape {
    let startAngle: Double
    let totalSweep: Double
    let radius: CGFloat
    let tickLength: CGFloat
    let fractions: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        for fraction in fractions {
            let angle = startAngle + totalSweep * fraction
            let radians = angle * .pi / 180

            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(radians)) * (radius - tickLength / 2),
                y: center.y + CGFloat(sin(radians)) * (radius - tickLength / 2)
            )
            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(radians)) * (radius + tickLength / 2),
                y: center.y + CGFloat(sin(radians)) * (radius + tickLength / 2)
            )

            path.move(to: innerPoint)
            path.addLine(to: outerPoint)
        }

        return path
    }
}

// MARK: - Bubble Tail Shape

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Triangle pointing downward (tip at bottom-center)
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Coin Callout (Speech-Bubble Style)

private struct CoinCallout: View {
    let reward: Int
    let angleOnArc: Double
    var milestoneIndex: Int = 0

    // Baked-in tuned values
    private let coinSz: CGFloat = 18
    private let padH: CGFloat = 6.9
    private let padV: CGFloat = 4.5
    private let txtSz: CGFloat = 13
    private let tW: CGFloat = 13.9
    private let tH: CGFloat = 8.3
    private let eA: CGFloat = 24
    private let eB: CGFloat = 6.4

    // Per-badge tail adjustments (keyed by milestone index)
    private static let tailOffXAdj: [Int: CGFloat] = [1: 12.7, 2: 17.5, 3: 1.3, 4: -20.7]
    private static let tailOffYAdj: [Int: CGFloat] = [1: -1.8, 3: 8.6]
    private static let tailRotAdj: [Int: CGFloat] = [1: -129.2, 2: 127.3, 3: -111, 4: -134.7]

    private var towardCenterRad: Double {
        (angleOnArc + 180) * .pi / 180
    }

    private var tailRotation: Double {
        let base = angleOnArc + 90
        let adj = Self.tailRotAdj[milestoneIndex] ?? 0
        return base + Double(adj)
    }

    private var tailOffset: CGPoint {
        let dx = CGFloat(cos(towardCenterRad))
        let dy = CGFloat(sin(towardCenterRad))
        let denom = sqrt((dx * dx) / (eA * eA) + (dy * dy) / (eB * eB))
        guard denom > 0 else { return .zero }
        let baseX = dx / denom
        let baseY = dy / denom
        let adjX = Self.tailOffXAdj[milestoneIndex] ?? 0
        let adjY = Self.tailOffYAdj[milestoneIndex] ?? 0
        return CGPoint(x: baseX + adjX, y: baseY + adjY)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), Color(hex: "#F0A830")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: coinSz, height: coinSz)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#E8A800").opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        Text("C")
                            .font(.system(size: coinSz * 0.45, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    )

                Text("\(reward)+")
                    .font(.system(size: txtSz, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#444444"))
            }
            .padding(.horizontal, padH)
            .padding(.vertical, padV)
            .background(Capsule().fill(Color.white))

            BubbleTail()
                .fill(Color.white)
                .frame(width: tW, height: tH)
                .rotationEffect(.degrees(tailRotation))
                .offset(x: tailOffset.x, y: tailOffset.y)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Tier Milestone Presets

extension SpeedometerGauge {
    static func bronzeMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 0, coinReward: 0),
            GaugeMilestone(points: 1000, coinReward: 50),
            GaugeMilestone(points: 2000, coinReward: 75),
            GaugeMilestone(points: 4000, coinReward: 150),
            GaugeMilestone(points: 6000, coinReward: 250),
            GaugeMilestone(points: 8000, coinReward: 0),
        ]
    }

    static func silverMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 8000, coinReward: 0),
            GaugeMilestone(points: 12000, coinReward: 10),
            GaugeMilestone(points: 18000, coinReward: 15),
            GaugeMilestone(points: 24000, coinReward: 20),
            GaugeMilestone(points: 30000, coinReward: 25),
        ]
    }

    static func goldMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 30000, coinReward: 0),
            GaugeMilestone(points: 45000, coinReward: 15),
            GaugeMilestone(points: 60000, coinReward: 20),
            GaugeMilestone(points: 80000, coinReward: 25),
            GaugeMilestone(points: 100000, coinReward: 50),
        ]
    }

    static func platinumMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 100000, coinReward: 0),
            GaugeMilestone(points: 150000, coinReward: 25),
            GaugeMilestone(points: 250000, coinReward: 50),
            GaugeMilestone(points: 500000, coinReward: 100),
        ]
    }
}

// MARK: - CircularProgressRing Preview

#Preview("Empty Ring") {
    CircularProgressRing(progress: 0.0)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Half Progress") {
    CircularProgressRing(progress: 0.5)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Full Progress") {
    CircularProgressRing(progress: 1.0)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Custom Colors") {
    CircularProgressRing(
        progress: 0.75,
        colors: [.red, .orange, .yellow],
        lineWidth: 12
    )
    .frame(width: 140, height: 140)
    .padding()
}

// MARK: - SpeedometerGauge Preview

#Preview("Speedometer - Bronze 30%") {
    SpeedometerGauge(
        progress: 0.3,
        currentPoints: 2461,
        maxPoints: 8000,
        tierColor: .billixBronzeTier,
        milestones: SpeedometerGauge.bronzeMilestones()
    )
    .padding()
    .background(Color.white)
}

#Preview("Speedometer - Silver 50%") {
    SpeedometerGauge(
        progress: 0.5,
        currentPoints: 19000,
        maxPoints: 30000,
        tierColor: .billixSilverTier,
        milestones: SpeedometerGauge.silverMilestones()
    )
    .padding()
    .background(Color.white)
}
