import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let statusMessage: String

    private let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            .billixGoldenAmber,
                            .billixDarkTeal,
                            .billixMoneyGreen,
                            .billixGoldenAmber
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8, bounce: 0.2), value: progress)

            // Center content
            VStack(spacing: 8) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.billixNavyBlue)
                    .contentTransition(.numericText())
                    .animation(.default, value: progress)

                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
            }
        }
        .frame(width: 140, height: 140)
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.35, statusMessage: "Uploading...")
        CircularProgressView(progress: 0.75, statusMessage: "Analyzing...")
        CircularProgressView(progress: 1.0, statusMessage: "Complete!")
    }
    .padding()
    .background(Color.billixCreamBeige)
}
