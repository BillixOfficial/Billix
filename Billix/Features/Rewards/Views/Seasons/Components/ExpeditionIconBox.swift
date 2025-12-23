import SwiftUI

struct ExpeditionIconBox: View {
    let partNumber: Int
    let isUnlocked: Bool

    var body: some View {
        ZStack {
            // Orange-to-Red gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#F97316"),  // Orange
                    Color(hex: "#E11D48")   // Red
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
            .frame(width: 60, height: 60)

            // Part number or lock icon
            if isUnlocked {
                Text("\(partNumber)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .opacity(0.6)
            }
        }
        .frame(width: 60, height: 60)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpeditionIconBox(partNumber: 1, isUnlocked: true)
        ExpeditionIconBox(partNumber: 2, isUnlocked: false)
    }
    .padding()
}
