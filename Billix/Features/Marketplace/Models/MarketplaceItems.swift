//
//  MarketplaceItems.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import Foundation

// MARK: - Bounty

/// Status of a bounty request
enum BountyStatus: String, Codable {
    case open = "Open"
    case claimed = "Claimed"
    case verified = "Verified"
    case expired = "Expired"
}

/// Bounty - request for specific bill data
struct Bounty: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: MarketplaceBillType
    let providerName: String?
    let zipCode: String?
    let requirements: [String]
    let rewardPoints: Int
    var status: BountyStatus
    let postedDate: Date
    let expiresDate: Date?
    let posterId: UUID
    var claimCount: Int

    var timeRemaining: String? {
        guard let expires = expiresDate else { return nil }
        let interval = expires.timeIntervalSince(Date())
        if interval <= 0 { return "Expired" }
        let days = Int(interval / 86400)
        if days > 0 { return "\(days)d left" }
        let hours = Int(interval / 3600)
        return "\(hours)h left"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: MarketplaceBillType,
        providerName: String? = nil,
        zipCode: String? = nil,
        requirements: [String] = [],
        rewardPoints: Int,
        status: BountyStatus = .open,
        postedDate: Date = Date(),
        expiresDate: Date? = nil,
        posterId: UUID = UUID(),
        claimCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.providerName = providerName
        self.zipCode = zipCode
        self.requirements = requirements
        self.rewardPoints = rewardPoints
        self.status = status
        self.postedDate = postedDate
        self.expiresDate = expiresDate
        self.posterId = posterId
        self.claimCount = claimCount
    }
}

// MARK: - Script Card

/// Standalone script/bluff for negotiation
struct NegotiationScript: Codable, Identifiable {
    let id: UUID
    let title: String
    let script: String
    let providerName: String?
    let category: MarketplaceBillType
    let successRate: Double
    let totalWins: Int
    let totalUses: Int
    let pointsCost: Int
    let authorId: UUID
    let authorHandle: String
    let postedDate: Date
    let isVerified: Bool

    var successPercent: Int {
        Int(successRate * 100)
    }

    init(
        id: UUID = UUID(),
        title: String,
        script: String,
        providerName: String? = nil,
        category: MarketplaceBillType,
        successRate: Double = 0.8,
        totalWins: Int = 0,
        totalUses: Int = 0,
        pointsCost: Int = 50,
        authorId: UUID = UUID(),
        authorHandle: String,
        postedDate: Date = Date(),
        isVerified: Bool = false
    ) {
        self.id = id
        self.title = title
        self.script = script
        self.providerName = providerName
        self.category = category
        self.successRate = successRate
        self.totalWins = totalWins
        self.totalUses = totalUses
        self.pointsCost = pointsCost
        self.authorId = authorId
        self.authorHandle = authorHandle
        self.postedDate = postedDate
        self.isVerified = isVerified
    }
}

// MARK: - Service/Gig Card

/// Type of service offered
enum ServiceType: String, Codable, CaseIterable {
    case billAudit = "Bill Audit"
    case negotiation = "Negotiation"
    case billRoast = "Bill Roast"
    case consultation = "Consultation"
    case switching = "Switching Help"

    var icon: String {
        switch self {
        case .billAudit: return "magnifyingglass.circle.fill"
        case .negotiation: return "phone.fill"
        case .billRoast: return "flame.fill"
        case .consultation: return "person.crop.circle.badge.questionmark"
        case .switching: return "arrow.left.arrow.right"
        }
    }
}

/// Compensation model for services
enum CompensationType: String, Codable {
    case tips = "Tips"
    case fixed = "Fixed"
    case percentage = "Percentage of Savings"
    case free = "Free"
}

/// Service/Gig offering
struct ServiceListing: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let serviceType: ServiceType
    let categories: [MarketplaceBillType]
    let providerId: UUID
    let providerHandle: String
    let isVerifiedHighSaver: Bool
    let compensation: CompensationType
    let suggestedAmount: Int? // Points or dollars
    let rating: Double
    let reviewCount: Int
    let completedJobs: Int
    let responseTime: String // e.g., "< 1 hour"

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        serviceType: ServiceType,
        categories: [MarketplaceBillType],
        providerId: UUID = UUID(),
        providerHandle: String,
        isVerifiedHighSaver: Bool = false,
        compensation: CompensationType = .tips,
        suggestedAmount: Int? = nil,
        rating: Double = 4.5,
        reviewCount: Int = 0,
        completedJobs: Int = 0,
        responseTime: String = "< 24 hours"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.serviceType = serviceType
        self.categories = categories
        self.providerId = providerId
        self.providerHandle = providerHandle
        self.isVerifiedHighSaver = isVerifiedHighSaver
        self.compensation = compensation
        self.suggestedAmount = suggestedAmount
        self.rating = rating
        self.reviewCount = reviewCount
        self.completedJobs = completedJobs
        self.responseTime = responseTime
    }
}

