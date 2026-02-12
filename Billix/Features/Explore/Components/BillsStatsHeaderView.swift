import SwiftUI

/// Live statistics dashboard for the Bills Marketplace
struct BillsStatsHeaderView: View {
    let totalProviders: Int
    let averageSavings: Double
    let totalSamples: Int
    @State private var animateNumbers = false

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bills Marketplace")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Compare bills in your area")
                        .font(.subheadline)
                        .foregroundColor(.billixDarkTeal)
                }

                Spacer()

                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.billixGold)
                    .symbolEffect(.bounce, value: animateNumbers)
            }

            // Stats grid
            HStack(spacing: 12) {
                StatCard(
                    icon: "building.2.fill",
                    value: "\(totalProviders)",
                    label: "Providers",
                    color: .billixMoneyGreen,
                    animate: animateNumbers
                )

                StatCard(
                    icon: "dollarsign.circle.fill",
                    value: "$\(Int(averageSavings))",
                    label: "Avg Savings",
                    color: .billixGold,
                    animate: animateNumbers
                )

                StatCard(
                    icon: "doc.text.fill",
                    value: formatNumber(totalSamples),
                    label: "Bills",
                    color: .billixPurple,
                    animate: animateNumbers
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.billixCreamBeige.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.billixNavyBlue.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateNumbers = true
            }
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fK", thousands)
        }
        return "\(number)"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let animate: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)

            // Value
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.billixNavyBlue)
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1.0 : 0.0)

            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.billixDarkTeal.opacity(0.8))
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.5))
        )
    }
}

// MARK: - Preview

struct BillsStatsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        BillsStatsHeaderView(
        totalProviders: 45,
        averageSavings: 87.50,
        totalSamples: 3420
        )
        
        BillsStatsHeaderView(
        totalProviders: 12,
        averageSavings: 42.30,
        totalSamples: 156
        )
        }
        .padding()
        .background(Color.billixCreamBeige.opacity(0.3))
    }
}
