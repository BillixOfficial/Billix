import SwiftUI

struct AnimatedHeroHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Animated icon with phase animator
            Image(systemName: "doc.text.image.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.billixGoldenAmber, .billixDarkTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .billixGoldenAmber.opacity(0.3), radius: 20, x: 0, y: 10)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.05 : 1.0)
                        .rotationEffect(.degrees(phase ? 2 : -2))
                } animation: { _ in
                    .spring(duration: 2, bounce: 0.5).repeatForever()
                }

            // Title and subtitle
            VStack(spacing: 8) {
                Text("Turn Bills into Assets")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.billixNavyBlue)
                    .multilineTextAlignment(.center)

                Text("Upload and analyze your bills with AI-powered insights")
                    .font(.subheadline)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Upload bills for AI analysis")
    }
}

#Preview {
    AnimatedHeroHeader()
        .padding()
        .background(Color.billixCreamBeige)
}
