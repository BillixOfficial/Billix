import SwiftUI

/// Placeholder for Receipt Scanning functionality
/// TODO: Implement camera integration with AVFoundation
struct ReceiptScanView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.billixMoneyGreen)

                VStack(spacing: 12) {
                    Text("Receipt Scanner")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Text("Camera integration coming soon")
                        .font(.system(size: 16))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 12) {
                    Text("Features:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "camera.viewfinder", text: "Real-time receipt scanning")
                        FeatureRow(icon: "doc.text.magnifyingglass", text: "Automatic text recognition")
                        FeatureRow(icon: "checkmark.circle", text: "Smart bill categorization")
                        FeatureRow(icon: "arrow.down.doc", text: "Auto-fill bill details")
                    }
                }
                .padding(20)
                .billixCard()
                .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.billixLoginTeal)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.billixLightGreen.ignoresSafeArea())
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.billixMediumGreen)
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.billixLoginTeal)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.billixDarkGreen)

            Spacer()
        }
    }
}

#Preview {
    ReceiptScanView()
}
