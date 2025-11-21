import SwiftUI

struct BillHealthScoreCard: View {
    let healthScore: BillHealthScore
    let onTap: () -> Void

    @State private var animatedScore: Double = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bill Health Score")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(healthScore.interpretation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                        .imageScale(.medium)
                }

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: animatedScore / 100)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: healthScore.gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: animatedScore)

                    VStack(spacing: 4) {
                        Text("\(Int(animatedScore))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(healthScore.color)

                        Text(healthScore.statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
                .frame(height: 160)
                .padding(.vertical, 8)

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .imageScale(.small)

                    Text("Tap for detailed insights")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()

                    Text("Updated \(relativeTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animatedScore = Double(healthScore.score)
            }
        }
    }

    private var trendIcon: String {
        switch healthScore.trend {
        case .improving:
            return "arrow.up.right.circle.fill"
        case .stable:
            return "minus.circle.fill"
        case .declining:
            return "arrow.down.right.circle.fill"
        }
    }

    private var trendColor: Color {
        switch healthScore.trend {
        case .improving:
            return .green
        case .stable:
            return .blue
        case .declining:
            return .red
        }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: healthScore.lastUpdated, relativeTo: Date())
    }
}
