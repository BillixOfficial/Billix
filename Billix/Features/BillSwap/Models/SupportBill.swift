//
//  SupportBill.swift
//  Billix
//
//  Bill model for the Bill Connection feature (replaces SwapBill)
//  Note: Account numbers are NOT stored - only Guest Pay links for external payment
//

import Foundation

// MARK: - Bill Analysis Data (OCR Results)

/// Simplified bill analysis data stored with support bills
/// Full analysis is in BillAnalysis model, this is a subset for connection purposes
struct SupportBillAnalysisData: Codable, Equatable {
    let provider: String?
    let amount: Double?
    let dueDate: String?
    let category: String?
    let plainEnglishSummary: String?
    let hasRedFlags: Bool
    let healthScore: Int?

    enum CodingKeys: String, CodingKey {
        case provider
        case amount
        case dueDate = "due_date"
        case category
        case plainEnglishSummary = "plain_english_summary"
        case hasRedFlags = "has_red_flags"
        case healthScore = "health_score"
    }

    /// Create from full BillAnalysis
    init(from analysis: BillAnalysis) {
        self.provider = analysis.provider
        self.amount = analysis.amount
        self.dueDate = analysis.dueDate
        self.category = analysis.category
        self.plainEnglishSummary = analysis.plainEnglishSummary
        self.hasRedFlags = !(analysis.redFlags?.isEmpty ?? true)
        // Calculate health score based on red flags
        self.healthScore = analysis.redFlags.map { flags in
            let severityPenalty = flags.reduce(0) { total, flag in
                switch flag.type.lowercased() {
                case "high": return total + 30
                case "medium": return total + 15
                case "low": return total + 5
                default: return total + 10
                }
            }
            return max(0, 100 - severityPenalty)
        }
    }

    init(
        provider: String? = nil,
        amount: Double? = nil,
        dueDate: String? = nil,
        category: String? = nil,
        plainEnglishSummary: String? = nil,
        hasRedFlags: Bool = false,
        healthScore: Int? = nil
    ) {
        self.provider = provider
        self.amount = amount
        self.dueDate = dueDate
        self.category = category
        self.plainEnglishSummary = plainEnglishSummary
        self.hasRedFlags = hasRedFlags
        self.healthScore = healthScore
    }
}

// MARK: - Bill Status

/// Bill status in the connection marketplace
enum SupportBillStatus: String, Codable, CaseIterable {
    case posted         // Visible on Community Board
    case connected      // Matched with a supporter
    case paid           // Bill has been paid
    case cancelled      // Request cancelled

