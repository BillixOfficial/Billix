//
//  Connection.swift
//  Billix
//
//  Connection model for the Bill Connection feature (replaces BillSwap)
//  Implements the 5-phase peer-to-peer support workflow
//

import Foundation
import SwiftUI

// MARK: - Connection Status

/// Status of a Bill Connection transaction following the 5-phase workflow
enum ConnectionStatus: String, Codable, CaseIterable {
    case requested      // Phase 1: Bill posted to Community Board
    case handshake      // Phase 2: Chat opened, agreeing on terms
    case executing      // Phase 3: Supporter paying via external portal
    case proofing       // Phase 4: Proof uploaded, awaiting verification
    case completed      // Phase 5: Success, reputation awarded
    case disputed       // Issue raised, under review
    case cancelled      // User cancelled the connection

    var displayName: String {
        switch self {
        case .requested: return "Requested"
        case .handshake: return "In Discussion"
        case .executing: return "Payment in Progress"
        case .proofing: return "Verifying Payment"
        case .completed: return "Completed"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .requested: return "hand.raised.fill"
        case .handshake: return "bubble.left.and.bubble.right.fill"
        case .executing: return "arrow.up.right.square"
        case .proofing: return "doc.text.magnifyingglass"
        case .completed: return "checkmark.circle.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .requested: return Color(hex: "#5BA4D4")     // Info blue
        case .handshake: return Color(hex: "#E8A54B")     // Amber
        case .executing: return Color(hex: "#5B8A6B")     // Money green
        case .proofing: return Color(hex: "#9B7B9F")      // Purple
        case .completed: return Color(hex: "#4CAF7A")     // Success green
        case .disputed: return Color(hex: "#E07A6B")      // Danger red
        case .cancelled: return Color(hex: "#8B9A94")     // Gray
        }
    }

    /// The phase number (1-5) for active connections
    var phaseNumber: Int? {
        switch self {
        case .requested: return 1
        case .handshake: return 2
        case .executing: return 3
        case .proofing: return 4
        case .completed: return 5
        case .disputed, .cancelled: return nil
        }
    }

    /// User-friendly description of current phase
    var phaseDescription: String {
        switch self {
        case .requested:
            return "Your support request is visible on the Community Board"
        case .handshake:
            return "Discuss and agree on support terms with your match"
        case .executing:
            return "Supporter is paying your bill via the utility portal"
        case .proofing:
            return "Payment proof submitted, awaiting your confirmation"
        case .completed:
            return "Connection successful! Reputation points awarded"
        case .disputed:
            return "This connection is under review"
        case .cancelled:
            return "This connection was cancelled"
        }
    }
}

// MARK: - Connection Type

/// Whether this is a mutual support (both help each other) or one-way request
enum ConnectionType: String, Codable, CaseIterable {
    case mutual = "mutual"      // "I'll help you too" - bi-directional
    case oneWay = "one_way"     // "Just need help" - one-way only

    var displayName: String {
        switch self {
        case .mutual: return "Mutual Support"
        case .oneWay: return "One-Way Support"
        }
    }

    var detailDescription: String {
        switch self {
        case .mutual:
            return "Both users help each other pay bills"
        case .oneWay:
            return "Only requesting support, not offering to help back"
        }
    }

    var iconName: String {
        switch self {
        case .mutual: return "arrow.left.arrow.right"
        case .oneWay: return "arrow.right"
        }
    }
}

// MARK: - Proof Type

/// Type of payment verification required
enum ProofType: String, Codable, CaseIterable {
    case screenshot = "screenshot"
    case screenshotWithConfirmation = "screenshot_confirmation"
    case utilityPortal = "utility_portal"
    case bankStatement = "bank_statement"

    var displayName: String {
        switch self {
        case .screenshot:
            return "Screenshot Only"
        case .screenshotWithConfirmation:
            return "Screenshot + Confirmation"
        case .utilityPortal:
            return "Utility Portal"
        case .bankStatement:
            return "Bank Statement"
        }
    }

    var detailDescription: String {
        switch self {
        case .screenshot:
            return "Upload a screenshot of the payment confirmation"
        case .screenshotWithConfirmation:
            return "Screenshot plus initiator must confirm receipt"
        case .utilityPortal:
            return "Screenshot from the utility company's portal"
        case .bankStatement:
            return "Bank statement showing the transaction"
        }
    }

