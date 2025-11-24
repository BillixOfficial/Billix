//
//  QuickAddModels.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

// MARK: - Bill Type

struct BillType: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let category: String
}

// MARK: - Bill Provider

struct BillProvider: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoName: String
    let serviceArea: String
}

// MARK: - Billing Frequency

enum BillingFrequency: String, Codable, CaseIterable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Quick Add Request

struct QuickAddRequest: Codable {
    let billType: BillType
    let provider: BillProvider
    let zipCode: String
    let amount: Double
    let frequency: BillingFrequency
}

// MARK: - Quick Add Result

struct QuickAddResult: Codable {
    let billType: BillType
    let provider: BillProvider
    let amount: Double
    let frequency: BillingFrequency
    let areaAverage: Double
    let percentDifference: Double
    let status: Status
    let potentialSavings: Double?
    let message: String
    let ctaMessage: String?

    enum Status: String, Codable {
        case overpaying
        case underpaying
        case average
    }

    var statusColor: String {
        switch status {
        case .overpaying:
            return "red"
        case .underpaying:
            return "green"
        case .average:
            return "blue"
        }
    }

    var statusIcon: String {
        switch status {
        case .overpaying:
            return "arrow.up.circle.fill"
        case .underpaying:
            return "arrow.down.circle.fill"
        case .average:
            return "equal.circle.fill"
        }
    }
}
