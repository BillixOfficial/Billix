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
    let category: String
    let avgAmount: Double?
    let sampleSize: Int?

    /// Formatted average amount for display (e.g., "$125.50/mo")
    var formattedAvgAmount: String? {
        guard let avg = avgAmount else { return nil }
        return String(format: "$%.0f/mo avg", avg)
    }

    /// Sample size description (e.g., "Based on 47 bills")
    var sampleSizeDescription: String? {
        guard let count = sampleSize, count > 0 else { return nil }
        return "Based on \(count) bill\(count == 1 ? "" : "s")"
    }
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

        /// Maps backend API status values to iOS status
        init(fromAPIStatus apiStatus: String) {
            switch apiStatus {
            case "above_average":
                self = .overpaying
            case "below_average":
                self = .underpaying
            case "average", "insufficient_data":
                self = .average
            default:
                self = .average
            }
        }
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
