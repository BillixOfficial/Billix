//
//  PointsLedger.swift
//  Billix
//
//  Bill Swap Points Ledger Model
//

import Foundation

// MARK: - Points Reason

enum SwapPointsReason: String, Codable, CaseIterable {
    case swapCompleted = "SWAP_COMPLETED"
    case firstSwapOfDay = "FIRST_SWAP_OF_DAY"
    case feeWaiver = "FEE_WAIVER"
    case referralBonus = "REFERRAL_BONUS"
    case verificationBonus = "VERIFICATION_BONUS"
    case promotionalBonus = "PROMOTIONAL_BONUS"
    case disputeRefund = "DISPUTE_REFUND"
    case adminAdjustment = "ADMIN_ADJUSTMENT"
    case redemption = "REDEMPTION"

    var displayName: String {
        switch self {
        case .swapCompleted: return "Swap Completed"
        case .firstSwapOfDay: return "First Swap of Day"
        case .feeWaiver: return "Fee Waiver"
        case .referralBonus: return "Referral Bonus"
        case .verificationBonus: return "Verification Bonus"
        case .promotionalBonus: return "Promotional Bonus"
        case .disputeRefund: return "Dispute Refund"
        case .adminAdjustment: return "Admin Adjustment"
        case .redemption: return "Redemption"
        }
    }

    var icon: String {
        switch self {
        case .swapCompleted: return "checkmark.circle.fill"
        case .firstSwapOfDay: return "sunrise.fill"
        case .feeWaiver: return "ticket.fill"
        case .referralBonus: return "person.2.fill"
        case .verificationBonus: return "checkmark.seal.fill"
        case .promotionalBonus: return "gift.fill"
        case .disputeRefund: return "arrow.uturn.backward.circle.fill"
        case .adminAdjustment: return "wrench.and.screwdriver.fill"
        case .redemption: return "cart.fill"
        }
    }

    /// Whether this is a positive transaction
    var isCredit: Bool {
        switch self {
        case .feeWaiver, .redemption:
            return false
        default:
            return true
        }
    }

    /// Default points for this reason (can be overridden)
    var defaultPoints: Int {
        switch self {
        case .swapCompleted: return 100
        case .firstSwapOfDay: return 50
        case .feeWaiver: return -500
        case .referralBonus: return 200
        case .verificationBonus: return 100
        case .promotionalBonus: return 50
        case .disputeRefund: return 100
        case .adminAdjustment: return 0
        case .redemption: return 0
        }
    }
}

// MARK: - Points Ledger Entry

struct SwapPointsLedgerEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let deltaPoints: Int
    let reason: SwapPointsReason
    let swapId: UUID?
    var description: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deltaPoints = "delta_points"
        case reason
        case swapId = "swap_id"
        case description
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    /// Is this a credit (positive points)?
    var isCredit: Bool {
        deltaPoints > 0
    }

    /// Formatted points string with sign
    var formattedPoints: String {
        if deltaPoints >= 0 {
            return "+\(deltaPoints)"
        } else {
            return "\(deltaPoints)"
        }
    }

    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Short date for list display
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            formatter.timeStyle = .short
            return formatter.string(from: createdAt)
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: createdAt)
        }
    }
}

// MARK: - Points Summary

struct PointsSummary {
    let currentBalance: Int
    let lifetimeEarned: Int
    let lifetimeSpent: Int
    let swapsCompletedThisMonth: Int
    let canWaiveFee: Bool

    /// Progress to next fee waiver (0.0 - 1.0)
    var progressToFeeWaiver: Double {
        guard currentBalance < 500 else { return 1.0 }
        return Double(currentBalance) / 500.0
    }

    /// Points needed to waive fee
    var pointsToFeeWaiver: Int {
        max(0, 500 - currentBalance)
    }
}

// MARK: - Add Points Request

struct AddPointsRequest: Codable {
    let userId: UUID
    let deltaPoints: Int
    let reason: SwapPointsReason
    let swapId: UUID?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deltaPoints = "delta_points"
        case reason
        case swapId = "swap_id"
        case description
    }
}

// MARK: - Points Error

enum SwapPointsError: LocalizedError {
    case notAuthenticated
    case insufficientBalance
    case transactionFailed
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .insufficientBalance:
            return "Not enough points"
        case .transactionFailed:
            return "Points transaction failed"
        case .invalidAmount:
            return "Invalid points amount"
        }
    }
}

// MARK: - Points Constants

enum PointsConstants {
    static let perCompletedSwap = 100
    static let firstSwapOfDayBonus = 50
    static let feeWaiverCost = 500
    static let referralBonus = 200
    static let verificationBonus = 100
}
