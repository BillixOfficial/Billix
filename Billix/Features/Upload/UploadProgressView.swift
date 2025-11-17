import SwiftUI

struct UploadProgressView: View {
    let progress: Double
    let message: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress indicator with status message
            CircularProgressView(progress: progress, statusMessage: message)

            Spacer()

            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.billixNavyBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.billixCreamBeige.ignoresSafeArea())
    }
}

#Preview {
    UploadProgressView(
        progress: 0.65,
        message: "Analyzing your bill...",
        onCancel: {}
    )
}
