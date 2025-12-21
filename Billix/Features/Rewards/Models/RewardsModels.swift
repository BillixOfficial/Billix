//
//  RewardsModels.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Models for the Rewards Hub - Points, Marketplace, Games, Leaderboard
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Tier System

enum RewardsTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var pointsRange: ClosedRange<Int> {
        switch self {
        case .bronze: return 0...7999
        case .silver: return 8000...29999
        case .gold: return 30000...99999
        case .platinum: return 100000...Int.max
        }
    }

    var nextTier: RewardsTier? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return nil
        }
    }

    var color: Color {
        switch self {
        case .bronze: return .billixBronzeTier
        case .silver: return .billixSilverTier
        case .gold: return .billixGoldTier
        case .platinum: return .billixPlatinumTier
        }
    }
}

// MARK: - Rewards Points (Separate from BillixCredits)

struct RewardsPoints: Codable, Equatable {
    var balance: Int
    var lifetimeEarned: Int
    var transactions: [PointTransaction]

    var cashEquivalent: Double {
        Double(balance) / 2000.0 // 2,000 points = $1 (scaled economy)
    }

    var recentTransactions: [PointTransaction] {
        Array(transactions.prefix(10))
    }
}

struct PointTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: PointTransactionType
    let amount: Int
    let description: String
    let createdAt: Date

    var amountString: String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(amount)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: createdAt)
    }
}

enum PointTransactionType: String, Codable {
    case gameWin = "Game Win"
    case dailyBonus = "Daily Bonus"
    case redemption = "Redemption"
    case referral = "Referral"
    case achievement = "Achievement"
}

// MARK: - Marketplace Rewards

struct Reward: Identifiable, Codable, Equatable {
    let id: UUID
    let type: RewardType
    let category: RewardCategory  // New: categorization for marketplace sections
    let title: String
    let description: String
    let pointsCost: Int
    let brand: String?
    let dollarValue: Double?
    let iconName: String
    let accentColor: String // Hex color for brand theming

    var formattedCost: String {
        "\(pointsCost) pts"
    }

    var formattedValue: String? {
        guard let value = dollarValue else { return nil }
        return String(format: "$%.0f", value)
    }
}

enum RewardCategory: String, Codable, CaseIterable {
    case virtualGoods = "Virtual Goods"
    case giveaway = "Giveaways"
    case giftCard = "Gift Cards"
}

enum RewardType: String, Codable, CaseIterable {
    case billCredit = "Bill Credit"
    case giftCard = "Gift Card"
    case digitalGood = "Digital Good"
    case giveawayEntry = "Giveaway Entry"
    case customization = "Customization"

    var icon: String {
        switch self {
        case .billCredit: return "dollarsign.circle.fill"
        case .giftCard: return "giftcard.fill"
        case .digitalGood: return "sparkles"
        case .giveawayEntry: return "ticket.fill"
        case .customization: return "paintpalette.fill"
        }
    }
}

// MARK: - Geo Game Support Types

struct LocationCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct MapRegionData: Codable, Equatable {
    let centerLatitude: Double
    let centerLongitude: Double
    let pitch: Double
    let heading: Double

    var mapCamera: MapCamera {
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            distance: 5000,
            heading: heading,
            pitch: pitch
        )
    }

    func updatedCamera(heading: Double, distance: Double, pitch: Double) -> MapCamera {
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            distance: distance,
            heading: heading,
            pitch: pitch
        )
    }
}

struct DecoyLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let displayLabel: String

    init(id: UUID = UUID(), name: String, displayLabel: String) {
        self.id = id
        self.name = name
        self.displayLabel = displayLabel
    }
}

// MARK: - Daily Game (Price Guessr)

struct DailyGame: Identifiable, Codable, Equatable {
    let id: UUID
    let subject: String          // "Milk" or "1-Bedroom Apartment"
    let location: String         // "Manhattan, NY"
    let locationCode: String     // "10001"
    let category: GameCategory
    let actualPrice: Double
    let minGuess: Double
    let maxGuess: Double
    let unit: String             // "gallon", "month", etc.
    let expiresAt: Date

