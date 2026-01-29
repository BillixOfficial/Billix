//
//  SwapConversation.swift
//  Billix
//
//  Wrapper model for displaying swap-linked conversations in Chat Hub
//

import Foundation

// MARK: - Swap Conversation Status

/// Status indicator for swap conversations in the chat list
enum SwapConversationStatus: String {
    case negotiating = "negotiating"
    case active = "active"
    case waitingForPartner = "waiting_partner"
    case waitingForYou = "waiting_you"
    case completed = "completed"
    case disputed = "disputed"

    var displayName: String {
        switch self {
        case .negotiating:
            return "Negotiating"
        case .active:
            return "Active Swap"
        case .waitingForPartner:
            return "Waiting for Partner"
        case .waitingForYou:
            return "Your Turn"
        case .completed:
            return "Completed"
        case .disputed:
            return "Disputed"
        }
    }

    var badgeColor: String {
        switch self {
        case .negotiating:
            return "#5BA4D4" // Info blue
        case .active:
            return "#5B8A6B" // Primary green
        case .waitingForPartner:
            return "#E8A54B" // Warning amber
        case .waitingForYou:
            return "#E07A6B" // Danger red (attention needed)
        case .completed:
            return "#4CAF7A" // Success green
        case .disputed:
            return "#E07A6B" // Danger red
        }
    }

    var icon: String {
        switch self {
        case .negotiating:
            return "doc.text.magnifyingglass"
        case .active:
            return "arrow.left.arrow.right"
        case .waitingForPartner:
            return "hourglass"
        case .waitingForYou:
            return "exclamationmark.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .disputed:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Swap Conversation

/// Wrapper for displaying swap-related conversations in the Chat Hub
struct SwapConversation: Identifiable, Equatable, Hashable {
    let swap: BillSwapTransaction
    let partnerParticipant: ChatParticipant
    let currentDeal: SwapDeal?
    let lastEvent: SwapEvent?
    let pendingExtension: ExtensionRequest?
    let hasUnreadEvents: Bool
    let conversationId: UUID?  // Linked conversation ID if chat exists

    var id: UUID { swap.id }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(swap.id)
    }

    static func == (lhs: SwapConversation, rhs: SwapConversation) -> Bool {
        lhs.swap.id == rhs.swap.id
    }

    // MARK: - Computed Properties

    /// Current status for display
    var status: SwapConversationStatus {
        // Check for dispute first
        if swap.status == .dispute {
            return .disputed
        }

        // Check if completed
        if swap.status == .completed {
            return .completed
        }

        // Check if still negotiating (no accepted deal)
        if currentDeal == nil || currentDeal?.status != .accepted {
            return .negotiating
        }

        // Active swap - check payment status
        guard let userId = SupabaseService.shared.currentUserId else {
            return .active
        }

        let iPaid = swap.hasPaidPartner(userId: userId)
        let partnerPaid = swap.partnerHasPaidMe(userId: userId)

        if !iPaid && !partnerPaid {
            // Determine who needs to pay first based on deal
            if let deal = currentDeal {
                let isUserA = swap.isUserA(userId: userId)
                let iPayFirst = (deal.whoPaysFirst == .userAPaysFirst && isUserA) ||
                                (deal.whoPaysFirst == .userBPaysFirst && !isUserA)

                if deal.whoPaysFirst == .simultaneous {
                    return .active
                } else if iPayFirst {
                    return .waitingForYou
                } else {
                    return .waitingForPartner
                }
            }
            return .active
        } else if iPaid && !partnerPaid {
            return .waitingForPartner
        } else if !iPaid && partnerPaid {
            return .waitingForYou
        } else {
            return .completed
        }
    }

    /// Preview text for conversation list
    var previewText: String {
        // Show last event description if available
        if let event = lastEvent {
            switch event.eventType {
            case .dealProposed:
                return "New terms proposed"
            case .dealCountered:
                return "Counter-offer received"
            case .dealAccepted:
                return "Terms accepted - swap active"
            case .paymentProofSubmitted:
                return "Payment proof uploaded"
            case .extensionRequested:
                return "Extension requested"
            default:
                return event.eventType.displayName
            }
        }

        // Fall back to status-based preview
        switch status {
        case .negotiating:
            if currentDeal != nil {
                return "Reviewing terms..."
            } else {
                return "Waiting for terms"
            }
        case .active:
            return "Swap in progress"
        case .waitingForPartner:
            return "Waiting for partner's payment"
        case .waitingForYou:
            return "Your payment needed"
        case .completed:
            return "Swap completed"
        case .disputed:
            return "Dispute in progress"
        }
    }

    /// Timestamp for sorting (last activity)
    var lastActivityAt: Date {
        lastEvent?.createdAt ?? swap.createdAt
    }

    /// Amount being swapped (for display)
    var swapAmountText: String? {
        guard let userId = SupabaseService.shared.currentUserId else { return nil }

        if let deal = currentDeal {
            let isUserA = swap.isUserA(userId: userId)
            let myAmount = deal.amount(isUserA: isUserA)

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSDecimalNumber(decimal: myAmount))
        }

        return nil
    }

    /// Check if there's an action required from current user
    var requiresAction: Bool {
        guard let userId = SupabaseService.shared.currentUserId else { return false }

        // Check for pending deal that needs response
        if let deal = currentDeal, deal.canRespond(userId: userId) {
            return true
        }

        // Check for pending extension that needs response
        if let ext = pendingExtension, ext.canRespond(userId: userId) {
            return true
        }

        // Check if it's user's turn to pay
        return status == .waitingForYou
    }

    /// Badge count (unread events or actions needed)
    var badgeCount: Int {
        var count = 0

        if hasUnreadEvents {
            count += 1
        }

        if requiresAction {
            count += 1
        }

        return count
    }
}

// MARK: - Conversation Extension

/// Extension to Conversation model to support swap linking
extension Conversation {
    /// Check if this conversation is linked to a swap
    var isSwapLinked: Bool {
        // This would be determined by the swap_id field in the database
        // For now, return false - will be updated when ChatModels is modified
        false
    }
}

// MARK: - SwapConversation Array Extension

extension Array where Element == SwapConversation {
    /// Sort by action required first, then by last activity
    var sortedByPriority: [SwapConversation] {
        sorted { a, b in
            // Actions required first
            if a.requiresAction && !b.requiresAction {
                return true
            }
            if !a.requiresAction && b.requiresAction {
                return false
            }

            // Then by unread events
            if a.hasUnreadEvents && !b.hasUnreadEvents {
                return true
            }
            if !a.hasUnreadEvents && b.hasUnreadEvents {
                return false
            }

            // Then by last activity (most recent first)
            return a.lastActivityAt > b.lastActivityAt
        }
    }