    /// Legacy compatibility alias for detailDescription
    var description: String {
        detailDescription
    }

    var icon: String {
        switch self {
        case .screenshot:
            return "camera.fill"
        case .screenshotWithConfirmation:
            return "checkmark.seal.fill"
        case .utilityPortal:
            return "building.2.fill"
        case .bankStatement:
            return "doc.text.fill"
        }
    }
}

// MARK: - Connection Model

/// A connection between two users in Bill Connection
/// Represents the peer-to-peer support relationship
struct Connection: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let initiatorId: UUID           // User who posted the support request
    let supporterId: UUID?          // User who offered to help (nil until matched)
    let billId: UUID                // The bill being supported
    var status: ConnectionStatus
    var connectionType: ConnectionType
    var phase: Int                  // Current phase (1-5)
    var proofUrl: String?           // Screenshot of payment confirmation
    var proofVerifiedAt: Date?      // When AI/initiator verified the proof
    var reputationAwarded: Bool     // Whether reputation was given
    let createdAt: Date
    var matchedAt: Date?            // When supporter connected
    var completedAt: Date?
    var cancelledAt: Date?
    var cancelReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case initiatorId = "initiator_id"
        case supporterId = "supporter_id"
        case billId = "bill_id"
        case status
        case connectionType = "connection_type"
        case phase
        case proofUrl = "proof_url"
        case proofVerifiedAt = "proof_verified_at"
        case reputationAwarded = "reputation_awarded"
        case createdAt = "created_at"
        case matchedAt = "matched_at"
        case completedAt = "completed_at"
        case cancelledAt = "cancelled_at"
        case cancelReason = "cancel_reason"
    }

    init(
        id: UUID = UUID(),
        initiatorId: UUID,
        supporterId: UUID? = nil,
        billId: UUID,
        status: ConnectionStatus = .requested,
        connectionType: ConnectionType = .mutual,
        phase: Int = 1,
        proofUrl: String? = nil,
        proofVerifiedAt: Date? = nil,
        reputationAwarded: Bool = false,
        createdAt: Date = Date(),
        matchedAt: Date? = nil,
        completedAt: Date? = nil,
        cancelledAt: Date? = nil,
        cancelReason: String? = nil
    ) {
        self.id = id
        self.initiatorId = initiatorId
        self.supporterId = supporterId
        self.billId = billId
        self.status = status
        self.connectionType = connectionType
        self.phase = phase
        self.proofUrl = proofUrl
        self.proofVerifiedAt = proofVerifiedAt
        self.reputationAwarded = reputationAwarded
        self.createdAt = createdAt
        self.matchedAt = matchedAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.cancelReason = cancelReason
    }

    // MARK: - Computed Properties

    /// Check if current user is the initiator
    func isInitiator(userId: UUID) -> Bool {
        return initiatorId == userId
    }

    /// Check if current user is the supporter
    func isSupporter(userId: UUID) -> Bool {
        return supporterId == userId
    }

    /// Get the partner's user ID
    func partnerId(for currentUserId: UUID) -> UUID? {
        if isInitiator(userId: currentUserId) {
            return supporterId
        } else if isSupporter(userId: currentUserId) {
            return initiatorId
        }
        return nil
    }

    /// Whether a supporter has connected
    var hasSupporter: Bool {
        return supporterId != nil
    }

    /// Whether the connection is still active (not completed, cancelled, or disputed)
    var isActive: Bool {
        switch status {
        case .requested, .handshake, .executing, .proofing:
            return true
        case .completed, .disputed, .cancelled:
            return false
        }
    }

    /// Progress percentage (0.0 to 1.0) based on phase
    var progressPercentage: Double {
        switch status {
        case .requested: return 0.2
        case .handshake: return 0.4
        case .executing: return 0.6
        case .proofing: return 0.8
        case .completed: return 1.0
        case .disputed, .cancelled: return 0.0
        }
    }

    /// Human-readable status message for current user
    func statusMessage(for userId: UUID) -> String {
        let isInitiatorUser = isInitiator(userId: userId)

        switch status {
        case .requested:
            if isInitiatorUser {
                return "Waiting for someone to offer support"
            } else {
                return "Offer to help with this bill"
            }

        case .handshake:
            return "Discuss terms in chat"

        case .executing:
            if isInitiatorUser {
                return "Your supporter is paying your bill"
            } else {
                return "Pay the bill via the utility portal"
            }

        case .proofing:
            if isInitiatorUser {
                return "Verify the payment proof"
            } else {
                return "Waiting for payment confirmation"
            }

        case .completed:
            return "Connection successful!"

        case .disputed:
            return "Under review by support team"

        case .cancelled:
            return "This connection was cancelled"
        }
    }

    /// Action button text for current user
    func actionText(for userId: UUID) -> String? {
        let isInitiatorUser = isInitiator(userId: userId)

        switch status {
        case .requested:
            return isInitiatorUser ? nil : "Offer Support"

        case .handshake:
            return "Open Chat"

        case .executing:
            return isInitiatorUser ? nil : "Open Utility Portal"

        case .proofing:
            return isInitiatorUser ? "Verify Payment" : nil

        case .completed, .disputed, .cancelled:
            return nil
        }
    }

    /// Whether proof has been uploaded
    var hasProof: Bool {
        return proofUrl != nil
    }

    /// Whether proof has been verified
    var isProofVerified: Bool {
        return proofVerifiedAt != nil
    }
}

