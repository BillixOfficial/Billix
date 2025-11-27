//
//  Cluster.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import Foundation

/// Type of cluster/group buy
enum ClusterType: String, Codable, CaseIterable {
    case groupBuy = "Group Buy"
    case syndicate = "Syndicate"
    case reverseAuction = "Reverse Auction"
    case rally = "Rally"

    var icon: String {
        switch self {
        case .groupBuy: return "person.3.fill"
        case .syndicate: return "link.circle.fill"
        case .reverseAuction: return "arrow.down.circle.fill"
        case .rally: return "megaphone.fill"
        }
    }

    var description: String {
        switch self {
        case .groupBuy: return "Pool together for bulk pricing"
        case .syndicate: return "Coordinate switching for leverage"
        case .reverseAuction: return "Providers bid for your business"
        case .rally: return "Collective action for better rates"
        }
    }
}

/// Status of a cluster
enum ClusterStatus: String, Codable {
    case forming = "Forming"
    case active = "Active"
    case goalReached = "Goal Reached"
    case flashDrop = "Flash Drop"
    case completed = "Completed"
    case expired = "Expired"
}

/// A bid placed by a user to join a cluster
struct ClusterBid: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let maxPrice: Double
    let contractEndDate: Date?
    let willingToSwitch: Bool
    let needsInstall: Bool
    let zipCode: String
    let placedDate: Date

    init(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        maxPrice: Double,
        contractEndDate: Date? = nil,
        willingToSwitch: Bool = true,
        needsInstall: Bool = false,
        zipCode: String,
        placedDate: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.maxPrice = maxPrice
        self.contractEndDate = contractEndDate
        self.willingToSwitch = willingToSwitch
        self.needsInstall = needsInstall
        self.zipCode = zipCode
        self.placedDate = placedDate
    }
}

/// Flash Drop offer from a provider
struct FlashDropOffer: Codable, Identifiable {
    let id: UUID
    let providerName: String
    let providerLogoName: String
    let offerPrice: Double
    let originalPrice: Double
    let terms: String
    let expiresAt: Date
    let claimCount: Int
    let maxClaims: Int

    var savingsAmount: Double {
        originalPrice - offerPrice
    }

    var savingsPercent: Double {
        guard originalPrice > 0 else { return 0 }
        return (savingsAmount / originalPrice) * 100
    }

    var timeRemaining: String {
        let interval = expiresAt.timeIntervalSince(Date())
        if interval <= 0 { return "Expired" }
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)h left"
        } else {
            return "\(hours / 24)d left"
        }
    }

    init(
        id: UUID = UUID(),
        providerName: String,
        providerLogoName: String = "building.2",
        offerPrice: Double,
        originalPrice: Double,
        terms: String,
        expiresAt: Date,
        claimCount: Int = 0,
        maxClaims: Int = 100
    ) {
        self.id = id
        self.providerName = providerName
        self.providerLogoName = providerLogoName
        self.offerPrice = offerPrice
        self.originalPrice = originalPrice
        self.terms = terms
        self.expiresAt = expiresAt
        self.claimCount = claimCount
        self.maxClaims = maxClaims
    }
}

/// Cluster - group buy / syndicate model
struct Cluster: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: ClusterType
    let category: MarketplaceBillType
    var status: ClusterStatus

    // Progress
    let goalCount: Int
    var currentCount: Int
    var bids: [ClusterBid]

    // Aggregated stats
    var medianContractEnd: Date?
    var medianWillingToPay: Double?
    var coveredZipCodes: [String]

    // Timing
    let createdDate: Date
    let expiresDate: Date?

    // Flash drop (when goal reached)
    var flashDropOffer: FlashDropOffer?

    // Computed
    var progressPercent: Double {
        guard goalCount > 0 else { return 0 }
        return Double(currentCount) / Double(goalCount)
    }

    var isGoalReached: Bool {
        currentCount >= goalCount
    }

    var timeRemaining: String? {
        guard let expires = expiresDate else { return nil }
        let interval = expires.timeIntervalSince(Date())
        if interval <= 0 { return "Expired" }
        let days = Int(interval / 86400)
        if days > 0 {
            return "\(days)d left"
        }
        let hours = Int(interval / 3600)
        return "\(hours)h left"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: ClusterType = .groupBuy,
        category: MarketplaceBillType,
        status: ClusterStatus = .forming,
        goalCount: Int,
        currentCount: Int = 0,
        bids: [ClusterBid] = [],
        medianContractEnd: Date? = nil,
        medianWillingToPay: Double? = nil,
        coveredZipCodes: [String] = [],
        createdDate: Date = Date(),
        expiresDate: Date? = nil,
        flashDropOffer: FlashDropOffer? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.category = category
        self.status = status
        self.goalCount = goalCount
        self.currentCount = currentCount
        self.bids = bids
        self.medianContractEnd = medianContractEnd
        self.medianWillingToPay = medianWillingToPay
        self.coveredZipCodes = coveredZipCodes
        self.createdDate = createdDate
        self.expiresDate = expiresDate
        self.flashDropOffer = flashDropOffer
    }
}