    /// Filter to active swaps only (not completed)
    var activeOnly: [SwapConversation] {
        filter { $0.swap.status != .completed }
    }

    /// Group by status for sectioned display
    func groupedByStatus() -> [(status: SwapConversationStatus, conversations: [SwapConversation])] {
        let grouped = Dictionary(grouping: self) { $0.status }

        // Order: waitingForYou, negotiating, active, waitingForPartner, completed, disputed
        let statusOrder: [SwapConversationStatus] = [
            .waitingForYou,
            .negotiating,
            .active,
            .waitingForPartner,
            .disputed,
            .completed
        ]

        return statusOrder.compactMap { status in
            guard let conversations = grouped[status], !conversations.isEmpty else { return nil }
            return (status: status, conversations: conversations)
        }
    }
}

// MARK: - Mock Data

#if DEBUG
extension SwapConversation {
    static func mock(
        status: BillSwapStatus = .active,
        hasUnread: Bool = false
    ) -> SwapConversation {
        let userA = UUID()
        let userB = UUID()
        let swap = BillSwapTransaction.mockActiveSwap(userAId: userA, userBId: userB)

        return SwapConversation(
            swap: swap,
            partnerParticipant: ChatParticipant(
                userId: userB,
                handle: "swappartner",
                displayName: "Swap Partner"
            ),
            currentDeal: SwapDeal.mockDeal(swapId: swap.id, proposerId: userA, status: .accepted),
            lastEvent: SwapEvent.mockEvent(swapId: swap.id, actorId: userA, type: .paymentProofSubmitted),
            pendingExtension: nil,
            hasUnreadEvents: hasUnread,
            conversationId: UUID()
        )
    }

    static let mockList: [SwapConversation] = [
        .mock(status: .active, hasUnread: true),
        .mock(status: .pending, hasUnread: false),
        .mock(status: .completed, hasUnread: false)
    ]
}
#endif