// MARK: - Mock Data

extension Connection {
    static func mockRequested(initiatorId: UUID) -> Connection {
        return Connection(
            id: UUID(),
            initiatorId: initiatorId,
            supporterId: nil,
            billId: UUID(),
            status: .requested,
            connectionType: .mutual,
            phase: 1,
            createdAt: Date()
        )
    }

    static func mockHandshake(initiatorId: UUID, supporterId: UUID) -> Connection {
        return Connection(
            id: UUID(),
            initiatorId: initiatorId,
            supporterId: supporterId,
            billId: UUID(),
            status: .handshake,
            connectionType: .mutual,
            phase: 2,
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            matchedAt: Date()
        )
    }

    static func mockExecuting(initiatorId: UUID, supporterId: UUID) -> Connection {
        return Connection(
            id: UUID(),
            initiatorId: initiatorId,
            supporterId: supporterId,
            billId: UUID(),
            status: .executing,
            connectionType: .oneWay,
            phase: 3,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            matchedAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
        )
    }

    static func mockCompleted(initiatorId: UUID, supporterId: UUID) -> Connection {
        return Connection(
            id: UUID(),
            initiatorId: initiatorId,
            supporterId: supporterId,
            billId: UUID(),
            status: .completed,
            connectionType: .mutual,
            phase: 5,
            proofUrl: "https://example.com/proof.jpg",
            proofVerifiedAt: Date(),
            reputationAwarded: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            matchedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            completedAt: Date()
        )
    }

    // MARK: - Convenience Mock Methods (for previews)

    static func mockRequested() -> Connection {
        mockRequested(initiatorId: UUID())
    }

    static func mockHandshake() -> Connection {
        mockHandshake(initiatorId: UUID(), supporterId: UUID())
    }

    static func mockExecuting() -> Connection {
        mockExecuting(initiatorId: UUID(), supporterId: UUID())
    }

    static func mockCompleted() -> Connection {
        mockCompleted(initiatorId: UUID(), supporterId: UUID())
    }
}

// MARK: - Community Board Item

/// Combined model for displaying bills on the Community Board
/// Includes both the support bill and its associated connection info
struct CommunityBoardItem: Identifiable {
    let bill: SupportBill
    let connectionType: ConnectionType
    let connectionCreatedAt: Date

    var id: UUID { bill.id }

    /// Time interval until the request expires (7 days from creation)
    var timeUntilExpiry: TimeInterval {
        let expiryDate = connectionCreatedAt.addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        return expiryDate.timeIntervalSinceNow
    }

    /// Whether the request has expired
    var isExpired: Bool {
        timeUntilExpiry <= 0
    }

    /// Formatted time remaining (e.g., "5d 12h" or "Expired")
    var timeRemainingText: String {
        if isExpired {
            return "Expired"
        }

        let seconds = Int(timeUntilExpiry)
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = (seconds % 3600) / 60
            return "\(minutes)m"
        }
    }
}