    // GEO GAME EXTENSIONS (all optional for backward compatibility)
    let gameMode: GameMode?              // .groceryRun or .apartmentHunt
    let coordinates: LocationCoordinate? // Lat/long for map center
    let mapRegion: MapRegionData?        // Camera settings (pitch, heading, zoom)
    let decoyLocations: [DecoyLocation]? // Wrong answer choices (A/B/C/D)
    let economicContext: String?         // "To live here, need $X/year"
    let landmarkCoordinate: LocationCoordinate? // Famous landmark to center camera on

    var formattedSubject: String {
        "\(subject) in \(location)"
    }

    var priceRange: ClosedRange<Double> {
        minGuess...maxGuess
    }

    var isGeoGame: Bool {
        gameMode != nil && coordinates != nil && mapRegion != nil
    }
}

enum GameCategory: String, Codable, CaseIterable {
    case grocery = "Grocery"
    case rent = "Rent"
    case utility = "Utility"
    case subscription = "Subscription"
    case gas = "Gas"

    var icon: String {
        switch self {
        case .grocery: return "cart.fill"
        case .rent: return "house.fill"
        case .utility: return "bolt.fill"
        case .subscription: return "tv.fill"
        case .gas: return "fuelpump.fill"
        }
    }

    var color: Color {
        switch self {
        case .grocery: return .green
        case .rent: return .blue
        case .utility: return .orange
        case .subscription: return .purple
        case .gas: return .red
        }
    }
}

enum GameMode: String, Codable {
    case groceryRun = "The Grocery Run"
    case apartmentHunt = "The Apartment Hunt"

    var icon: String {
        switch self {
        case .groceryRun: return "cart.fill"
        case .apartmentHunt: return "house.fill"
        }
    }

    var description: String {
        switch self {
        case .groceryRun: return "Guess grocery prices around the world"
        case .apartmentHunt: return "Estimate rent in different cities"
        }
    }
}

struct GameResult: Identifiable, Codable, Equatable {
    let id: UUID
    let gameId: UUID
    let userGuess: Double
    let actualPrice: Double
    let pointsEarned: Int
    let accuracy: Double         // 0.0 to 1.0 (1.0 = perfect)
    let playedAt: Date

    var accuracyPercentage: Int {
        Int(accuracy * 100)
    }

    var resultType: GameResultType {
        if accuracy >= 0.95 { return .perfect }
        else if accuracy >= 0.85 { return .close }
        else { return .miss }
    }

    var formattedGuess: String {
        String(format: "$%.2f", userGuess)
    }

    var formattedActual: String {
        String(format: "$%.2f", actualPrice)
    }
}

enum GameResultType {
    case perfect  // Within 5%
    case close    // Within 15%
    case miss     // More than 15% off

    var title: String {
        switch self {
        case .perfect: return "Amazing!"
        case .close: return "So close!"
        case .miss: return "Good try!"
        }
    }

