import SwiftUI

struct ExpeditionActionButton: View {
    let isUnlocked: Bool
    let requiredPart: Int?

    var body: some View {
        if isUnlocked {
            // Green START button
            Text("START")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 44)
                .background(Color.green)
                .cornerRadius(8)
        } else {
            // Locked state
            VStack(spacing: 2) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                if let required = requiredPart {
                    Text("Complete\nPart \(required)")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Locked")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.secondary)
            .opacity(0.6)
            .frame(width: 80, height: 44)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpeditionActionButton(isUnlocked: true, requiredPart: nil)
        ExpeditionActionButton(isUnlocked: false, requiredPart: 1)
    }
    .padding()
}
