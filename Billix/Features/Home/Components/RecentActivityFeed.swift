import SwiftUI

struct RecentActivityFeed: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Happening on Billix")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            VStack(spacing: 10) {
                ActivityItem(
                    initials: "SJ",
                    backgroundColor: .purple,
                    text: "Sarah J. saved $32 switching to Mint Mobile",
                    time: "2h ago"
                )

                ActivityItem(
                    initials: "MB",
                    backgroundColor: .blue,
                    text: "New bill comparison: T-Mobile vs Verizon",
                    time: "5h ago"
                )

                ActivityItem(
                    initials: "KL",
                    backgroundColor: .green,
                    text: "Trending: Auto insurance rates ↑8%",
                    time: "1d ago"
                )

                ActivityItem(
                    initials: "DJ",
                    backgroundColor: .orange,
                    text: "David J. verified Comcast overcharge",
                    time: "2d ago"
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ActivityItem: View {
    let initials: String
    let backgroundColor: Color
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(backgroundColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(initials)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(backgroundColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

#Preview {
    RecentActivityFeed()
        .padding()
        .background(Color.billixLightGreen)
}
