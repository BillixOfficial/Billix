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

            // 4. Triangle marker at progress tip
            let progressAngle = startAngle + totalSweep * animatedProgress
            let markerPos = pointOnCircle(angle: progressAngle, radius: gaugeRadius + 2)
            GaugeTriangleMarker()
                .fill(tierColor)
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(progressAngle + 90))
                .offset(x: markerPos.x, y: markerPos.y)
                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProgress)

            // 5. Coin milestone badges (outside the arc)
            ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                if milestone.coinReward > 0 {
                    let fraction = Double(milestone.points) / Double(maxPoints)
                    let clampedFraction = min(max(fraction, 0), 1)
                    let angle = startAngle + totalSweep * clampedFraction
                    let badgeRadius = gaugeRadius + 40
                    let badgePos = pointOnCircle(angle: angle, radius: badgeRadius)

                    CoinBadge(reward: milestone.coinReward)
                        .offset(x: badgePos.x, y: badgePos.y)
                }
            }

            // 6. Mascot (pig_loading) centered
            Image("pig_loading")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(y: -4)
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

// MARK: - Triangle Marker

private struct GaugeTriangleMarker: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Coin Badge

private struct CoinBadge: View {
    let reward: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFD700"), Color(hex: "#F0A830")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .shadow(color: Color(hex: "#F0A830").opacity(0.4), radius: 2, x: 0, y: 1)

            Text("\(reward)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Tier Milestone Presets

extension SpeedometerGauge {
    static func bronzeMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 0, coinReward: 0),
            GaugeMilestone(points: 1000, coinReward: 6),
            GaugeMilestone(points: 2000, coinReward: 6),
            GaugeMilestone(points: 4000, coinReward: 10),
            GaugeMilestone(points: 6000, coinReward: 10),
            GaugeMilestone(points: 8000, coinReward: 25),
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
