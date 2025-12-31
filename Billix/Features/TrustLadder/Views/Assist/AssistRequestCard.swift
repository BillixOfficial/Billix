//
//  AssistRequestCard.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Card component for displaying assist requests in the feed
//

import SwiftUI

// MARK: - Assist Request Card

struct AssistRequestCard: View {
    let request: AssistRequest
    let requesterTrustScore: Int?
    let onTap: () -> Void

    init(
        request: AssistRequest,
        requesterTrustScore: Int? = nil,
        onTap: @escaping () -> Void
    ) {
        self.request = request
        self.requesterTrustScore = requesterTrustScore
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Category + Urgency Badge
                HStack {
                    // Category icon
                    categoryIcon

                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.billProvider)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(request.billCategory)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Urgency badge
                    urgencyBadge
                }

                // Amount requested
                HStack(alignment: .bottom, spacing: 4) {
                    Text("$\(String(format: "%.0f", request.amountRequested))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("needed")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)

                    Spacer()

                    // Preferred terms badge
                    if let terms = request.preferredTerms {
                        termsBadge(terms)
                    }
                }

                // Description (if any)
                if let description = request.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Divider()

                // Footer: Due date + Trust score + Connection fee
                HStack(spacing: 16) {
                    // Due date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(dueDateText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(request.isOverdue ? .red : .secondary)

                    // Trust score
                    if let score = requesterTrustScore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                            Text("\(score) pts")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.orange)
                    }

                    Spacer()

                    // Connection fee
                    Text("$\(String(format: "%.2f", request.connectionFee)) fee")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }

    // MARK: - Subviews

    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: categoryIconName)
                .font(.system(size: 20))
                .foregroundColor(categoryColor)
        }
    }

    private var urgencyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: request.urgency.icon)
                .font(.system(size: 10))
            Text(request.urgency.displayName)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(request.urgency.color)
        .cornerRadius(6)
    }

    private func termsBadge(_ terms: RepaymentTerms) -> some View {
        HStack(spacing: 4) {
            Image(systemName: terms.assistType.icon)
                .font(.system(size: 10))
            Text(terms.assistType.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(terms.assistType.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(terms.assistType.color.opacity(0.15))
        .cornerRadius(6)
    }

    // MARK: - Computed Properties

    private var categoryIconName: String {
        switch request.billCategory.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas", "natural gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet", "wifi": return "wifi"
        case "phone", "mobile": return "phone.fill"
        case "cable", "tv": return "tv.fill"
        case "insurance": return "shield.fill"
        case "rent", "mortgage": return "house.fill"
        default: return "doc.text.fill"
        }
    }

    private var categoryColor: Color {
        switch request.billCategory.lowercased() {
        case "electric", "electricity": return .yellow
        case "gas", "natural gas": return .orange
        case "water": return .blue
        case "internet", "wifi": return .purple
        case "phone", "mobile": return .green
        case "cable", "tv": return .red
        case "insurance": return .indigo
        case "rent", "mortgage": return .brown
        default: return .gray
        }
    }

    private var dueDateText: String {
        let days = request.daysUntilDue
        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(days)d"
        }
    }
}

// MARK: - Compact Card (for horizontal scroll)

struct AssistRequestCompactCard: View {
    let request: AssistRequest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Urgency indicator
                HStack {
                    Circle()
                        .fill(request.urgency.color)
                        .frame(width: 8, height: 8)

                    Text(request.urgency.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(request.urgency.color)

                    Spacer()
                }

                // Amount
                Text("$\(String(format: "%.0f", request.amountRequested))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // Provider
                Text(request.billProvider)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Category
                Text(request.billCategory)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                // Terms badge
                if let terms = request.preferredTerms {
                    Text(terms.assistType.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(terms.assistType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(terms.assistType.color.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .frame(width: 140, height: 160)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }
}

// MARK: - "Need Help?" Creation Card

struct AssistCreateCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Text("Need Help?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Request assistance")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
            )
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }
}

// MARK: - Preview

#if DEBUG
struct AssistRequestCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                AssistRequestCard(
                    request: .preview,
                    requesterTrustScore: 450
                ) {}

                AssistRequestCard(
                    request: .previewCritical,
                    requesterTrustScore: 320
                ) {}

                HStack(spacing: 12) {
                    AssistCreateCard {}

                    AssistRequestCompactCard(request: .preview) {}

                    AssistRequestCompactCard(request: .previewCritical) {}
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
