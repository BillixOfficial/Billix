//
//  Bill.swift
//  Billix
//
//  Bill Swap Bill Model
//

import Foundation

// Note: SwapBillCategory is defined in TrustLadderEnums.swift

// MARK: - Bill Status

enum SwapBillStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case lockedInSwap = "LOCKED_IN_SWAP"
    case paidConfirmed = "PAID_CONFIRMED"
    case expired = "EXPIRED"
    case removed = "REMOVED"

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Available"
        case .lockedInSwap: return "In Swap"
        case .paidConfirmed: return "Paid"
        case .expired: return "Expired"
        case .removed: return "Removed"
        }
    }

    var isAvailable: Bool {
        self == .active
    }

    var isTerminal: Bool {
        switch self {
        case .paidConfirmed, .expired, .removed: return true
        default: return false
        }
    }
}

// MARK: - Swap Bill Model

struct SwapBill: Identifiable, Codable, Equatable {
    let id: UUID
    let ownerUserId: UUID
    var title: String
    var category: SwapBillCategory
    var providerName: String?
    var amountCents: Int
    var dueDate: Date
    var status: SwapBillStatus
    var paymentUrl: String?
    var accountNumberLast4: String?
    var billImageUrl: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case title
        case category
        case providerName = "provider_name"
        case amountCents = "amount_cents"
        case dueDate = "due_date"
        case status
        case paymentUrl = "payment_url"
        case accountNumberLast4 = "account_number_last4"
        case billImageUrl = "bill_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Amount in dollars
    var amountDollars: Double {
        Double(amountCents) / 100.0
    }

    /// Formatted amount string
    var formattedAmount: String {
        String(format: "$%.2f", amountDollars)
    }

    /// Days until due
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    /// Is due soon (within 3 days)
    var isDueSoon: Bool {
        daysUntilDue <= 3 && daysUntilDue >= 0
    }

    /// Is overdue
    var isOverdue: Bool {
        daysUntilDue < 0
    }

    /// Formatted due date
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    // MARK: - Validation

    /// Check if amount is within valid range ($1 - $200)
    static func isValidAmount(_ cents: Int) -> Bool {
        cents >= 100 && cents <= 20000
    }

    /// Check if amount is within tier limit
    func isWithinTierLimit(_ tier: SwapTrustTier) -> Bool {
        amountCents <= tier.maxBillCents
    }
}

// MARK: - Create Bill Request

struct CreateBillRequest: Codable {
    let title: String
    let category: SwapBillCategory
    let providerName: String?
    let amountCents: Int
    let dueDate: Date
    let paymentUrl: String?
    let accountNumberLast4: String?
    let billImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case category
        case providerName = "provider_name"
        case amountCents = "amount_cents"
        case dueDate = "due_date"
        case paymentUrl = "payment_url"
        case accountNumberLast4 = "account_number_last4"
        case billImageUrl = "bill_image_url"
    }
}

// MARK: - Bill with Owner Info

struct SwapBillWithOwner: Identifiable {
    let bill: SwapBill
    let ownerProfile: TrustProfile?
    let ownerDisplayName: String?
    let ownerHandle: String?

    var id: UUID { bill.id }
}
