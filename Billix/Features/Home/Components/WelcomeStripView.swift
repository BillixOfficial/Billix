import SwiftUI

struct WelcomeStripView: View {
    let userName: String
    let monthlyDifference: Double

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }

    private var differenceText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0

        let absValue = abs(monthlyDifference)
        let amount = formatter.string(from: NSNumber(value: absValue)) ?? "$0"

        if monthlyDifference > 0 {
            return "You're \(amount) under budget this month"
        } else if monthlyDifference < 0 {
            return "You're \(amount) over budget this month"
        } else {
            return "You're right on budget this month"
        }
    }

    private var differenceColor: Color {
        if monthlyDifference > 0 {
            return .green
        } else if monthlyDifference < 0 {
            return .red
        } else {
            return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greetingText), \(userName)!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack(spacing: 6) {
                Image(systemName: monthlyDifference >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(differenceColor)

                Text(differenceText)
                    .font(.subheadline)
                    .foregroundColor(differenceColor)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