// MARK: - Prediction Market

/// Prediction outcome
enum PredictionOutcome: String, Codable {
    case yes = "YES"
    case no = "NO"
    case pending = "Pending"
}

/// Prediction market card
struct PredictionMarket: Codable, Identifiable {
    let id: UUID
    let question: String
    let description: String?
    let category: MarketplaceBillType
    let providerName: String?
    let currentValue: Double? // e.g., current rate
    let targetValue: Double? // e.g., predicted rate
    let targetDate: Date
    var yesPercent: Double
    var noPercent: Double
    let totalStaked: Int // Total points staked
    var outcome: PredictionOutcome
    let createdDate: Date

    var yesOdds: String {
        String(format: "%.0f%%", yesPercent)
    }

    var noOdds: String {
        String(format: "%.0f%%", noPercent)
    }

    var timeToResolution: String {
        let interval = targetDate.timeIntervalSince(Date())
        if interval <= 0 { return "Resolving..." }
        let days = Int(interval / 86400)
        if days > 30 {
            return "\(days / 30)mo"
        } else if days > 0 {
            return "\(days)d"
        }
        let hours = Int(interval / 3600)
        return "\(hours)h"
    }

    init(
        id: UUID = UUID(),
        question: String,
        description: String? = nil,
        category: MarketplaceBillType,
        providerName: String? = nil,
        currentValue: Double? = nil,
        targetValue: Double? = nil,
        targetDate: Date,
        yesPercent: Double = 50,
        noPercent: Double = 50,
        totalStaked: Int = 0,
        outcome: PredictionOutcome = .pending,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.description = description
        self.category = category
        self.providerName = providerName
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.yesPercent = yesPercent
        self.noPercent = noPercent
        self.totalStaked = totalStaked
        self.outcome = outcome
        self.createdDate = createdDate
    }
}

// MARK: - Contract Takeover

/// Contract takeover listing
struct ContractTakeover: Codable, Identifiable {
    let id: UUID
    let title: String
    let providerName: String
    let providerLogoName: String
    let category: MarketplaceBillType
    let monthlyRate: Double
    let monthsRemaining: Int
    let etfAvoided: Double // Early termination fee avoided
    let sellerIncentive: Double // Cash/points offered to taker
    let specs: DynamicSpecs
    let sellerId: UUID
    let sellerHandle: String
    let postedDate: Date
    var inquiryCount: Int

    var totalValue: String {
        let value = etfAvoided + sellerIncentive
        return String(format: "$%.0f value", value)
    }

    init(
        id: UUID = UUID(),
        title: String,
        providerName: String,
        providerLogoName: String = "building.2",
        category: MarketplaceBillType,
        monthlyRate: Double,
        monthsRemaining: Int,
        etfAvoided: Double,
        sellerIncentive: Double = 0,
        specs: DynamicSpecs,
        sellerId: UUID = UUID(),
        sellerHandle: String,
        postedDate: Date = Date(),
        inquiryCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.providerName = providerName
        self.providerLogoName = providerLogoName
        self.category = category
        self.monthlyRate = monthlyRate
        self.monthsRemaining = monthsRemaining
        self.etfAvoided = etfAvoided
        self.sellerIncentive = sellerIncentive
        self.specs = specs
        self.sellerId = sellerId
        self.sellerHandle = sellerHandle
        self.postedDate = postedDate
        self.inquiryCount = inquiryCount
    }
}

// MARK: - Marketplace User

/// User profile for marketplace
struct MarketplaceUser: Codable, Identifiable {
    let id: UUID
    let handle: String
    let avatarName: String? // SF Symbol or memoji name
    let joinedDate: Date
    var totalSaved: Double
    var successfulDeals: Int
    var totalDeals: Int
    var points: Int
    var isSherpa: Bool
    var isVerifiedHighSaver: Bool
    var badges: [String]
    var zipCode: String?

    var successRate: Double {
        guard totalDeals > 0 else { return 0 }
        return Double(successfulDeals) / Double(totalDeals)
    }

    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: joinedDate)
    }

    init(
        id: UUID = UUID(),
        handle: String,
        avatarName: String? = nil,
        joinedDate: Date = Date(),
        totalSaved: Double = 0,
        successfulDeals: Int = 0,
        totalDeals: Int = 0,
        points: Int = 0,
        isSherpa: Bool = false,
        isVerifiedHighSaver: Bool = false,
        badges: [String] = [],
        zipCode: String? = nil
    ) {
        self.id = id
        self.handle = handle
        self.avatarName = avatarName
        self.joinedDate = joinedDate
        self.totalSaved = totalSaved
        self.successfulDeals = successfulDeals
        self.totalDeals = totalDeals
        self.points = points
        self.isSherpa = isSherpa
        self.isVerifiedHighSaver = isVerifiedHighSaver
        self.badges = badges
        self.zipCode = zipCode
    }
}
