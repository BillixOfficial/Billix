//
//  BillListing.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import Foundation

/// Grade tier for deals - like sneaker condition grading
enum DealGrade: String, Codable, CaseIterable {
    case sTier = "S-Tier"
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"

    var color: String {
        switch self {
        case .sTier: return "gold"
        case .aPlus, .a: return "green"
        case .b: return "yellow"
        case .c: return "orange"
        case .d: return "red"
        }
    }
}

/// Eligibility type for the deal
enum EligibilityType: String, Codable {
    case newCustomer = "New Cust"
    case existing = "Existing"
    case anyCustomer = "Any"
    case switchOnly = "Switch Only"
}

/// Friction level for obtaining the deal
enum FrictionLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "Digital chat only"
        case .medium: return "Phone call (~15 min)"
        case .high: return "Cancel threat + escalation"
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🔴"
        }
    }
}

/// Strategy type for obtaining the deal
enum StrategyType: String, Codable {
    case retentionCall = "RETENTION_CALL"
    case newSignup = "NEW_SIGNUP"
    case bundleStack = "BUNDLE_STACK"
    case loyaltyOffer = "LOYALTY_OFFER"
    case priceMatch = "PRICE_MATCH"
    case cancelThreat = "CANCEL_THREAT"
}

/// Bill type for marketplace listings
enum MarketplaceBillType: String, Codable, CaseIterable {
    case internet = "Internet"
    case mobile = "Mobile"
    case energy = "Energy"
    case insurance = "Insurance"
    case streaming = "Streaming"
    case creditCard = "Credit Card"
    case rent = "Rent"
    case other = "Other"

    var icon: String {
        switch self {
        case .internet: return "wifi"
        case .mobile: return "iphone"
        case .energy: return "bolt.fill"
        case .insurance: return "shield.fill"
        case .streaming: return "play.tv.fill"
        case .creditCard: return "creditcard.fill"
        case .rent: return "house.fill"
        case .other: return "doc.fill"
        }
    }
}

/// Dynamic specs that vary by bill category
struct DynamicSpecs: Codable, Identifiable {
    var id: UUID = UUID()
    let category: MarketplaceBillType

    // Internet specs
    var speed: String?
    var contractLength: String?
    var equipment: String?

    // Energy specs
    var planType: String?
    var rate: String?
    var renewablePercent: Int?

    // Credit Card specs
    var creditLimit: String?
    var apr: String?
    var rewards: String?

    // Rent specs
    var beds: Int?
    var sqft: Int?
    var floor: Int?

    // Generic specs
    var frequency: String?
    var dueDate: String?
    var autopay: Bool?

    /// Returns formatted spec items based on category
    var specItems: [(icon: String, label: String)] {
        switch category {
        case .internet:
            var items: [(String, String)] = []
            if let speed = speed { items.append(("bolt.fill", speed)) }
            if let contract = contractLength { items.append(("doc.text", contract)) }
            if let equip = equipment { items.append(("tv", equip)) }
            return items
        case .energy:
            var items: [(String, String)] = []
            if let plan = planType { items.append(("leaf.fill", plan)) }
            if let r = rate { items.append(("dollarsign.circle", r)) }
            if let renewable = renewablePercent { items.append(("sun.max.fill", "\(renewable)% Renewable")) }
            return items
        case .creditCard:
            var items: [(String, String)] = []
            if let limit = creditLimit { items.append(("creditcard", limit)) }
            if let apr = apr { items.append(("percent", apr)) }
            if let rewards = rewards { items.append(("star.fill", rewards)) }
            return items
        default:
            var items: [(String, String)] = []
            if let freq = frequency { items.append(("calendar", freq)) }
            if let due = dueDate { items.append(("clock", due)) }
            if autopay == true { items.append(("arrow.clockwise", "Autopay")) }
            return items
        }
    }
}

/// Blueprint - the hidden strategy/script behind a deal
struct Blueprint: Codable, Identifiable {
    let id: UUID
    let strategyType: StrategyType
    let script: String
    let dependencies: [String] // e.g., "AT&T Mobile Bundle", "Student ID"
    let pointsCost: Int
    let isVerified: Bool
    let successRate: Double
    let totalUses: Int

    init(
        id: UUID = UUID(),
        strategyType: StrategyType,
        script: String,
        dependencies: [String] = [],
        pointsCost: Int = 50,
        isVerified: Bool = false,
        successRate: Double = 0.0,
        totalUses: Int = 0
    ) {
        self.id = id
        self.strategyType = strategyType
        self.script = script
        self.dependencies = dependencies
        self.pointsCost = pointsCost
        self.isVerified = isVerified
        self.successRate = successRate
        self.totalUses = totalUses
    }
}

