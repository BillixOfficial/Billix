//
//  BillCard.swift
//  Billix
//
//  Redesigned bill card with category gradient and refined styling
//

import SwiftUI

struct BillCard: View {
    let bill: SwapBill
    var showOwner: Bool = false
    var ownerName: String? = nil
    var ownerHandle: String? = nil
    var onTap: (() -> Void)? = nil
    var onMenuAction: ((BillCardAction) -> Void)? = nil

    @State private var isPressed = false

    enum BillCardAction {
        case edit
        case delete
        case offer
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Header with gradient
                HStack {
                    // Category icon
                    CategoryIcon(category: bill.category.rawValue, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bill.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BillSwapTheme.primaryText)
                            .lineLimit(1)

                        if let provider = bill.providerName {
                            Text(provider)
                                .font(.system(size: 12))
                                .foregroundColor(BillSwapTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(bill.formattedAmount)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(BillSwapTheme.accent)

                        // Status or due info
                        if bill.status == .active {
                            dueBadge
                        } else {
                            statusBadge
                        }
                    }
                }
                .padding(14)

                // Divider
                Rectangle()
                    .fill(BillSwapTheme.secondaryText.opacity(0.08))
                    .frame(height: 1)

                // Footer
                HStack {
                    // Owner info (for available bills)
                    if showOwner, let handle = ownerHandle {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 12))
                            Text("@\(handle)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(BillSwapTheme.secondaryText)
                    } else {
                        // Category label
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 10))
                            Text(bill.category.displayName)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(categoryColor)
                    }

                    Spacer()

                    // Due date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text("Due \(formattedDueDate)")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(dueDateColor)

                    // Menu button (for owned bills)
                    if !showOwner && onMenuAction != nil {
                        Menu {
                            if bill.status == .draft {
                                Button {
                                    onMenuAction?(.edit)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }

                            if bill.status == .active || bill.status == .draft {
                                Button(role: .destructive) {
                                    onMenuAction?(.delete)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(BillSwapTheme.secondaryText)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(categoryColor.opacity(0.04))
            }
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
            .overlay(
                RoundedRectangle(cornerRadius: BillSwapTheme.cardCornerRadius)
                    .stroke(categoryColor.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var dueBadge: some View {
        let days = bill.daysUntilDue

        HStack(spacing: 3) {
            if days < 0 {
                Text("Overdue")
            } else if days == 0 {
                Text("Due today")
            } else if days <= 3 {
                Text("\(days)d left")
            } else {
                Text("\(days) days")
            }
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(dueDateColor)
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(bill.status.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(statusColor)
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        BillSwapTheme.categoryColor(for: bill.category.rawValue)
    }

    private var categoryIcon: String {
        BillSwapTheme.categoryIcon(for: bill.category.rawValue)
    }

    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bill.dueDate)
    }

    private var dueDateColor: Color {
        if bill.isOverdue {
            return BillSwapTheme.statusDispute
        } else if bill.isDueSoon {
            return BillSwapTheme.statusPending
        }
        return BillSwapTheme.secondaryText
    }

    private var statusColor: Color {
        switch bill.status {
        case .active:
            return BillSwapTheme.statusActive
        case .lockedInSwap:
            return BillSwapTheme.statusLocked
        case .paidConfirmed:
            return BillSwapTheme.statusComplete
        case .draft:
            return BillSwapTheme.secondaryText
        default:
            return BillSwapTheme.statusCancelled
        }
    }
}

// MARK: - Available Bill Card (for browsing)

struct AvailableBillCard: View {
    let bill: SwapBillWithOwner
    var onTap: (() -> Void)? = nil
    var onOffer: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Main content
                HStack(alignment: .top, spacing: 12) {
                    // Category icon with gradient background
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor.opacity(0.15), categoryColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 24))
                            .foregroundColor(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Title and provider
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bill.bill.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(BillSwapTheme.primaryText)
                                .lineLimit(1)

                            if let provider = bill.bill.providerName {
                                Text(provider)
                                    .font(.system(size: 12))
                                    .foregroundColor(BillSwapTheme.secondaryText)
                            }
                        }

                        // Owner
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 11))
                            Text("@\(bill.ownerHandle ?? "unknown")")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BillSwapTheme.accent)
                    }

                    Spacer()

                    // Amount and due date
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(bill.bill.formattedAmount)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(BillSwapTheme.primaryText)

                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(formattedDueDate)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(dueDateColor)
                    }
                }
                .padding(14)

                // Offer button
                if onOffer != nil {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onOffer?()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 12))
                            Text("Make Offer")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(BillSwapTheme.accent)
                    }
                    .cornerRadius(0)
                }
            }
            .background(BillSwapTheme.cardBackground)
            .cornerRadius(BillSwapTheme.cardCornerRadius)
            .shadow(
                color: BillSwapTheme.cardShadow,
                radius: BillSwapTheme.cardShadowRadius,
                x: 0,
                y: BillSwapTheme.cardShadowY
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        BillSwapTheme.categoryColor(for: bill.bill.category.rawValue)
    }

    private var categoryIcon: String {
        BillSwapTheme.categoryIcon(for: bill.bill.category.rawValue)
    }

    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bill.bill.dueDate)
    }

    private var dueDateColor: Color {
        if bill.bill.isOverdue {
            return BillSwapTheme.statusDispute
        } else if bill.bill.isDueSoon {
            return BillSwapTheme.statusPending
        }
        return BillSwapTheme.secondaryText
    }
}

// MARK: - Preview

#Preview("Bill Card") {
    VStack(spacing: 16) {
        BillCard(
            bill: SwapBill(
                id: UUID(),
                ownerUserId: UUID(),
                title: "Electric Bill",
                category: .electric,
                providerName: "ConEd",
                amountCents: 8500,
                dueDate: Date().addingTimeInterval(86400 * 2),
                status: .active,
                paymentUrl: nil,
                accountNumberLast4: nil,
                billImageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ) { action in
            print("Action: \(action)")
        }

        BillCard(
            bill: SwapBill(
                id: UUID(),
                ownerUserId: UUID(),
                title: "Water Bill",
                category: .water,
                providerName: "City Water",
                amountCents: 4500,
                dueDate: Date().addingTimeInterval(86400 * 10),
                status: .active,
                paymentUrl: nil,
                accountNumberLast4: nil,
                billImageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            showOwner: true,
            ownerHandle: "johndoe"
        )
    }
    .padding()
    .background(BillSwapTheme.background)
}
