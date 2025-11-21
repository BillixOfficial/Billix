import SwiftUI

struct ConsolidatedSavingsCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left Side - Total Savings
            VStack(alignment: .leading, spacing: 6) {
                Text("Total Saved")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Text("$245")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)

                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Right Side - Mini Chart
            VStack(alignment: .trailing, spacing: 8) {
                // Sparkline Chart
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach([0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 1.0], id: \.self) { height in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.billixMoneyGreen.opacity(0.7),
                                        Color.billixMoneyGreen
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 8, height: CGFloat(height) * 50)
                    }
                }
                .frame(height: 50)

                // Top Category
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Top Category")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.billixMoneyGreen)

                        Text("Utilities")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)

                        Text("$120")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.billixMoneyGreen.opacity(0.08),
                    Color.billixMoneyGreen.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ConsolidatedSavingsCard()
        .padding()
        .background(Color.billixLightGreen)
}
