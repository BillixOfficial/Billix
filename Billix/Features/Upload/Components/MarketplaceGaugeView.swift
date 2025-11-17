import SwiftUI

struct MarketplaceGaugeView: View {
    let comparison: BillAnalysis.MarketplaceComparison
    let userAmount: Double

    @State private var animateNeedle = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(positionColor)
                Text("Marketplace Comparison")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixNavyBlue)
            }

            // Gauge
            ZStack {
                // Background arc zones
                gaugeBackground

                // Needle
                needle
                    .rotationEffect(.degrees(needleAngle), anchor: .bottom)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateNeedle)

                // Center dot
                Circle()
                    .fill(Color.billixNavyBlue)
                    .frame(width: 12, height: 12)
                    .offset(y: 80)
            }
            .frame(height: 200)

            // Labels
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text("Your Bill")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                    Text(formatCurrency(userAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 50)

                VStack(spacing: 4) {
                    Text("Area Avg (ZIP \(comparison.zipPrefix)**)")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                    Text(formatCurrency(comparison.areaAverage))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)
                }
                .frame(maxWidth: .infinity)
            }

            // Status message
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: positionIcon)
                        .font(.title3)
                        .foregroundColor(positionColor)

                    Text(statusMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.billixNavyBlue)
                        .multilineTextAlignment(.center)
                }

                if comparison.position == .below {
                    Text("You're saving \(formatCurrency(abs(userAmount - comparison.areaAverage))) compared to average!")
                        .font(.caption)
                        .foregroundColor(.billixMoneyGreen)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(positionColor.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.billixNavyBlue.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            // Delay animation slightly for better effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateNeedle = true

                // Show confetti if user is below average
                if comparison.position == .below {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showConfetti = true
                    }
                }
            }
        }
    }

    // MARK: - Gauge Components

    private var gaugeBackground: some View {
        ZStack {
            // Below zone (green) - left third
            Arc(startAngle: .degrees(180), endAngle: .degrees(240))
                .stroke(Color.billixMoneyGreen, lineWidth: 20)
                .frame(width: 160, height: 160)

            // Average zone (yellow) - middle third
            Arc(startAngle: .degrees(240), endAngle: .degrees(300))
                .stroke(Color.yellow, lineWidth: 20)
                .frame(width: 160, height: 160)

            // Above zone (red) - right third
            Arc(startAngle: .degrees(300), endAngle: .degrees(360))
                .stroke(Color.red, lineWidth: 20)
                .frame(width: 160, height: 160)

            // Zone labels
            Text("Lower")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.billixMoneyGreen)
                .offset(x: -80, y: 40)

            Text("Average")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .offset(x: 0, y: -10)

            Text("Higher")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .offset(x: 80, y: 40)
        }
        .offset(y: 80)
    }

    private var needle: some View {
        ZStack {
            // Needle triangle
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color.billixNavyBlue, Color.billixNavyBlue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6, height: 90)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 1)
        }
        .offset(y: 35)
    }

    // MARK: - Computed Properties

    private var needleAngle: Double {
        if !animateNeedle {
            return -90 // Start at left (below average)
        }

        // Map percentDiff to angle
        // -100% -> -90° (far left), 0% -> 0° (center), +100% -> 90° (far right)
        let clampedDiff = max(-100, min(100, comparison.percentDiff))
        return clampedDiff * 0.9 // Scale to ±90 degrees
    }

    private var positionColor: Color {
        switch comparison.position {
        case .below:
            return .billixMoneyGreen
        case .average:
            return .orange
        case .above:
            return .red
        }
    }

    private var positionIcon: String {
        switch comparison.position {
        case .below:
            return "checkmark.circle.fill"
        case .average:
            return "minus.circle.fill"
        case .above:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusMessage: String {
        let percentText = String(format: "%.1f%%", abs(comparison.percentDiff))

        switch comparison.position {
        case .below:
            return "Excellent! You're paying \(percentText) less than average"
        case .average:
            return "You're paying around the area average"
        case .above:
            return "You're paying \(percentText) more than average"
        }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

// MARK: - Custom Shapes

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
