//
//  BillGaugeView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Custom speedometer/gauge view showing bill amount vs area average
struct BillGaugeView: View {
    let billAmount: Double
    let areaAverage: Double
    let percentDiff: Double
    let position: BillAnalysis.MarketplaceComparison.Position

    @State private var animatedNeedle: Double = 0
    @State private var animatedAmount: Double = 0
    @State private var appeared = false

    // Calculate needle position (0 to 1 where 0.5 is average)
    private var needlePosition: Double {
        // Clamp percent diff to -50% to +50% range, map to 0-1
        let clampedDiff = max(-50, min(50, percentDiff))
        return (clampedDiff + 50) / 100.0
    }

    private var positionColor: Color {
        switch position {
        case .below: return .billixMoneyGreen
        case .average: return .billixChartBlue
        case .above: return .billixVotePink
        }
    }

    private var positionText: String {
        switch position {
        case .below: return "Below Average"
        case .average: return "Average"
        case .above: return "Above Average"
        }
    }

    private var positionIcon: String {
        switch position {
        case .below: return "arrow.down.circle.fill"
        case .average: return "equal.circle.fill"
        case .above: return "arrow.up.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main gauge
            ZStack {
                // Background arc
                GaugeArc()
                    .stroke(
                        LinearGradient(
                            colors: [.billixMoneyGreen, .billixSavingsYellow, .billixVotePink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 100)

                // Background track
                GaugeArc()
                    .stroke(Color.billixBorderGreen.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 100)

                // Needle
                GaugeNeedle()
                    .fill(positionColor)
                    .frame(width: 8, height: 70)
                    .offset(y: -35)
                    .rotationEffect(.degrees(-90 + (animatedNeedle * 180)))

                // Center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                Circle()
                    .fill(positionColor)
                    .frame(width: 12, height: 12)

                // Amount display
                VStack(spacing: 2) {
                    Text("Your Bill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(Int(animatedAmount))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)
                        .contentTransition(.numericText())
                }
                .offset(y: 60)
            }
            .frame(height: 160)

            // Comparison info
            VStack(spacing: 8) {
                // Position badge
                HStack(spacing: 6) {
                    Image(systemName: positionIcon)
                        .font(.system(size: 14, weight: .semibold))

                    Text(positionText)
                        .font(.system(size: 14, weight: .semibold))

                    Text(percentDiffText)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(positionColor.opacity(0.15))
                        )
                }
                .foregroundColor(positionColor)

                // Billix average
                HStack(spacing: 4) {
                    Text("Billix Average:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(String(format: "%.2f", areaAverage))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            // Animate needle
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedNeedle = needlePosition
            }
            // Animate amount
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedAmount = billAmount
            }
        }
    }

    private var percentDiffText: String {
        let sign = percentDiff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentDiff))%"
    }
}

// MARK: - Custom Shapes

struct GaugeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        return path
    }
}

struct GaugeNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY
        let width = rect.width / 2

        path.move(to: CGPoint(x: midX, y: topY))
        path.addLine(to: CGPoint(x: midX + width, y: bottomY))
        path.addLine(to: CGPoint(x: midX - width, y: bottomY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Fallback Gauge (when no comparison data)

struct SimpleBillGaugeView: View {
    let billAmount: Double
    let provider: String
    let category: String

    @State private var animatedAmount: Double = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Provider badge
            HStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixChartBlue)

                Text(provider)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.billixChartBlue.opacity(0.1))
            )

            // Amount
            VStack(spacing: 4) {
                Text("Total Amount")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                Text("$\(String(format: "%.2f", animatedAmount))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
                    .contentTransition(.numericText())
            }

            // Category
            Text(category)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.billixLightGreenText)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedAmount = billAmount
            }
        }
    }

    private var categoryIcon: String {
        switch category.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet": return "wifi"
        case "phone": return "phone.fill"
        default: return "doc.text.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            BillGaugeView(
                billAmount: 142.50,
                areaAverage: 128.00,
                percentDiff: 11.3,
                position: .above
            )

            BillGaugeView(
                billAmount: 95.00,
                areaAverage: 128.00,
                percentDiff: -25.8,
                position: .below
            )

            SimpleBillGaugeView(
                billAmount: 142.50,
                provider: "DTE Energy",
                category: "Electric"
            )
        }
        .padding()
    }
    .background(Color.billixLightGreen)
}
