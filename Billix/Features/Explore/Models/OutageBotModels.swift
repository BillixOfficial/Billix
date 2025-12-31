//
//  OutageBotModels.swift
//  Billix
//
//  Models for the Outage Bot feature
//

import Foundation
import SwiftUI

// MARK: - Provider Option

/// A provider option for the Add Provider sheet
struct ProviderOption: Identifiable {
    let id: UUID
    let name: String
    let logo: String

    init(id: UUID = UUID(), name: String, logo: String = "building.2") {
        self.id = id
        self.name = name
        self.logo = logo
    }

    /// Returns providers for a given category
    static func providers(for category: OutageBillType) -> [ProviderOption] {
        switch category {
        case .internet:
            return [
                ProviderOption(name: "Xfinity", logo: "wifi"),
                ProviderOption(name: "Verizon Fios", logo: "wifi"),
                ProviderOption(name: "AT&T", logo: "wifi"),
                ProviderOption(name: "Spectrum", logo: "wifi"),
                ProviderOption(name: "Cox", logo: "wifi"),
                ProviderOption(name: "Optimum", logo: "wifi"),
                ProviderOption(name: "Other", logo: "building.2")
            ]
        case .power:
            return [
                ProviderOption(name: "Con Edison", logo: "bolt.fill"),
                ProviderOption(name: "PSE&G", logo: "bolt.fill"),
                ProviderOption(name: "National Grid", logo: "bolt.fill"),
                ProviderOption(name: "Duke Energy", logo: "bolt.fill"),
                ProviderOption(name: "PG&E", logo: "bolt.fill"),
                ProviderOption(name: "Other", logo: "building.2")
            ]
        case .gas:
            return [
                ProviderOption(name: "National Grid", logo: "flame.fill"),
                ProviderOption(name: "PSE&G", logo: "flame.fill"),
                ProviderOption(name: "Con Edison", logo: "flame.fill"),
                ProviderOption(name: "SoCalGas", logo: "flame.fill"),
                ProviderOption(name: "Other", logo: "building.2")
            ]
        case .water:
            return [
                ProviderOption(name: "NYC Water", logo: "drop.fill"),
                ProviderOption(name: "LADWP", logo: "drop.fill"),
                ProviderOption(name: "City Water", logo: "drop.fill"),
                ProviderOption(name: "Other", logo: "building.2")
            ]
        case .mobile:
            return [
                ProviderOption(name: "Verizon", logo: "antenna.radiowaves.left.and.right"),
                ProviderOption(name: "AT&T", logo: "antenna.radiowaves.left.and.right"),
                ProviderOption(name: "T-Mobile", logo: "antenna.radiowaves.left.and.right"),
                ProviderOption(name: "Mint Mobile", logo: "antenna.radiowaves.left.and.right"),
                ProviderOption(name: "Other", logo: "building.2")
            ]
        }
    }
}

// MARK: - Detected Outage

/// A detected outage with crowd confirmation
struct DetectedOutage: Identifiable {
    let id: UUID
    let connection: OutageConnection
    let event: OutageEvent
    let crowdReports: Int
    let crowdConfidence: Double

    init(
        id: UUID = UUID(),
        connection: OutageConnection,
        event: OutageEvent,
        crowdReports: Int = 0,
        crowdConfidence: Double = 0.0
    ) {
        self.id = id
        self.connection = connection
        self.event = event
        self.crowdReports = crowdReports
        self.crowdConfidence = crowdConfidence
    }

    var crowdMessage: String {
        if crowdReports > 50 {
            return "\(crowdReports)+ reports in your area"
        } else if crowdReports > 10 {
            return "\(crowdReports) others affected nearby"
        } else if crowdReports > 0 {
            return "A few reports in your area"
        } else {
            return "Monitoring your connection"
        }
    }
}

// MARK: - OutageConnection Extensions

extension OutageConnection {
    /// Formatted total claimed amount
    var formattedTotalClaimed: String {
        if totalClaimed >= 1000 {
            return String(format: "$%.1fK", totalClaimed / 1000)
        } else if totalClaimed > 0 {
            return String(format: "$%.0f", totalClaimed)
        } else {
            return "$0"
        }
    }
}

// MARK: - OutageEvent Extensions

extension OutageEvent {
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: startTime)
    }

    var formattedDuration: String {
        if durationHours < 1 {
            return "\(Int(durationHours * 60)) min"
        } else if durationHours < 24 {
            return String(format: "%.1f hrs", durationHours)
        } else {
            return String(format: "%.0f days", durationHours / 24)
        }
    }
}

// MARK: - OutageClaim Extensions

extension OutageClaim {
    var formattedOutageDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: outageDate)
    }

    var formattedDuration: String {
        if durationHours < 1 {
            return "\(Int(durationHours * 60)) min"
        } else {
            return String(format: "%.1f hrs", durationHours)
        }
    }

    var displayCredit: String {
        String(format: "$%.2f", claimAmount)
    }
}

extension OutageClaim.ClaimStatus {
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .submitted: return "paperplane.fill"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        }
    }

    var displayName: String {
        rawValue
    }

    var isActionable: Bool {
        self == .pending
    }
}