    var displayName: String {
        switch self {
        case .posted: return "Posted"
        case .connected: return "Connected"
        case .paid: return "Paid"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .posted: return "megaphone.fill"
        case .connected: return "person.2.fill"
        case .paid: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Bill Category

/// Categories of bills that can be posted for support
/// Note: Uses SwapBillCategory from TrustLadderEnums for compatibility
typealias SupportBillCategory = SwapBillCategory

// MARK: - Support Bill Model

/// A bill posted for community support
/// NOTE: No account numbers are stored - payment is via Guest Pay links only
struct SupportBill: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var amount: Decimal
    var dueDate: Date?
    var providerName: String?
    var category: SupportBillCategory?
    var zipCode: String?
    var status: SupportBillStatus
    var imageUrl: String?
    var guestPayLink: String?       // PRIMARY payment method - external utility portal URL
    let createdAt: Date
    var tokensCharged: Int          // Tokens charged at upload (typically 2)

    // OCR Verification fields
    var billAnalysis: SupportBillAnalysisData?
    var isVerified: Bool
    var verifiedAt: Date?

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
        case guestPayLink = "guest_pay_link"
        case createdAt = "created_at"
        case tokensCharged = "tokens_charged"
        case billAnalysis = "bill_analysis"
        case isVerified = "is_verified"
        case verifiedAt = "verified_at"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        amount: Decimal,
        dueDate: Date? = nil,
        providerName: String? = nil,
        category: SupportBillCategory? = nil,
        zipCode: String? = nil,
        status: SupportBillStatus = .posted,
        imageUrl: String? = nil,
        guestPayLink: String? = nil,
        createdAt: Date = Date(),
        tokensCharged: Int = 2,
        billAnalysis: SupportBillAnalysisData? = nil,
        isVerified: Bool = false,
        verifiedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.dueDate = dueDate
        self.providerName = providerName
        self.category = category
        self.zipCode = zipCode
        self.status = status
        self.imageUrl = imageUrl
        self.guestPayLink = guestPayLink
        self.createdAt = createdAt
        self.tokensCharged = tokensCharged
        self.billAnalysis = billAnalysis
        self.isVerified = isVerified
        self.verifiedAt = verifiedAt
    }

    // MARK: - Computed Properties

    /// Alias for providerName for compatibility
    var provider: String? {
        providerName
    }

    /// Whether this bill has a Guest Pay link for external payment
    var hasGuestPayLink: Bool {
        guard let link = guestPayLink, !link.isEmpty else { return false }
        return URL(string: link) != nil
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

    /// Urgency level based on due date
    var urgencyLevel: UrgencyLevel {
        guard let days = daysUntilDue else { return .normal }
        if days < 0 { return .overdue }
        if days <= 3 { return .urgent }
        if days <= 7 { return .soon }
        return .normal
    }

    /// Get city name from zip code
    var cityFromZip: String? {
        guard let zip = zipCode, !zip.isEmpty else { return nil }

        let zipPrefix = String(zip.prefix(3))

        // Basic zip code to city mapping for major areas
        let cityMap: [String: String] = [
            // Michigan
            "481": "Detroit, MI",
            "482": "Detroit, MI",
            "483": "Royal Oak, MI",
            "488": "Lansing, MI",
            "493": "Grand Rapids, MI",
            // Texas
            "750": "Dallas, TX",
            "770": "Houston, TX",
            "786": "Austin, TX",
            "780": "San Antonio, TX",
            // California
            "900": "Los Angeles, CA",
            "920": "San Diego, CA",
            "940": "San Francisco, CA",
            "950": "San Jose, CA",
            // New York
            "100": "New York, NY",
            "112": "Brooklyn, NY",
            // Illinois
            "606": "Chicago, IL",
            // Georgia
            "303": "Atlanta, GA",
            // Florida
            "330": "Miami, FL",
            "327": "Orlando, FL",
            "335": "Tampa, FL",
        ]

        if let city = cityMap[zipPrefix] {
            return city
        }

        return "Zip: \(zip)"
    }
}

// MARK: - Urgency Level

enum UrgencyLevel: String, Codable {
    case normal
    case soon       // Due within 7 days
    case urgent     // Due within 3 days
    case overdue    // Past due

    var color: String {
        switch self {
        case .normal: return "#5B8A6B"   // Green
        case .soon: return "#E8B54D"     // Amber
        case .urgent: return "#E07941"   // Orange
        case .overdue: return "#C45C5C"  // Red
        }
    }

    var displayName: String {
        switch self {
        case .normal: return "On Track"
        case .soon: return "Due Soon"
        case .urgent: return "Urgent"
        case .overdue: return "Overdue"
        }
    }
}

// MARK: - Mock Data

extension SupportBill {
    /// Mock electric bill for previews
    static func mockElectric() -> SupportBill {
        SupportBill(
            id: UUID(),
            userId: UUID(),
            amount: 125.50,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            providerName: "DTE Energy",
            category: .electric,
            zipCode: "48201",
            status: .posted,
            guestPayLink: "https://newlook.dteenergy.com/wps/wcm/connect/dte-web/quicklinks/pay-your-bill",
            tokensCharged: 2,
            billAnalysis: SupportBillAnalysisData(
                provider: "DTE Energy",
                amount: 125.50,
                category: "electric",
                healthScore: 72
            ),
            isVerified: true,
            verifiedAt: Date()
        )
    }

    static let mockBills: [SupportBill] = [
        SupportBill(
            id: UUID(),
            userId: UUID(),
            amount: 125.50,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            providerName: "DTE Energy",
            category: .electric,
            zipCode: "48201",
            status: .posted,
            imageUrl: nil,
            guestPayLink: "https://newlook.dteenergy.com/wps/wcm/connect/dte-web/quicklinks/pay-your-bill",
            createdAt: Date(),
            tokensCharged: 2,
            billAnalysis: SupportBillAnalysisData(
                provider: "DTE Energy",
                amount: 125.50,
                category: "electric",
                healthScore: 72
            ),
            isVerified: true,
            verifiedAt: Date()
        ),
        SupportBill(
            id: UUID(),
            userId: UUID(),
            amount: 89.99,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            providerName: "Comcast",
            category: .internet,
            zipCode: "48201",
            status: .posted,
            imageUrl: nil,
            guestPayLink: "https://www.xfinity.com/pay-bill",
            createdAt: Date(),
            tokensCharged: 2,
            billAnalysis: nil,
            isVerified: false,
            verifiedAt: nil
        ),
        SupportBill(
            id: UUID(),
            userId: UUID(),
            amount: 45.00,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            providerName: "Great Lakes Water",
            category: .water,
            zipCode: "48201",
            status: .connected,
            imageUrl: nil,
            guestPayLink: "https://greatlakeswater.org/pay",
            createdAt: Date(),
            tokensCharged: 2,
            billAnalysis: SupportBillAnalysisData(
                provider: "Great Lakes Water",
                amount: 45.00,
                category: "water",
                hasRedFlags: false,
                healthScore: 85
            ),
            isVerified: true,
            verifiedAt: Date()
        )
    ]
}
