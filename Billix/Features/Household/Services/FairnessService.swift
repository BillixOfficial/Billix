//
//  FairnessService.swift
//  Billix
//
//  Service for calculating fair bill splits based on
//  household fairness mode (equal, custom, income-based).
//

import Foundation

@MainActor
class FairnessService: ObservableObject {
    static let shared = FairnessService()

    private let householdService = HouseholdService.shared

    private init() {}

    // MARK: - Calculate Splits

    /// Calculate how a bill should be split among household members
    func calculateSplit(amount: Double, excludeMembers: [UUID] = []) -> [BillSplit] {
        guard let household = householdService.currentHousehold else { return [] }

        let activeMembers = householdService.members.filter { member in
            !excludeMembers.contains(member.userId)
        }

        guard !activeMembers.isEmpty else { return [] }

        switch household.fairnessMode {
        case .equal:
            return calculateEqualSplit(amount: amount, members: activeMembers)
        case .custom:
            return calculateCustomSplit(amount: amount, members: activeMembers)
        case .incomeBased:
            return calculateIncomeBasedSplit(amount: amount, members: activeMembers)
        }
    }

    /// Equal split: Total / member count
    private func calculateEqualSplit(amount: Double, members: [HouseholdMemberModel]) -> [BillSplit] {
        let perPerson = amount / Double(members.count)
        let percentage = 100.0 / Double(members.count)

        return members.map { member in
            BillSplit(
                member: member,
                amount: perPerson,
                percentage: percentage,
                isPaid: false
            )
        }
    }

    /// Custom split: Use stored equity percentages
    private func calculateCustomSplit(amount: Double, members: [HouseholdMemberModel]) -> [BillSplit] {
        // Check if all members have percentages set
        let hasAllPercentages = members.allSatisfy { $0.equityPercentage != nil }

        if !hasAllPercentages {
            // Fall back to equal split if not all percentages set
            return calculateEqualSplit(amount: amount, members: members)
        }

        // Normalize percentages to ensure they sum to 100
        let totalPercentage = members.compactMap { $0.equityPercentage }.reduce(0, +)
        let normalizationFactor = totalPercentage > 0 ? 100.0 / totalPercentage : 1.0

        return members.map { member in
            let normalizedPercentage = (member.equityPercentage ?? 0) * normalizationFactor
            let memberAmount = amount * (normalizedPercentage / 100.0)

            return BillSplit(
                member: member,
                amount: memberAmount,
                percentage: normalizedPercentage,
                isPaid: false
            )
        }
    }

    /// Income-based split: Use karma score as proxy for contribution weight
    private func calculateIncomeBasedSplit(amount: Double, members: [HouseholdMemberModel]) -> [BillSplit] {
        // Use karma as a proxy for contribution (higher karma = contributed more)
        let totalKarma = members.map { max($0.karmaScore, 1) }.reduce(0, +)

        return members.map { member in
            let karmaWeight = Double(max(member.karmaScore, 1)) / Double(totalKarma)
            let percentage = karmaWeight * 100.0
            let memberAmount = amount * karmaWeight

            return BillSplit(
                member: member,
                amount: memberAmount,
                percentage: percentage,
                isPaid: false
            )
        }
    }

    // MARK: - Validation

    /// Validate that custom percentages sum to 100
    func validateCustomPercentages(percentages: [(UUID, Double)]) -> ValidationResult {
        let total = percentages.map { $0.1 }.reduce(0, +)

        if abs(total - 100.0) < 0.01 {
            return .valid
        } else if total < 100.0 {
            return .invalid(message: "Percentages must add up to 100%. Currently at \(Int(total))%")
        } else {
            return .invalid(message: "Percentages exceed 100%. Currently at \(Int(total))%")
        }
    }

