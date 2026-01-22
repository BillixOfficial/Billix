//
//  SwapBill.swift
//  Billix
//
//  Bill model for the BillSwap feature
//

import Foundation

/// Bill status in the swap marketplace
enum SwapBillStatus: String, Codable, CaseIterable {
    case unmatched
    case matched
    case paid

    var displayName: String {
        switch self {
        case .unmatched: return "Unmatched"
        case .matched: return "Matched"
        case .paid: return "Paid"
        }
    }
}

// Note: SwapBillCategory is defined in TrustLadderEnums.swift
// Use categories like .electric, .naturalGas, .water, .internet, .phonePlan, etc.

/// A bill uploaded for swapping
struct SwapBill: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var amount: Decimal
    var dueDate: Date?
    var providerName: String?
    var category: SwapBillCategory?
    var zipCode: String?
    var status: SwapBillStatus
    var imageUrl: String?
    var accountNumber: String?  // Hidden until handshake fee is paid
    var guestPayLink: String?   // URL for guest payment on provider website
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case dueDate = "due_date"
        case providerName = "provider_name"
        case category
        case zipCode = "zip_code"
        case status
        case imageUrl = "image_url"
        case accountNumber = "account_number"
        case guestPayLink = "guest_pay_link"
        case createdAt = "created_at"
    }

    /// Check if this bill can be matched with another
    func canMatchWith(_ other: SwapBill) -> Bool {
        // Must be different users
        guard userId != other.userId else { return false }

        // Both must be unmatched
        guard status == .unmatched && other.status == .unmatched else { return false }

        // Amounts must be within 10% of each other
        let lowerBound = amount * Decimal(0.9)
        let upperBound = amount * Decimal(1.1)
        return other.amount >= lowerBound && other.amount <= upperBound
    }

    /// Formatted amount string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
    }

    /// Formatted due date string
    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    /// Days until due (negative if past due)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }

    /// Whether the bill is past due
    var isPastDue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0
    }
}

// MARK: - Mock Data

extension SwapBill {
    static let mockBills: [SwapBill] = [
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 125.50,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            providerName: "DTE Energy",
            category: .electric,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****4521",
            guestPayLink: "https://newlook.dteenergy.com/wps/wcm/connect/dte-web/quicklinks/pay-your-bill",
            createdAt: Date()
        ),
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 89.99,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            providerName: "Comcast",
            category: .internet,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****7892",
            guestPayLink: "https://www.xfinity.com/pay-bill",
            createdAt: Date()
        ),
        SwapBill(
            id: UUID(),
            userId: UUID(),
            amount: 45.00,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            providerName: "Great Lakes Water",
            category: .water,
            zipCode: "48201",
            status: .unmatched,
            imageUrl: nil,
            accountNumber: "****1234",
            guestPayLink: nil,
            createdAt: Date()
        )
    ]
}
