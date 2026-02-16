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
    let tierStartPoints: Int      // 0 for Bronze, 8000 for Silver, etc.
    let tierColor: Color
    let milestones: [GaugeMilestone]
    var onPigTapped: (() -> Void)? = nil
    var onMilestoneClaimed: ((GaugeMilestone) -> Void)? = nil
    var labelFontSize: CGFloat = 9
    var tickScale: CGFloat = 1.0

    // Per-badge position overrides
    private static let badgeDistOverrides: [Int: CGFloat] = [:]

    // Per-tier baked-in bubble + tail adjustments (tuned via debug panel)
    private static let tierBubbleOffX: [String: [Int: CGFloat]] = [
        "bronze":   [1: -6.8, 2: -5.9, 4: 7.7],
        "silver":   [1: -6.8, 2: -5.9, 3: 8.2, 4: 17.4],
        "gold":     [1: -12.0, 2: -5.9, 3: 8.2, 4: 24.5],
        "platinum": [1: -14.0, 2: -9.2, 3: 33.8],
    ]
    private static let tierBubbleOffY: [String: [Int: CGFloat]] = [
        "bronze":   [3: 11.8],
        "silver":   [2: 6.2, 3: -0.6, 4: -4.4],
        "gold":     [2: 6.2, 3: -0.6, 4: -4.4],
        "platinum": [2: 8.8, 3: -17.1],
    ]
    private static let tierTailOffX: [String: [Int: CGFloat]] = [
        "bronze":   [1: 5.7, 2: 9.3, 4: -12.9],
        "silver":   [1: 5.7, 2: 9.3, 3: -14.9, 4: -19.9],
        "gold":     [1: 8.9, 2: 9.3, 3: -14.9, 4: -23.1],
        "platinum": [1: 12.4, 2: 9.6, 3: -25.9],
    ]
    private static let tierTailOffY: [String: [Int: CGFloat]] = [
        "bronze":   [3: 1.7],
        "silver":   [2: 2.8, 3: 1.7, 4: -0.3],
        "gold":     [1: 3.1, 2: 2.8, 3: 1.7, 4: -3.1],
        "platinum": [2: 1.7, 3: 2.5],
    ]
    private static let tierTailRot: [String: [Int: CGFloat]] = [
        "silver":   [3: -20.2, 4: 17.1],
        "gold":     [3: -20.2, 4: 17.1],
        "platinum": [3: -143.7],
    ]

    @State private var animatedProgress: Double = 0

    // Debug controls state
    @State private var showBubbleDebug = false
    @State private var debugTier: String = "bronze"
    @State private var selectedMilestone: Int = 1

    // Per-milestone debug adjustments (additive on top of baked values)
    @State private var bubbleOffX: [Int: CGFloat] = [:]
    @State private var bubbleOffY: [Int: CGFloat] = [:]
    @State private var tailOffX: [Int: CGFloat] = [:]
    @State private var tailOffY: [Int: CGFloat] = [:]
    @State private var tailRot: [Int: CGFloat] = [:]

    // Arc geometry — 270° horseshoe, gap at bottom
    private let startAngle: Double = 135   // bottom-left
    private let totalSweep: Double = 270   // 135° → 405° (45°)
    private let arcLineWidth: CGFloat = 14
    private let gaugeRadius: CGFloat = 90

    // Resolve which tier key to use for baked offsets
    private var tierKey: String {
        if showBubbleDebug { return debugTier }
        switch tierStartPoints {
        case 0: return "bronze"
        case 8000: return "silver"
        case 30000: return "gold"
        case 100000: return "platinum"
        default: return "bronze"
        }
    }

    // Effective values for debug tier override
    private var effectiveMilestones: [GaugeMilestone] {
        guard showBubbleDebug else { return milestones }
        switch debugTier {
        case "bronze": return Self.bronzeMilestones()
        case "silver": return Self.silverMilestones()
        case "gold": return Self.goldMilestones()
        case "platinum": return Self.platinumMilestones()
        default: return milestones
        }
    }

    private var effectiveTierStart: Int {
        guard showBubbleDebug else { return tierStartPoints }
        switch debugTier {
        case "bronze": return 0
        case "silver": return 8000
        case "gold": return 30000
        case "platinum": return 100000
        default: return tierStartPoints
        }
    }

    private var effectiveMaxPoints: Int {
        guard showBubbleDebug else { return maxPoints }
        switch debugTier {
        case "bronze": return 8000
        case "silver": return 30000
        case "gold": return 100000
        case "platinum": return 500000
        default: return maxPoints
        }
    }

    private var effectiveTierColor: Color {
        guard showBubbleDebug else { return tierColor }
        switch debugTier {
        case "bronze": return .billixBronzeTier
        case "silver": return .billixSilverTier
        case "gold": return .billixGoldTier
        case "platinum": return Color(red: 0.9, green: 0.85, blue: 0.7)
        default: return tierColor
        }
    }

    var body: some View {
        let activeMilestones = effectiveMilestones
        let activeTierStart = effectiveTierStart
        let activeMaxPoints = effectiveMaxPoints
        let activeColor = effectiveTierColor
        let tierRange = Double(activeMaxPoints - activeTierStart)

        ZStack {
            // 1. Gray background track (full 270°)
            ArcShape(startAngle: startAngle, sweepAngle: totalSweep)
                .stroke(
                    Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round)
                )
                .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // 2. Tier-colored progress arc with gradient + glow
            ArcShape(startAngle: startAngle, sweepAngle: totalSweep * animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [activeColor, activeColor.opacity(0.85), activeColor.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: arcLineWidth, lineCap: .round)
                )
                .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)
                .shadow(color: activeColor.opacity(0.3), radius: 6, x: 0, y: 0)
                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProgress)

            // 3. Glowing leading edge dot
            if animatedProgress > 0.01 {
                let edgeAngle = startAngle + totalSweep * animatedProgress
                let edgePos = pointOnCircle(angle: edgeAngle, radius: gaugeRadius)

                Circle()
                    .fill(activeColor)
                    .frame(width: arcLineWidth + 2, height: arcLineWidth + 2)
                    .shadow(color: activeColor.opacity(0.7), radius: 8, x: 0, y: 0)
                    .shadow(color: activeColor.opacity(0.4), radius: 16, x: 0, y: 0)
                    .offset(x: edgePos.x, y: edgePos.y)
                    .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProgress)
            }

            // 4. Dense inner tick-mark ring (evenly spaced small ticks)
            let innerTickRadius = gaugeRadius - 20

            EvenTickRingShape(
                startAngle: startAngle,
                totalSweep: totalSweep,
                radius: innerTickRadius,
                tickCount: 45,
                tickLength: 5 * tickScale
            )
            .stroke(Color.gray.opacity(0.25), lineWidth: 0.8 * tickScale)
            .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // Bold milestone ticks at exact milestone positions
            let milestoneFractions = activeMilestones.map { min(max(Double($0.points - activeTierStart) / tierRange, 0), 1) }

            MilestoneTicksShape(
                startAngle: startAngle,
                totalSweep: totalSweep,
                radius: innerTickRadius,
                tickLength: 10 * tickScale,
                fractions: milestoneFractions
            )
            .stroke(Color.gray.opacity(0.5), lineWidth: 1.5 * tickScale)
            .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)

            // 5. Milestone number labels (just inside the bold ticks)
            ForEach(Array(activeMilestones.enumerated()), id: \.offset) { _, milestone in
                let fraction = Double(milestone.points - activeTierStart) / tierRange
                let clampedFraction = min(max(fraction, 0), 1)
                let angle = startAngle + totalSweep * clampedFraction

                let labelRadius = innerTickRadius - 16
                let labelPos = pointOnCircle(angle: angle, radius: labelRadius)
                Text(formatPoints(milestone.points))
                    .font(.system(size: labelFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .offset(x: labelPos.x, y: labelPos.y)
            }

            // 7. Mascot (pig_loading) centered — warm glow seats it inside the ring
            Image("pig_loading")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .shadow(color: Color(hex: "#F0A830").opacity(0.35), radius: 10, x: 0, y: 2)
                .shadow(color: Color(hex: "#F0A830").opacity(0.15), radius: 20, x: 0, y: 0)
                .offset(y: -4)
                .onTapGesture {
                    if let action = onPigTapped {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        action()
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showBubbleDebug.toggle()
                }
        }
        .frame(width: 240, height: 220)
        .overlay {
            ZStack {
                ForEach(Array(activeMilestones.enumerated()), id: \.offset) { idx, milestone in
                    if milestone.coinReward > 0 {
                        let fraction = Double(milestone.points - activeTierStart) / tierRange
                        let clampedFraction = min(max(fraction, 0), 1)
                        let angle = startAngle + totalSweep * clampedFraction
                        let dist = Self.badgeDistOverrides[idx] ?? 38.8
                        let badgeRadius = gaugeRadius + dist
                        let badgePos = pointOnCircle(angle: angle, radius: badgeRadius)

                        // Baked per-tier offsets + additive debug adjustments
                        let bkBubX = Self.tierBubbleOffX[tierKey]?[idx] ?? 0
                        let bkBubY = Self.tierBubbleOffY[tierKey]?[idx] ?? 0
                        let bkTailX = Self.tierTailOffX[tierKey]?[idx] ?? 0
                        let bkTailY = Self.tierTailOffY[tierKey]?[idx] ?? 0
                        let bkTailR = Self.tierTailRot[tierKey]?[idx] ?? 0

                        CoinCallout(
                            reward: milestone.coinReward,
                            angleOnArc: angle,
                            milestoneIndex: idx,
                            extraTailOffX: bkTailX + (tailOffX[idx] ?? 0),
                            extraTailOffY: bkTailY + (tailOffY[idx] ?? 0),
                            extraTailRot: bkTailR + (tailRot[idx] ?? 0),
                            claimState: milestone.claimState,
                            onTap: milestone.claimState == .claimable ? { onMilestoneClaimed?(milestone) } : nil
                        )
                        .zIndex(milestone.claimState == .claimable ? 10 : 0)
                        .offset(x: badgePos.x + bkBubX + (bubbleOffX[idx] ?? 0),
                                y: badgePos.y + bkBubY + (bubbleOffY[idx] ?? 0))
                    }
                }
            }
            .frame(width: 400, height: 360)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
        .sheet(isPresented: $showBubbleDebug) {
            bubbleDebugPanel
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
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

    // Milestone indices that have coin rewards for current effective tier
    private var coinMilestoneIndices: [Int] {
        effectiveMilestones.enumerated().compactMap { idx, m in
            m.coinReward > 0 ? idx : nil
        }
    }

    // MARK: - Bubble Debug Panel

    @ViewBuilder
    private var bubbleDebugPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bubble Debug")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button("Done") { showBubbleDebug = false }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Tier picker
            Picker("Tier", selection: $debugTier) {
                Text("Bronze").tag("bronze")
                Text("Silver").tag("silver")
                Text("Gold").tag("gold")
                Text("Platinum").tag("platinum")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .onChange(of: debugTier) { _, _ in
                // Reset milestone selection to first coin milestone of new tier
                let indices = coinMilestoneIndices
                selectedMilestone = indices.first ?? 1
            }

            // Milestone selector (only coin-reward milestones)
            if !coinMilestoneIndices.isEmpty {
                Picker("Milestone", selection: $selectedMilestone) {
                    ForEach(coinMilestoneIndices, id: \.self) { idx in
                        Text("M\(idx)").tag(idx)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Sliders for selected milestone
            VStack(spacing: 6) {
                debugSlider("Bubble X", color: .blue,
                            value: Binding(
                                get: { bubbleOffX[selectedMilestone] ?? 0 },
                                set: { bubbleOffX[selectedMilestone] = $0 }
                            ), range: -40...40, step: 1)

                debugSlider("Bubble Y", color: .purple,
                            value: Binding(
                                get: { bubbleOffY[selectedMilestone] ?? 0 },
                                set: { bubbleOffY[selectedMilestone] = $0 }
                            ), range: -40...40, step: 1)

                debugSlider("Tail X", color: .green,
                            value: Binding(
                                get: { tailOffX[selectedMilestone] ?? 0 },
                                set: { tailOffX[selectedMilestone] = $0 }
                            ), range: -20...20, step: 0.5)

                debugSlider("Tail Y", color: .orange,
                            value: Binding(
                                get: { tailOffY[selectedMilestone] ?? 0 },
                                set: { tailOffY[selectedMilestone] = $0 }
                            ), range: -20...20, step: 0.5)

                debugSlider("Tail Rot", color: .red,
                            value: Binding(
                                get: { tailRot[selectedMilestone] ?? 0 },
                                set: { tailRot[selectedMilestone] = $0 }
                            ), range: -180...180, step: 1)
            }
            .padding(.horizontal, 20)

            // Actions
            HStack(spacing: 12) {
                Button {
                    bubbleOffX = [:]
                    bubbleOffY = [:]
                    tailOffX = [:]
                    tailOffY = [:]
                    tailRot = [:]
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }

                Button {
                    copyDebugValues()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .padding(.top, 8)
    }

    private func debugSlider(_ label: String, color: Color, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Slider(value: value, in: range, step: step)
                .tint(color)
            Text(String(format: "%.1f", value.wrappedValue))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 44, alignment: .trailing)
        }
        .frame(height: 28)
    }

    private func copyDebugValues() {
        var lines: [String] = []
        let allDicts: [(String, [Int: CGFloat])] = [
            ("bubbleOffX", bubbleOffX),
            ("bubbleOffY", bubbleOffY),
            ("tailOffX", tailOffX),
            ("tailOffY", tailOffY),
            ("tailRot", tailRot),
        ]
        for (name, dict) in allDicts {
            let nonZero = dict.filter { $0.value != 0 }
            if !nonZero.isEmpty {
                let entries = nonZero.sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \(String(format: "%.1f", $0.value))" }
                    .joined(separator: ", ")
                lines.append("\(name): [\(entries)]")
            }
        }
        let result = lines.isEmpty ? "// All values at default (0)" : lines.joined(separator: "\n")
        UIPasteboard.general.string = "// \(debugTier) tier\n\(result)"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Gauge Milestone Model

struct GaugeMilestone {
    let points: Int
    let coinReward: Int  // 0 = no coin badge shown
    var claimState: ClaimState = .notReached

    enum ClaimState: Equatable {
        case notReached  // White bubble (default)
        case claimable   // Golden pulsing glow — user can tap
        case claimed     // Green tint + checkmark — already collected
    }
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
    var extraTailOffX: CGFloat = 0
    var extraTailOffY: CGFloat = 0
    var extraTailRot: CGFloat = 0
    var claimState: GaugeMilestone.ClaimState = .notReached
    var onTap: (() -> Void)? = nil

    @State private var isGlowing = false
    @State private var bounceOffset: CGFloat = 0

    // Baked-in tuned values
    private let coinSz: CGFloat = 18
    private let padH: CGFloat = 6.9
    private let padV: CGFloat = 4.5
    private let txtSz: CGFloat = 13
    private let tW: CGFloat = 13.9
    private let tH: CGFloat = 8.3
    private let eA: CGFloat = 26
    private let eB: CGFloat = 12

    private var towardCenterRad: Double {
        (angleOnArc + 180) * .pi / 180
    }

    private var tailRotation: Double {
        angleOnArc + 90 + Double(extraTailRot)
    }

    private var tailOffset: CGPoint {
        let dx = CGFloat(cos(towardCenterRad))
        let dy = CGFloat(sin(towardCenterRad))
        let denom = sqrt((dx * dx) / (eA * eA) + (dy * dy) / (eB * eB))
        guard denom > 0 else { return .zero }
        return CGPoint(x: dx / denom + extraTailOffX, y: dy / denom + extraTailOffY)
    }

    private var bubbleColor: Color {
        switch claimState {
        case .notReached: return .white
        case .claimable: return Color(hex: "#FFE082") // rich warm amber
        case .claimed: return Color(hex: "#E8F5E9")
        }
    }

    private var tailColor: Color {
        bubbleColor
    }

    private var bubbleContent: some View {
        ZStack {
            HStack(spacing: 4) {
                // Icon: gold coin for notReached/claimable, green checkmark for claimed
                if claimState == .claimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: coinSz, weight: .bold))
                        .foregroundColor(Color(hex: "#4CAF50"))
                } else {
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
                }

                Text(claimState == .claimed ? "\(reward)" : "\(reward)+")
                    .font(.system(size: txtSz, weight: .heavy, design: .rounded))
                    .foregroundColor(
                        claimState == .claimed ? Color(hex: "#4CAF50") :
                        claimState == .claimable ? Color(hex: "#8B6914") :
                        Color(hex: "#444444")
                    )
            }
            .padding(.horizontal, padH)
            .padding(.vertical, padV)
            .background(
                Capsule().fill(
                    claimState == .claimable ?
                    AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "#FFD54F"), Color(hex: "#FFB300")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )) :
                    AnyShapeStyle(bubbleColor)
                )
            )
            .overlay(
                claimState == .claimable ?
                Capsule().stroke(Color(hex: "#F9A825").opacity(0.6), lineWidth: 1.5)
                : nil
            )

            BubbleTail()
                .fill(claimState == .claimable ? Color(hex: "#FFC107") : tailColor)
                .frame(width: tW, height: tH)
                .rotationEffect(.degrees(tailRotation))
                .offset(x: tailOffset.x, y: tailOffset.y)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .shadow(
            color: claimState == .claimable ? Color(hex: "#FF8F00").opacity(isGlowing ? 0.65 : 0.25) : Color.clear,
            radius: claimState == .claimable ? (isGlowing ? 14 : 6) : 0
        )
    }

    var body: some View {
        Group {
            if claimState == .claimable {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onTap?()
                } label: {
                    bubbleContent
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.92))
            } else {
                bubbleContent
            }
        }
        .offset(y: claimState == .claimable ? bounceOffset : 0)
        .onAppear {
            startAnimationsIfNeeded()
        }
        .onChange(of: claimState) { _, _ in
            startAnimationsIfNeeded()
        }
    }

    private func startAnimationsIfNeeded() {
        guard claimState == .claimable else { return }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isGlowing = true
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            bounceOffset = -5
        }
    }
}

