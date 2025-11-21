import SwiftUI

struct MarketplaceHighlightsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Trending Bills Card
                    MarketplaceCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .orange,
                        title: "Trending",
                        subtitle: "Electric bills ↑12% this month",
                        backgroundColor: Color.orange.opacity(0.1)
                    )

                    // You vs Community Card
                    MarketplaceCard(
                        icon: "person.2.fill",
                        iconColor: .blue,
                        title: "You vs Community",
                        subtitle: "You pay 8% less than avg",
                        backgroundColor: Color.blue.opacity(0.1)
                    )

                    // Hot Savings Card
                    MarketplaceCard(
                        icon: "flame.fill",
                        iconColor: .red,
                        title: "Hot Savings",
                        subtitle: "$45 opportunity on AT&T",
                        backgroundColor: Color.red.opacity(0.1)
                    )

                    // Trust Score Card
                    MarketplaceCard(
                        icon: "shield.checkered",
                        iconColor: .purple,
                        title: "Trust Score",
                        subtitle: "You're in top 15%",
                        backgroundColor: Color.purple.opacity(0.1)
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct MarketplaceCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .frame(width: 160)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    MarketplaceHighlightsView()
        .background(Color.billixLightGreen)
}
