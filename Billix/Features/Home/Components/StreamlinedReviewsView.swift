import SwiftUI

struct StreamlinedReviewsView: View {
    @State private var reviewIndex = 0

    let reviews = [
        Review(
            text: "Great design and super easy to use—managing finances has never been simpler!",
            author: "Sarah M.",
            rating: 5
        ),
        Review(
            text: "Billix helped me save hundreds on my bills. Highly recommend!",
            author: "Mike T.",
            rating: 5
        ),
        Review(
            text: "The bill tracking feature is a game changer for my budget.",
            author: "Jessica R.",
            rating: 4
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Community Reviews")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // Navigation arrows
                HStack(spacing: 12) {
                    Button(action: {
                        if reviewIndex > 0 {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                reviewIndex -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(reviewIndex > 0 ? .billixLoginTeal : .gray.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(reviewIndex == 0)

                    Button(action: {
                        if reviewIndex < reviews.count - 1 {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                reviewIndex += 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(reviewIndex < reviews.count - 1 ? .billixLoginTeal : .gray.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(reviewIndex == reviews.count - 1)
                }
            }

            // Review Content
            VStack(alignment: .leading, spacing: 12) {
                // Stars
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < reviews[reviewIndex].rating ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(.billixStarGold)
                    }
                }

                // Review Text
                Text(reviews[reviewIndex].text)
                    .font(.system(size: 15))
                    .foregroundColor(.billixDarkGreen)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .id(reviewIndex)

                // Author
                Text("— \(reviews[reviewIndex].author)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.billixLoginTeal.opacity(0.08),
                    Color.billixLoginTeal.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixLoginTeal.opacity(0.2), lineWidth: 1)
        )
    }
}

struct Review {
    let text: String
    let author: String
    let rating: Int
}

#Preview {
    StreamlinedReviewsView()
        .padding()
        .background(Color.billixLightGreen)
}