// MARK: - Tier Milestone Presets

extension SpeedometerGauge {
    static func bronzeMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 0, coinReward: 0),
            GaugeMilestone(points: 1000, coinReward: 15),
            GaugeMilestone(points: 2000, coinReward: 25),
            GaugeMilestone(points: 4000, coinReward: 50),
            GaugeMilestone(points: 6000, coinReward: 100),
            GaugeMilestone(points: 8000, coinReward: 0),
        ]
    }

    static func silverMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 8000, coinReward: 0),
            GaugeMilestone(points: 12000, coinReward: 50),
            GaugeMilestone(points: 18000, coinReward: 100),
            GaugeMilestone(points: 24000, coinReward: 200),
            GaugeMilestone(points: 30000, coinReward: 350),
        ]
    }

    static func goldMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 30000, coinReward: 0),
            GaugeMilestone(points: 45000, coinReward: 150),
            GaugeMilestone(points: 60000, coinReward: 300),
            GaugeMilestone(points: 80000, coinReward: 500),
            GaugeMilestone(points: 100000, coinReward: 1000),
        ]
    }

    static func platinumMilestones() -> [GaugeMilestone] {
        [
            GaugeMilestone(points: 100000, coinReward: 0),
            GaugeMilestone(points: 150000, coinReward: 500),
            GaugeMilestone(points: 250000, coinReward: 1000),
            GaugeMilestone(points: 500000, coinReward: 2000),
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
        tierStartPoints: 0,
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
        tierStartPoints: 8000,
        tierColor: .billixSilverTier,
        milestones: SpeedometerGauge.silverMilestones()
    )
    .padding()
    .background(Color.white)
}
