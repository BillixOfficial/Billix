//
//  Swap.swift
//  Billix
//
//  Swap transaction model for the BillSwap feature
//

import Foundation

/// Status of a BillSwap transaction
enum BillSwapStatus: String, Codable, CaseIterable {
    case pending    // Match found, waiting for BOTH to commit
    case active     // Both users committed, swap in progress
    case expired    // Timer ran out without both committing
    case completed  // Both users paid each other's bills
    case dispute    // Issue raised, under review

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .expired: return "Expired"
        case .completed: return "Completed"
        case .dispute: return "Disputed"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .active: return "arrow.left.arrow.right"
        case .expired: return "clock.badge.xmark.fill"
        case .completed: return "checkmark.circle.fill"
        case .dispute: return "exclamationmark.triangle.fill"
        }
    }
}

/// A swap transaction between two users in BillSwap
struct BillSwapTransaction: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let billAId: UUID
    let billBId: UUID
    let userAId: UUID
    let userBId: UUID
    var status: BillSwapStatus
    var userAPaidFee: Bool      // User A committed (paid fee, used free swap, or is Prime)
    var userBPaidFee: Bool      // User B committed (paid fee, used free swap, or is Prime)
    var userAPaidPartner: Bool  // User A paid User B's bill
    var userBPaidPartner: Bool  // User B paid User A's bill
    var proofAUrl: String?      // Receipt screenshot from User A
    var proofBUrl: String?      // Receipt screenshot from User B
    let createdAt: Date
    var completedAt: Date?
    var expiresAt: Date?        // 24 hours from creation, match expires if both haven't committed
    var userACommittedAt: Date? // When User A committed to the swap
    var userBCommittedAt: Date? // When User B committed to the swap

    enum CodingKeys: String, CodingKey {
        case id
        case billAId = "bill_a_id"
        case billBId = "bill_b_id"
        case userAId = "user_a_id"
        case userBId = "user_b_id"
        case status
        case userAPaidFee = "user_a_paid_fee"
        case userBPaidFee = "user_b_paid_fee"
        case userAPaidPartner = "user_a_paid_partner"
        case userBPaidPartner = "user_b_paid_partner"
        case proofAUrl = "proof_a_url"
        case proofBUrl = "proof_b_url"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case expiresAt = "expires_at"
        case userACommittedAt = "user_a_committed_at"
        case userBCommittedAt = "user_b_committed_at"
    }

    /// Check if current user is User A
    func isUserA(userId: UUID) -> Bool {
        return userAId == userId
    }

    /// Check if current user is User B
    func isUserB(userId: UUID) -> Bool {
        return userBId == userId
    }

    /// Get the partner's user ID
    func partnerId(for currentUserId: UUID) -> UUID {
        return isUserA(userId: currentUserId) ? userBId : userAId
    }

    /// Get the partner's bill ID
    func partnerBillId(for currentUserId: UUID) -> UUID {
        return isUserA(userId: currentUserId) ? billBId : billAId
    }

    /// Get my bill ID
    func myBillId(for currentUserId: UUID) -> UUID {
        return isUserA(userId: currentUserId) ? billAId : billBId
    }

    /// Check if current user has paid the handshake fee
    func hasPaidFee(userId: UUID) -> Bool {
        return isUserA(userId: userId) ? userAPaidFee : userBPaidFee
    }

    /// Check if current user has paid their partner's bill
    func hasPaidPartner(userId: UUID) -> Bool {
        return isUserA(userId: userId) ? userAPaidPartner : userBPaidPartner
    }

    /// Check if partner has paid my bill
    func partnerHasPaidMe(userId: UUID) -> Bool {
        return isUserA(userId: userId) ? userBPaidPartner : userAPaidPartner
    }

    /// Get proof URL for current user
    func myProofUrl(for userId: UUID) -> String? {
        return isUserA(userId: userId) ? proofAUrl : proofBUrl
    }

    /// Get partner's proof URL
    func partnerProofUrl(for userId: UUID) -> String? {
        return isUserA(userId: userId) ? proofBUrl : proofAUrl
    }

    /// Check if both users have paid the handshake fee
    var bothPaidFees: Bool {
        return userAPaidFee && userBPaidFee
    }

    /// Check if both users have paid each other's bills
    var bothPaidPartners: Bool {
        return userAPaidPartner && userBPaidPartner
    }

    /// Check if the swap can be completed
    var canComplete: Bool {
        return status == .active && bothPaidPartners
    }

    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        var steps = 0.0

        if userAPaidFee { steps += 0.25 }
        if userBPaidFee { steps += 0.25 }
        if userAPaidPartner { steps += 0.25 }
        if userBPaidPartner { steps += 0.25 }

        return steps
    }

    /// Human-readable status message for current user
    func statusMessage(for userId: UUID) -> String {
        switch status {
        case .pending:
            if hasPaidFee(userId: userId) {
                return "Waiting for partner to accept"
            } else {
                return "Confirm to start this swap"
            }

        case .active:
            if hasPaidPartner(userId: userId) {
                if partnerHasPaidMe(userId: userId) {
                    return "Swap complete!"
                } else {
                    return "Waiting for partner to pay your bill"
                }
            } else {
                return "Pay your partner's bill"
            }

        case .expired:
            return "This match has expired"

        case .completed:
            return "Swap completed successfully!"

        case .dispute:
            return "Dispute under review"
        }
    }

    // MARK: - Expiration Helpers

    /// Time remaining until expiration (nil if no expiration set)
    var timeRemaining: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        return expiresAt.timeIntervalSinceNow
    }

    /// Whether the swap has expired
    var isExpired: Bool {
        guard let remaining = timeRemaining else { return false }
        return remaining <= 0
    }

    /// Formatted time remaining string (e.g., "23h 45m")
    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m remaining"
        } else {
            return "Less than 1m remaining"
        }
    }

    /// Check if partner has committed to the swap
    func partnerHasCommitted(userId: UUID) -> Bool {
        if isUserA(userId: userId) {
            return userBPaidFee
        } else {
            return userAPaidFee
        }
    }

    /// Get partner's committed timestamp
    func partnerCommittedAt(for userId: UUID) -> Date? {
        if isUserA(userId: userId) {
            return userBCommittedAt
        } else {
            return userACommittedAt
        }
    }
}

// MARK: - Mock Data

extension BillSwapTransaction {
    static func mockSwap(userAId: UUID, userBId: UUID) -> BillSwapTransaction {
        return BillSwapTransaction(
            id: UUID(),
            billAId: UUID(),
            billBId: UUID(),
            userAId: userAId,
            userBId: userBId,
            status: .pending,
            userAPaidFee: false,
            userBPaidFee: false,
            userAPaidPartner: false,
            userBPaidPartner: false,
            proofAUrl: nil,
            proofBUrl: nil,
            createdAt: Date(),
            completedAt: nil,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()),
            userACommittedAt: nil,
            userBCommittedAt: nil
        )
    }

    static func mockActiveSwap(userAId: UUID, userBId: UUID) -> BillSwapTransaction {
        return BillSwapTransaction(
            id: UUID(),
            billAId: UUID(),
            billBId: UUID(),
            userAId: userAId,
            userBId: userBId,
            status: .active,
            userAPaidFee: true,
            userBPaidFee: true,
            userAPaidPartner: false,
            userBPaidPartner: false,
            proofAUrl: nil,
            proofBUrl: nil,
            createdAt: Date(),
            completedAt: nil,
            expiresAt: nil, // No expiration for active swaps
            userACommittedAt: Date(),
            userBCommittedAt: Date()
        )
    }
}