/// Q&A item on a bill listing
struct ListingQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let answer: String?
    let askedDate: Date
    let answeredDate: Date?

    init(
        id: UUID = UUID(),
        question: String,
        answer: String? = nil,
        askedDate: Date = Date(),
        answeredDate: Date? = nil
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.askedDate = askedDate
        self.answeredDate = answeredDate
    }
}

/// Main Bill Listing model - the "asset" being traded
struct BillListing: Codable, Identifiable {
    let id: UUID

    // Zone 1: Identity & Trust
    let providerName: String
    let providerLogoName: String
    let isVerified: Bool
    let postedDate: Date
    let zipCode: String
    let reliabilityScore: Double
    let eligibility: EligibilityType
    var matchScore: Int // 0-100, personalized

    // Zone 2: Financial Spread
    let askPrice: Double
    let marketAvgPrice: Double
    let trueCost: Double // After fees
    let fees: Double
    let promoDuration: Int? // Months locked at promo rate
    let grade: DealGrade

    // Zone 3: Dynamic Specs
    let category: MarketplaceBillType
    let specs: DynamicSpecs
    let frictionLevel: FrictionLevel
    let requirements: [String] // e.g., "Autopay", "Mobile Bundle"

    // Zone 4: Blueprint
    let blueprint: Blueprint
    let questions: [ListingQuestion]

    // Zone 5: Seller
    let sellerId: UUID
    let sellerHandle: String
    let sellerTotalSaved: Double
    let sellerSuccessRate: Double
    let sellerTotalUses: Int
    let isSherpa: Bool

    // Live activity
    var viewingCount: Int
    var unlocksPerHour: Int
    var watchlistCount: Int

    // Computed
    var savingsVsMarket: Double {
        marketAvgPrice - askPrice
    }

    var savingsPercentage: Double {
        guard marketAvgPrice > 0 else { return 0 }
        return (savingsVsMarket / marketAvgPrice) * 100
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(postedDate)
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else if minutes < 1440 {
            return "\(minutes / 60)h ago"
        } else {
            return "\(minutes / 1440)d ago"
        }
    }

    init(
        id: UUID = UUID(),
        providerName: String,
        providerLogoName: String = "building.2",
        isVerified: Bool = true,
        postedDate: Date = Date(),
        zipCode: String,
        reliabilityScore: Double = 4.5,
        eligibility: EligibilityType = .anyCustomer,
        matchScore: Int = 85,
        askPrice: Double,
        marketAvgPrice: Double,
        trueCost: Double? = nil,
        fees: Double = 0,
        promoDuration: Int? = nil,
        grade: DealGrade = .a,
        category: MarketplaceBillType,
        specs: DynamicSpecs,
        frictionLevel: FrictionLevel = .low,
        requirements: [String] = [],
        blueprint: Blueprint,
        questions: [ListingQuestion] = [],
        sellerId: UUID = UUID(),
        sellerHandle: String,
        sellerTotalSaved: Double = 0,
        sellerSuccessRate: Double = 0.85,
        sellerTotalUses: Int = 0,
        isSherpa: Bool = false,
        viewingCount: Int = 0,
        unlocksPerHour: Int = 0,
        watchlistCount: Int = 0
    ) {
        self.id = id
        self.providerName = providerName
        self.providerLogoName = providerLogoName
        self.isVerified = isVerified
        self.postedDate = postedDate
        self.zipCode = zipCode
        self.reliabilityScore = reliabilityScore
        self.eligibility = eligibility
        self.matchScore = matchScore
        self.askPrice = askPrice
        self.marketAvgPrice = marketAvgPrice
        self.trueCost = trueCost ?? (askPrice + fees)
        self.fees = fees
        self.promoDuration = promoDuration
        self.grade = grade
        self.category = category
        self.specs = specs
        self.frictionLevel = frictionLevel
        self.requirements = requirements
        self.blueprint = blueprint
        self.questions = questions
        self.sellerId = sellerId
        self.sellerHandle = sellerHandle
        self.sellerTotalSaved = sellerTotalSaved
        self.sellerSuccessRate = sellerSuccessRate
        self.sellerTotalUses = sellerTotalUses
        self.isSherpa = isSherpa
        self.viewingCount = viewingCount
        self.unlocksPerHour = unlocksPerHour
        self.watchlistCount = watchlistCount
    }
}
