//
//  SwapMatch.swift
//  Billix
//
//  Auto-Match Model for Bill Swap Marketplace
//

import Foundation

// MARK: - Swap Match Model

/// Represents a potential match between two bills for swapping
struct SwapMatch: Identifiable {
    let id: UUID
    let yourBill: SwapBill
    let theirBill: SwapBill
    let partnerProfile: TrustProfile
    let matchScore: Double  // 0-100 compatibility score
    let matchReasons: [MatchReason]
    let estimatedFees: MatchFees

    init(
        id: UUID = UUID(),
        yourBill: SwapBill,
        theirBill: SwapBill,
        partnerProfile: TrustProfile,
        matchScore: Double,
        matchReasons: [MatchReason],
        estimatedFees: MatchFees
    ) {
        self.id = id
        self.yourBill = yourBill
        self.theirBill = theirBill
        self.partnerProfile = partnerProfile
        self.matchScore = matchScore
        self.matchReasons = matchReasons
        self.estimatedFees = estimatedFees
    }

    // MARK: - Computed Properties

    /// Formatted match score (e.g., "85%")
    var formattedMatchScore: String {
        String(format: "%.0f%%", matchScore)
    }

    /// Match quality description
    var matchQuality: MatchQuality {
        switch matchScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .poor
        }
    }

    /// Amount difference between bills
    var amountDifferenceCents: Int {
        abs(yourBill.amountCents - theirBill.amountCents)
    }

    /// Formatted amount difference
    var formattedAmountDifference: String {
        if amountDifferenceCents == 0 {
            return "Equal amounts"
        }
        return String(format: "$%.2f difference", Double(amountDifferenceCents) / 100.0)
    }

    /// Days between due dates
    var dueDateDifference: Int {
        let calendar = Calendar.current
        return abs(calendar.dateComponents([.day], from: yourBill.dueDate, to: theirBill.dueDate).day ?? 0)
    }
}

// MARK: - Match Quality

enum MatchQuality: String {
    case excellent = "Excellent Match"
    case good = "Good Match"
    case fair = "Fair Match"
    case poor = "Low Match"

    var color: String {
        switch self {
        case .excellent: return "#27AE60"  // Green
        case .good: return "#5B8A6B"       // Light green
        case .fair: return "#F5A623"       // Orange
        case .poor: return "#E74C3C"       // Red
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "circle.fill"
        case .poor: return "exclamationmark.circle"
        }
    }
}

// MARK: - Match Reason

enum MatchReason: String, Codable, CaseIterable {
    case similarAmount = "SIMILAR_AMOUNT"
    case exactAmount = "EXACT_AMOUNT"
    case complementaryDueDate = "COMPLEMENTARY_DUE_DATE"
    case sameTier = "SAME_TIER"
    case highTrustPartner = "HIGH_TRUST_PARTNER"
    case categoryMatch = "CATEGORY_MATCH"
    case urgentBill = "URGENT_BILL"
    case reliablePartner = "RELIABLE_PARTNER"

    var displayText: String {
        switch self {
        case .similarAmount: return "Similar amounts"
        case .exactAmount: return "Exact amount match"
        case .complementaryDueDate: return "Due dates align well"
        case .sameTier: return "Same trust tier"
        case .highTrustPartner: return "Highly trusted partner"
        case .categoryMatch: return "Same bill category"
        case .urgentBill: return "Urgent bill priority"
        case .reliablePartner: return "Reliable swap partner"
        }
    }

    var icon: String {
        switch self {
        case .similarAmount, .exactAmount: return "dollarsign.circle"
        case .complementaryDueDate: return "calendar"
        case .sameTier: return "person.2"
        case .highTrustPartner: return "checkmark.shield"
        case .categoryMatch: return "tag"
        case .urgentBill: return "exclamationmark.triangle"
        case .reliablePartner: return "star"
        }
    }

    /// Points added to match score for this reason
    var scoreContribution: Double {
        switch self {
        case .exactAmount: return 25
        case .similarAmount: return 15
        case .complementaryDueDate: return 15
        case .categoryMatch: return 10
        case .highTrustPartner: return 15
        case .sameTier: return 5
        case .urgentBill: return 5
        case .reliablePartner: return 10
        }
    }
}

// MARK: - Match Fees

/// Fee breakdown for a potential match
struct MatchFees {
    let facilitationFeePerUser: Int  // $1.99 = 199 cents
    let spreadFee: Int               // 3% of bill difference
    let yourTotal: Int
    let theirTotal: Int

    init(
        facilitationFeePerUser: Int = SwapFeeCalculator.facilitationFeeCents,
        spreadFee: Int = 0
    ) {
        self.facilitationFeePerUser = facilitationFeePerUser
        self.spreadFee = spreadFee
        // Split spread fee evenly
        self.yourTotal = facilitationFeePerUser + (spreadFee / 2)
        self.theirTotal = facilitationFeePerUser + (spreadFee / 2)
    }

    /// Total fees combined
    var totalAllFees: Int {
        yourTotal + theirTotal
    }

    /// Formatted your total fee
    var formattedYourTotal: String {
        String(format: "$%.2f", Double(yourTotal) / 100.0)
    }

    /// Formatted their total fee
    var formattedTheirTotal: String {
        String(format: "$%.2f", Double(theirTotal) / 100.0)
    }

    /// Formatted facilitation fee
    var formattedFacilitationFee: String {
        String(format: "$%.2f", Double(facilitationFeePerUser) / 100.0)
    }

    /// Formatted spread fee
    var formattedSpreadFee: String {
        if spreadFee == 0 {
            return "None"
        }
        return String(format: "$%.2f", Double(spreadFee) / 100.0)
    }

    /// Calculate fees for two bills
    static func calculate(yourBillCents: Int, theirBillCents: Int) -> MatchFees {
        let spreadFee = SwapFeeCalculator.calculateSpreadFee(
            billACents: yourBillCents,
            billBCents: theirBillCents
        )
        return MatchFees(spreadFee: spreadFee)
    }
}

// MARK: - Match Request

/// Request parameters for finding matches
struct MatchRequest {
    let billId: UUID
    let preferredCategories: [SwapBillCategory]?
    let maxAmountDifferenceCents: Int?
    let maxDueDateDays: Int?
    let minPartnerTier: SwapTrustTier?

    init(
        billId: UUID,
        preferredCategories: [SwapBillCategory]? = nil,
        maxAmountDifferenceCents: Int? = nil,
        maxDueDateDays: Int? = nil,
        minPartnerTier: SwapTrustTier? = nil
    ) {
        self.billId = billId
        self.preferredCategories = preferredCategories
        self.maxAmountDifferenceCents = maxAmountDifferenceCents
        self.maxDueDateDays = maxDueDateDays
        self.minPartnerTier = minPartnerTier
    }
}