    var color: Color {
        switch self {
        case .perfect: return .billixArcadeGold
        case .close: return .billixMoneyGreen
        case .miss: return .billixMediumGreen
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let rank: Int
    let displayName: String
    let avatarInitials: String
    let pointsThisWeek: Int
    let isCurrentUser: Bool

    var formattedPoints: String {
        "\(pointsThisWeek) pts"
    }

    var rankBadgeColor: Color {
        switch rank {
        case 1: return .billixLeaderGold
        case 2: return .billixLeaderSilver
        case 3: return .billixLeaderBronze
        default: return .billixMediumGreen
        }
    }
}

// MARK: - Preview Data

extension RewardsPoints {
    static let preview = RewardsPoints(
        balance: 12000,  // Changed to 12,000 (Silver tier) to show unlocked shop
        lifetimeEarned: 15000,
        transactions: [
            PointTransaction(
                id: UUID(),
                type: .gameWin,
                amount: 100,
                description: "Daily Price Guessr - Perfect!",
                createdAt: Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .dailyBonus,
                amount: 25,
                description: "Daily login bonus",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .redemption,
                amount: -500,
                description: "Redeemed $5 Amazon Gift Card",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .gameWin,
                amount: 50,
                description: "Daily Price Guessr - Close!",
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            PointTransaction(
                id: UUID(),
                type: .referral,
                amount: 200,
                description: "Friend joined and played",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            )
        ]
    )
}

extension Reward {
    static let previewRewards: [Reward] = [
        // $1 Quick Win Rewards
        Reward(
            id: UUID(),
            type: .billCredit,
            category: .giftCard,
            title: "$1 Bill Credit",
            description: "$1 off your next Billix Bill Pay",
            pointsCost: 2000,  // $1 @ 2,000:1 ratio
            brand: "Billix",
            dollarValue: 1,
            iconName: "dollarsign.circle.fill",
            accentColor: "#5b8a6b"
        ),
        // $2.50 Rewards
        Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$2.50 Starbucks Gift Card",
            description: "Use at any Starbucks location",
            pointsCost: 5000,  // $2.50 @ 2,000:1 ratio
            brand: "Starbucks",
            dollarValue: 2.5,
            iconName: "cup.and.saucer.fill",
            accentColor: "#00704A"
        ),
        // $5 Rewards
        Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$5 Amazon Gift Card",
            description: "Redeemable on Amazon.com",
            pointsCost: 10000,  // $5 @ 2,000:1 ratio
            brand: "Amazon",
            dollarValue: 5,
            iconName: "gift.fill",
            accentColor: "#FF9900"
        ),
        // $10 Rewards
        Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$10 Target Gift Card",
            description: "Shop at Target stores or online",
            pointsCost: 20000,  // $10 @ 2,000:1 ratio ✅
            brand: "Target",
            dollarValue: 10,
            iconName: "target",
            accentColor: "#CC0000"
        ),
        // Premium Digital Good
        Reward(
            id: UUID(),
            type: .digitalGood,
            category: .virtualGoods,
            title: "Premium Market Data",
            description: "Unlock 30 days of premium insights",
            pointsCost: 15000,  // $7.50 @ 2,000:1 ratio
            brand: nil,
            dollarValue: 7.5,
            iconName: "chart.line.uptrend.xyaxis",
            accentColor: "#52b8df"
        )
    ]

