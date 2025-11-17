import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
            }

            // Error message
            VStack(spacing: 8) {
                Text("Upload Failed")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.billixNavyBlue)

                Text(message)
                    .font(.body)
                    .foregroundColor(.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }

                Button(action: onDismiss) {
                    Text("Cancel")
                        .foregroundColor(.billixNavyBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.billixCreamBeige.ignoresSafeArea())
    }
}

#Preview {
    ErrorView(
        message: "The file you selected is too large. Please choose a file smaller than 10MB.",
        onRetry: {},
        onDismiss: {}
    )
}
