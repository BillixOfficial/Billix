import SwiftUI

/// Bills Explorer - Coming Soon placeholder
struct BillsExploreView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.billixCreamBeige.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundColor(Color.billixDarkTeal.opacity(0.6))

                // Text
                VStack(spacing: 12) {
                    Text("Coming Soon")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text("Bill Explorer is under development.\nStay tuned for updates!")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BillsExploreView()
    }
}
