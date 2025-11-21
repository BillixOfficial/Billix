import SwiftUI

struct CompactBillActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill Activity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                // Pending Bills Pill
                BillActivityPill(
                    count: "16",
                    label: "Pending",
                    icon: "clock.fill",
                    backgroundColor: Color.orange.opacity(0.1),
                    textColor: .orange
                )

                // Completed Bills Pill
                BillActivityPill(
                    count: "8",
                    label: "Done",
                    icon: "checkmark.circle.fill",
                    backgroundColor: Color.green.opacity(0.1),
                    textColor: .green
                )

                // Active Bills Pill
                BillActivityPill(
                    count: "5",
                    label: "Active",
                    icon: "bolt.fill",
                    backgroundColor: Color.blue.opacity(0.1),
                    textColor: .blue
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

struct BillActivityPill: View {
    let count: String
    let label: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        VStack(spacing: 6) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(textColor)

            // Count
            Text(count)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.billixDarkGreen)

            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(textColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    CompactBillActivityView()
        .padding()
        .background(Color.billixLightGreen)
}
