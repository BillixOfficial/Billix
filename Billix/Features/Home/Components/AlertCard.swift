import SwiftUI

struct AlertCard: View {
    let alert: HomeAlert
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.type.icon)
                .foregroundColor(alert.type.color)
                .imageScale(.large)
                .frame(width: 40, height: 40)
                .background(Circle().fill(alert.type.color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    if !alert.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                if let daysUntil = alert.daysUntilDue {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .imageScale(.small)

                        Text(daysUntilText(days: daysUntil))
                            .font(.caption)

                        Spacer()
                    }
                    .foregroundColor(daysUntil <= 3 ? .red : .orange)
                }

                if let actionTitle = alert.actionTitle {
                    Text(actionTitle)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .imageScale(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .onTapGesture {
            onTap()
        }
    }

    private var borderColor: Color {
        if alert.priority == .high && !alert.isRead {
            return alert.type.color.opacity(0.3)
        }
        return Color.clear
    }

    private var borderWidth: CGFloat {
        if alert.priority == .high && !alert.isRead {
            return 2
        }
        return 0
    }

    private func daysUntilText(days: Int) -> String {
        if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days < 0 {
            return "Overdue by \(abs(days)) days"
        } else {
            return "Due in \(days) days"
        }
    }
}