    // NEW: Complete preview data with all 4 categories (Gift Cards, Game Boosts, Virtual Goods, Giveaways)
    static let previewRewardsWithCategories: [Reward] = [
        // GAME BOOSTS (250-500 pts) - Power-ups for Price Guessr
        Reward(
            id: UUID(),
            type: .digitalGood,
            category: .virtualGoods,
            title: "Extra Life",
            description: "One more chance if you lose",
            pointsCost: 500,
            brand: nil,
            dollarValue: nil,
            iconName: "heart.fill",
            accentColor: "#FF6B6B"
        ),
        Reward(
            id: UUID(),
            type: .digitalGood,
            category: .virtualGoods,
            title: "Skip Question",
            description: "Pass a difficult question",
            pointsCost: 300,
            brand: nil,
            dollarValue: nil,
            iconName: "forward.fill",
            accentColor: "#95E1D3"
        ),
        Reward(
            id: UUID(),
            type: .digitalGood,
            category: .virtualGoods,
            title: "Time Freeze",
            description: "+15 seconds on timer",
            pointsCost: 400,
            brand: nil,
            dollarValue: nil,
            iconName: "clock.fill",
            accentColor: "#F38181"
        ),
        Reward(
            id: UUID(),
            type: .digitalGood,
            category: .virtualGoods,
            title: "Hint Token",
            description: "Reveal one wrong answer",
            pointsCost: 250,
            brand: nil,
            dollarValue: nil,
            iconName: "lightbulb.fill",
            accentColor: "#FFD93D"
        ),

        // VIRTUAL GOODS (100-500 pts) - Zero cost to developer
        Reward(
            id: UUID(),
            type: .customization,
            category: .virtualGoods,
            title: "Dark Mode Theme",
            description: "Unlock sleek dark interface",
            pointsCost: 200,  // $0.10 equivalent (zero real cost)
            brand: nil,
            dollarValue: nil,
            iconName: "moon.fill",
            accentColor: "#2C2C2E"
        ),
        Reward(
            id: UUID(),
            type: .customization,
            category: .virtualGoods,
            title: "Premium Dashboard",
            description: "Unlock advanced analytics view",
            pointsCost: 500,  // $0.25 equivalent (zero real cost)
            brand: nil,
            dollarValue: nil,
            iconName: "chart.bar.fill",
            accentColor: "#52b8df"
        ),
        Reward(
            id: UUID(),
            type: .customization,
            category: .virtualGoods,
            title: "Custom Bill Colors",
            description: "Personalize bill categories",
            pointsCost: 300,  // $0.15 equivalent (zero real cost)
            brand: nil,
            dollarValue: nil,
            iconName: "paintpalette.fill",
            accentColor: "#FF6B35"
        ),

        // GIVEAWAYS (100 pts per entry) - Amortized cost
        Reward(
            id: UUID(),
            type: .giveawayEntry,
            category: .giveaway,
            title: "Weekly Drawing Entry",
            description: "1 entry for $2.50 prize drawing",
            pointsCost: 100,  // $0.05 equivalent
            brand: nil,
            dollarValue: 0.05,
            iconName: "ticket.fill",
            accentColor: "#FFD700"
        ),
        Reward(
            id: UUID(),
            type: .giveawayEntry,
            category: .giveaway,
            title: "5-Entry Bundle",
            description: "5 entries for weekly drawing",
            pointsCost: 450,  // 10% discount vs individual
            brand: nil,
            dollarValue: 0.25,
            iconName: "ticket.fill",
            accentColor: "#FFA500"
        ),

        // GIFT CARDS ($0.50-$2) - Low-barrier real value
        Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$0.50 Starbucks Card",
            description: "Micro reward for early users",
            pointsCost: 1000,  // $0.50 @ 2,000:1 ratio
            brand: "Starbucks",
            dollarValue: 0.5,
            iconName: "cup.and.saucer.fill",
            accentColor: "#00704A"
        ),
        Reward(
            id: UUID(),
            type: .billCredit,
            category: .giftCard,
            title: "$1.00 Bill Credit",
            description: "$1 off your next bill payment",
            pointsCost: 2000,  // $1 @ 2,000:1 ratio
            brand: "Billix",
            dollarValue: 1,
            iconName: "dollarsign.circle.fill",
            accentColor: "#5b8a6b"
        ),
        Reward(
            id: UUID(),
            type: .giftCard,
            category: .giftCard,
            title: "$2.00 Amazon Card",
            description: "Redeem on Amazon.com",
            pointsCost: 4000,  // $2 @ 2,000:1 ratio
            brand: "Amazon",
            dollarValue: 2,
            iconName: "gift.fill",
            accentColor: "#FF9900"
        )
    ]
}

extension DailyGame {
    static let preview = DailyGame(
        id: UUID(),
        subject: "Milk",
        location: "Manhattan, NY",
        locationCode: "10001",
        category: .grocery,
        actualPrice: 4.89,
        minGuess: 2.00,
        maxGuess: 8.00,
        unit: "gallon",
        expiresAt: Calendar.current.date(byAdding: .hour, value: 14, to: Date()) ?? Date(),
        gameMode: nil,
        coordinates: nil,
        mapRegion: nil,
        decoyLocations: nil,
        economicContext: nil,
        landmarkCoordinate: nil
    )
}

extension GameResult {
    static let preview = GameResult(
        id: UUID(),
        gameId: UUID(),
        userGuess: 4.75,
        actualPrice: 4.89,
        pointsEarned: 80,
        accuracy: 0.97,
        playedAt: Date()
    )
}

extension LeaderboardEntry {
    static let previewEntries: [LeaderboardEntry] = [
        LeaderboardEntry(
            id: UUID(),
            rank: 1,
            displayName: "Sarah M.",
            avatarInitials: "SM",
            pointsThisWeek: 850,
            isCurrentUser: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 2,
            displayName: "Mike T.",
            avatarInitials: "MT",
            pointsThisWeek: 720,
            isCurrentUser: false
        ),
        LeaderboardEntry(
            id: UUID(),
            rank: 3,
            displayName: "Jessica L.",
            avatarInitials: "JL",
            pointsThisWeek: 680,
            isCurrentUser: false
        )
    ]

    static let currentUserEntry = LeaderboardEntry(
        id: UUID(),
        rank: 42,
        displayName: "You",
        avatarInitials: "DK",
        pointsThisWeek: 150,
        isCurrentUser: true
    )
}