    /// Suggest equal percentages for members
    func suggestEqualPercentages() -> [(UUID, Double)] {
        let members = householdService.members
        guard !members.isEmpty else { return [] }

        let equalPercentage = 100.0 / Double(members.count)

        return members.map { ($0.userId, equalPercentage) }
    }

    /// Update member equity percentages
    func updateEquityPercentages(_ percentages: [(UUID, Double)]) async throws {
        // Validate first
        let validation = validateCustomPercentages(percentages: percentages)
        guard case .valid = validation else {
            if case .invalid(let message) = validation {
                throw FairnessError.invalidPercentages(message)
            }
            return
        }

        // Update each member
        for (memberId, percentage) in percentages {
            if let member = householdService.members.first(where: { $0.userId == memberId }) {
                try await householdService.updateMember(
                    memberId: member.id,
                    equityPercentage: percentage
                )
            }
        }
    }

    // MARK: - Summary

    /// Get a summary of the current fairness setup
    func getFairnessSummary() -> FairnessSummary {
        guard let household = householdService.currentHousehold else {
            return FairnessSummary(mode: .equal, members: [], isConfigured: false)
        }

        let members = householdService.members
        let isConfigured: Bool

        switch household.fairnessMode {
        case .equal:
            isConfigured = true
        case .custom:
            isConfigured = members.allSatisfy { $0.equityPercentage != nil }
        case .incomeBased:
            isConfigured = true // Always configured based on karma
        }

        return FairnessSummary(
            mode: household.fairnessMode,
            members: members.map { member in
                MemberFairnessInfo(
                    member: member,
                    percentage: member.equityPercentage ?? (100.0 / Double(max(members.count, 1)))
                )
            },
            isConfigured: isConfigured
        )
    }

    // MARK: - Bill History

    /// Calculate how much each member has contributed historically
    func calculateContributionHistory(bills: [HouseholdBill]) -> [UUID: Double] {
        var contributions: [UUID: Double] = [:]

        for bill in bills {
            let splits = calculateSplit(amount: bill.swapBill?.amount ?? 0)
            for split in splits where split.isPaid {
                contributions[split.member.userId, default: 0] += split.amount
            }
        }

        return contributions
    }

    /// Check if splits are balanced (within 5% variance)
    func checkBalance() -> BalanceStatus {
        let summary = getFairnessSummary()
        let percentages = summary.members.map { $0.percentage }

        guard !percentages.isEmpty else { return .unknown }

        let average = percentages.reduce(0, +) / Double(percentages.count)
        let maxVariance = percentages.map { abs($0 - average) }.max() ?? 0

        if maxVariance < 5 {
            return .balanced
        } else if maxVariance < 15 {
            return .slightlyUnbalanced
        } else {
            return .unbalanced
        }
    }
}

// MARK: - Models

enum ValidationResult {
    case valid
    case invalid(message: String)
}

struct FairnessSummary {
    let mode: FairnessMode
    let members: [MemberFairnessInfo]
    let isConfigured: Bool
}

struct MemberFairnessInfo: Identifiable {
    var id: UUID { member.id }
    let member: HouseholdMemberModel
    let percentage: Double
}

enum BalanceStatus {
    case balanced
    case slightlyUnbalanced
    case unbalanced
    case unknown

    var message: String {
        switch self {
        case .balanced:
            return "Contributions are well balanced"
        case .slightlyUnbalanced:
            return "Slight imbalance in contributions"
        case .unbalanced:
            return "Significant imbalance - consider adjusting splits"
        case .unknown:
            return "Unable to calculate balance"
        }
    }

    var icon: String {
        switch self {
        case .balanced: return "checkmark.circle.fill"
        case .slightlyUnbalanced: return "exclamationmark.circle.fill"
        case .unbalanced: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Errors

enum FairnessError: LocalizedError {
    case invalidPercentages(String)
    case noMembers

    var errorDescription: String? {
        switch self {
        case .invalidPercentages(let message):
            return message
        case .noMembers:
            return "No members to split bill with"
        }
    }
}
