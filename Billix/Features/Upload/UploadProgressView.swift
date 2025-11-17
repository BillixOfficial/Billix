import SwiftUI

struct UploadProgressView: View {
    let progress: Double
    let message: String
    let onCancel: () -> Void

    @State private var animateGlow = false
    @State private var showMessage = false

    var body: some View {
        ZStack {
            Color.billixCreamBeige.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Animated header
                VStack(spacing: 16) {
                    Text(headerText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)
                        .multilineTextAlignment(.center)

                    Text(headerSubtext)
                        .font(.subheadline)
                        .foregroundColor(.billixDarkTeal)
                        .multilineTextAlignment(.center)
                        .opacity(showMessage ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showMessage)
                }
                .padding(.horizontal, 40)

                // Enhanced progress indicator
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.billixMoneyGreen.opacity(animateGlow ? 0.3 : 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGlow)

                    CircularProgressView(progress: progress, statusMessage: message)
                }

                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                // Cancel button
                Button(action: onCancel) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.title3)
                        Text("Cancel Upload")
                            .font(.headline)
                    }
                    .foregroundColor(.billixNavyBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.billixNavyBlue.opacity(0.1), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            animateGlow = true
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                showMessage = true
            }
        }
    }

    // MARK: - Computed Properties

    private var headerText: String {
        if progress < 0.3 {
            return "Uploading Bill"
        } else if progress < 0.7 {
            return "Analyzing with AI"
        } else {
            return "Almost Done"
        }
    }

    private var headerSubtext: String {
        if progress < 0.3 {
            return "Securely uploading your document"
        } else if progress < 0.7 {
            return "AI is reading and analyzing your bill"
        } else {
            return "Generating insights and comparisons"
        }
    }
}
