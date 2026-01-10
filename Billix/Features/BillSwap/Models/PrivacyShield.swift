//
//  PrivacyShield.swift
//  Billix
//
//  Privacy Shield Model for Redacting Bill Information in P2P Swaps
//

import Foundation

// MARK: - Redacted Bill Info

/// Bill information with sensitive data redacted for counterparty viewing
struct RedactedBillInfo: Identifiable {
    let id: UUID
    let billerName: String
    let amountCents: Int
    let accountLast4: String?
    let category: SwapBillCategory
    let dueDate: Date
    let ownerTier: SwapTrustTier
    let ownerDisplayName: String?

    // MARK: - Computed Properties

    /// Formatted amount (e.g., "$65.00")
    var formattedAmount: String {
        String(format: "$%.2f", Double(amountCents) / 100.0)
    }

    /// Masked account number (e.g., "••••1234")
    var maskedAccountNumber: String {
        guard let last4 = accountLast4 else { return "••••••••" }
        return "••••\(last4)"
    }

    /// Days until due
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    /// Formatted due date
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    /// Due date urgency text
    var dueDateUrgencyText: String {
        let days = daysUntilDue
        switch days {
        case ..<0: return "Overdue"
        case 0: return "Due today"
        case 1: return "Due tomorrow"
        case 2...3: return "Due in \(days) days"
        case 4...7: return "Due this week"
        default: return "Due \(formattedDueDate)"
        }
    }

    /// Is bill urgent (due within 3 days)
    var isUrgent: Bool {
        daysUntilDue <= 3
    }

    /// Is bill overdue
    var isOverdue: Bool {
        daysUntilDue < 0
    }

    /// Category display name
    var categoryDisplayName: String {
        category.displayName
    }

    /// Category icon
    var categoryIcon: String {
        category.icon
    }

    /// Owner tier badge color
    var tierBadgeColor: String {
        ownerTier.color
    }

    /// Owner tier display name
    var tierDisplayName: String {
        ownerTier.displayName
    }

    // MARK: - Factory Method

    /// Create redacted info from a full SwapBill
    static func fromBill(_ bill: SwapBill, ownerProfile: TrustProfile?) -> RedactedBillInfo {
        RedactedBillInfo(
            id: bill.id,
            billerName: bill.providerName ?? bill.title,
            amountCents: bill.amountCents,
            accountLast4: bill.accountNumberLast4,
            category: bill.category,
            dueDate: bill.dueDate,
            ownerTier: ownerProfile?.tier ?? .T1_PROVISIONAL,
            ownerDisplayName: ownerProfile?.displayName ?? ownerProfile?.handle
        )
    }
}

// MARK: - Privacy Level

/// Different levels of information visibility
enum PrivacyLevel {
    case full           // Owner sees everything
    case redacted       // Counterparty sees limited info
    case minimal        // Public feed sees minimal info

    /// Fields visible at this privacy level
    var visibleFields: Set<BillField> {
        switch self {
        case .full:
            return Set(BillField.allCases)
        case .redacted:
            return [.billerName, .amount, .accountLast4, .category, .dueDate, .ownerTier]
        case .minimal:
            return [.category, .amountRange]
        }
    }
}

/// Bill fields for privacy control
enum BillField: String, CaseIterable {
    case billerName
    case amount
    case amountRange
    case accountLast4
    case fullAccountNumber
    case category
    case dueDate
    case paymentUrl
    case ownerName
    case ownerTier
    case ownerAddress
    case billImage
}

// MARK: - Deal Sheet Bill Panel

/// Represents one side of the deal sheet
struct DealSheetBillPanel {
    let isOwner: Bool
    let billInfo: RedactedBillInfo
    let status: DealSheetBillStatus

    var headerText: String {
        isOwner ? "Your Bill" : "Their Bill"
    }

    var statusText: String {
        status.displayText(isOwner: isOwner)
    }

    var statusIcon: String {
        status.icon
    }

    var statusColor: String {
        status.color
    }
}

/// Status of a bill in the deal sheet
enum DealSheetBillStatus {
    case readyToBePaid
    case pendingPayment(dueDate: Date)
    case paymentSubmitted
    case paymentVerified
    case completed

    func displayText(isOwner: Bool) -> String {
        switch self {
        case .readyToBePaid:
            return isOwner ? "Ready to be paid by partner" : "You will pay this bill"
        case .pendingPayment(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Payment due by \(formatter.string(from: date))"
        case .paymentSubmitted:
            return "Payment proof submitted"
        case .paymentVerified:
            return "Payment verified"
        case .completed:
            return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .readyToBePaid: return "clock"
        case .pendingPayment: return "calendar.badge.clock"
        case .paymentSubmitted: return "doc.badge.clock"
        case .paymentVerified: return "checkmark.circle"
        case .completed: return "checkmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .readyToBePaid: return "#F5A623"      // Orange
        case .pendingPayment: return "#5BA4D4"    // Blue
        case .paymentSubmitted: return "#9B59B6"  // Purple
        case .paymentVerified: return "#5B8A6B"   // Green
        case .completed: return "#27AE60"         // Dark green
        }
    }
}

// MARK: - Mock Data

extension RedactedBillInfo {
    static var mockBill: RedactedBillInfo {
        RedactedBillInfo(
            id: UUID(),
            billerName: "Comcast Internet",
            amountCents: 8999,
            accountLast4: "4521",
            category: .internet,
            dueDate: Date().addingTimeInterval(86400 * 5),
            ownerTier: .T2_VERIFIED,
            ownerDisplayName: "John D."
        )
    }

    static var mockBill2: RedactedBillInfo {
        RedactedBillInfo(
            id: UUID(),
            billerName: "Duke Energy",
            amountCents: 12500,
            accountLast4: "7823",
            category: .electric,
            dueDate: Date().addingTimeInterval(86400 * 3),
            ownerTier: .T3_TRUSTED,
            ownerDisplayName: "Sarah M."
        )
    }
}
