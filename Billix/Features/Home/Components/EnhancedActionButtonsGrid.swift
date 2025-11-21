import SwiftUI

struct EnhancedActionButtonsGrid: View {
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                EnhancedActionButton(
                    icon: "message.fill",
                    label: "Chat",
                    gradient: [Color.billixChatBlue, Color.billixChatBlue.opacity(0.8)],
                    badge: "8"
                )

                EnhancedActionButton(
                    icon: "dollarsign.circle.fill",
                    label: "Funding",
                    gradient: [Color.billixFundingPurple, Color.billixFundingPurple.opacity(0.8)],
                    badge: nil
                )

                EnhancedActionButton(
                    icon: "hand.thumbsup.fill",
                    label: "Vote",
                    gradient: [Color.billixVotePink, Color.billixVotePink.opacity(0.8)],
                    badge: "8"
                )

                EnhancedActionButton(
                    icon: "questionmark.circle.fill",
                    label: "FAQ",
                    gradient: [Color.billixFaqGreen, Color.billixFaqGreen.opacity(0.8)],
                    badge: nil
                )

                EnhancedActionButton(
                    icon: "arrow.up.doc.fill",
                    label: "Upload",
                    gradient: [Color.billixLoginTeal, Color.billixLoginTeal.opacity(0.8)],
                    badge: nil
                )

                EnhancedActionButton(
                    icon: "arrow.left.arrow.right",
                    label: "Compare",
                    gradient: [Color.orange, Color.orange.opacity(0.8)],
                    badge: nil
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct EnhancedActionButton: View {
    let icon: String
    let label: String
    let gradient: [Color]
    let badge: String?

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)

                    // Badge
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -6, y: 6)
                    }
                }

                // Label
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    EnhancedActionButtonsGrid()
        .padding()
        .background(Color.billixLightGreen)
}
