import SwiftUI

struct BillSummaryCard: View {
    let analysis: BillAnalysis
    let onShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 20) {
            // Provider and status badge
            HStack {
                // Category icon with color coding
                ZStack {
                    Circle()
                        .fill(categoryColor(for: analysis.category).opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: categoryIcon(for: analysis.category))
                        .font(.title2)
                        .foregroundColor(categoryColor(for: analysis.category))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.provider)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text(analysis.category)
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Amount - Hero element
            VStack(spacing: 8) {
                Text(formatCurrency(analysis.amount))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixDarkTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 8, x: 0, y: 4)

                Text("Total Amount")
                    .font(.subheadline)
                    .foregroundColor(.billixDarkTeal)
            }
            .padding(.vertical, 8)

            // Bill and due date
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Bill Date")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                    Text(formatDateString(analysis.billDate))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixNavyBlue)
                }

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                    Text(analysis.dueDate.map { formatDateString($0) } ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.billixNavyBlue)
                }
            }

            // Quick action chips
            HStack(spacing: 12) {
                ActionChip(icon: "square.and.arrow.up", label: "Share", action: onShare)
                ActionChip(icon: "pencil", label: "Edit", action: onEdit)
                ActionChip(icon: "trash", label: "Delete", action: onDelete, isDestructive: true)
            }
        }
        .padding(24)
        .background(
            ZStack {
                // Glassmorphic background
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.billixNavyBlue.opacity(0.1), radius: 20, x: 0, y: 10)

                // Gradient border
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.billixMoneyGreen.opacity(0.5),
                                Color.billixDarkTeal.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        // Determine status based on marketplace comparison
        if let comparison = analysis.marketplaceComparison {
            switch comparison.position {
            case .below:
                return .billixMoneyGreen
            case .average:
                return .orange
            case .above:
                return .red
            }
        }
        return .billixDarkTeal
    }

    private var statusText: String {
        if let comparison = analysis.marketplaceComparison {
            switch comparison.position {
            case .below:
                return "Great Rate"
            case .average:
                return "Average"
            case .above:
                return "High Rate"
            }
        }
        return "Analyzed"
    }

    // MARK: - Helper Functions

    private func categoryIcon(for category: String) -> String {
        let lowercased = category.lowercased()

        switch lowercased {
        case let c where c.contains("electric") || c.contains("power"):
            return "bolt.fill"
        case let c where c.contains("water"):
            return "drop.fill"
        case let c where c.contains("gas"):
            return "flame.fill"
        case let c where c.contains("internet") || c.contains("telecom"):
            return "wifi"
        case let c where c.contains("phone"):
            return "phone.fill"
        case let c where c.contains("insurance"):
            return "shield.fill"
        case let c where c.contains("rent") || c.contains("mortgage"):
            return "house.fill"
        default:
            return "doc.text.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
        let lowercased = category.lowercased()

        switch lowercased {
        case let c where c.contains("electric") || c.contains("power"):
            return .blue
        case let c where c.contains("water"):
            return .cyan
        case let c where c.contains("gas"):
            return .orange
        case let c where c.contains("internet") || c.contains("telecom"):
            return .purple
        case let c where c.contains("phone"):
            return .indigo
        case let c where c.contains("insurance"):
            return .green
        case let c where c.contains("rent") || c.contains("mortgage"):
            return .brown
        default:
            return .billixDarkTeal
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    private func formatDateString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Action Chip Component

struct ActionChip: View {
    let icon: String
    let label: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .billixNavyBlue)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(isDestructive ? .red : .billixDarkTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive ? Color.red.opacity(0.1) : Color.white.opacity(0.8))
            )
        }
        .buttonStyle(.plain)
    }
}
