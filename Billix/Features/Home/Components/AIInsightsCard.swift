import SwiftUI

struct AIInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)

                Text("Billix found 3 ways to save $127")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()
            }

            // Insights List
            VStack(alignment: .leading, spacing: 10) {
                InsightRow(
                    icon: "antenna.radiowaves.left.and.right",
                    text: "Switch to Mint Mobile",
                    savings: "$45/mo"
                )

                InsightRow(
                    icon: "bolt.fill",
                    text: "Better electricity rate available",
                    savings: "$52/mo"
                )

                InsightRow(
                    icon: "wifi",
                    text: "Downgrade internet speed",
                    savings: "$30/mo"
                )
            }

            // View All Button
            Button(action: {
                // UI only
            }) {
                HStack {
                    Text("View All Insights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixLoginTeal)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.billixLoginTeal)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.08),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let savings: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.billixLoginTeal)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.billixDarkGreen)

            Spacer()

            Text(savings)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixMoneyGreen)
        }
    }
}

#Preview {
    AIInsightsCard()
        .padding()
        .background(Color.billixLightGreen)
}
