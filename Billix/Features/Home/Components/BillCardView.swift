import SwiftUI

struct BillCardView: View {
    let billName: String
    let provider: String
    let amount: Double
    let dueDate: Date?
    let category: SavingsOpportunity.BillCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                        .imageScale(.large)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(category.color.opacity(0.15)))

                    Spacer()

                    if let dueDate = dueDate {
                        DueDateBadge(dueDate: dueDate)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(billName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(provider)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Divider()

                HStack {
                    Text("$\(String(format: "%.2f", amount))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("/month")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .imageScale(.small)
                }
            }
            .padding()
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DueDateBadge: View {
    let dueDate: Date

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .imageScale(.small)

            Text(dueDateText)
                .font(.caption)
        }
        .foregroundColor(daysUntilDue <= 3 ? .red : .orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((daysUntilDue <= 3 ? Color.red : Color.orange).opacity(0.15))
        )
    }

    private var dueDateText: String {
        if daysUntilDue == 0 {
            return "Due today"
        } else if daysUntilDue == 1 {
            return "Due tomorrow"
        } else if daysUntilDue < 0 {
            return "Overdue"
        } else {
            return "\(daysUntilDue)d"
        }
    }
}
