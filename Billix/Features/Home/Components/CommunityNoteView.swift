import SwiftUI

struct CommunityNoteView: View {
    let totalUsers: Int
    let totalSavings: Double
    let avgSavings: Double
    let monthOverMonth: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.billixPurple)
                    .imageScale(.medium)
                    .symbolEffect(.pulse)

                Text("Community Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.billixDarkGray)

                Spacer()

                Text("US-wide")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixCreamBeige)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.billixPurple, Color.billixLightPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }

            Text("See how Billix users are saving nationwide")
                .font(.subheadline)
                .foregroundColor(.billixDarkTeal)

            HStack(spacing: 12) {
                KPIChip(
                    label: "Users",
                    value: formatNumber(Double(totalUsers)),
                    icon: "person.2.fill",
                    color: .billixPurple
                )

                KPIChip(
                    label: "Total Saved",
                    value: "$\(formatNumber(totalSavings))",
                    icon: "dollarsign.circle.fill",
                    color: .billixMoneyGreen
                )
            }

            HStack(spacing: 12) {
                KPIChip(
                    label: "Avg Savings",
                    value: "$\(String(format: "%.0f", avgSavings))/mo",
                    icon: "chart.bar.fill",
                    color: .billixGold
                )

                KPIChip(
                    label: "Growth",
                    value: "+\(String(format: "%.0f", monthOverMonth))%",
                    icon: "arrow.up.right",
                    color: .billixGoldenAmber
                )
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .imageScale(.small)
                    .foregroundColor(.billixMoneyGreen)

                Text("Updated daily from verified user data")
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .glassMorphic(cornerRadius: 20)
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct KPIChip: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .imageScale(.small)
                    .foregroundColor(color)
                    .symbolEffect(.pulse)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
