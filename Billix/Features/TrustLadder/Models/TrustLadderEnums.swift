//
//  TrustLadderEnums.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Enums for the Trust Ladder progressive swapping system
//

import Foundation
import SwiftUI

// MARK: - Trust Tier

enum TrustTier: Int, Codable, CaseIterable {
    case streamer = 1
    case utility = 2
    case guardian = 3

    var name: String {
        switch self {
        case .streamer: return "Streamer Zone"
        case .utility: return "Utility Zone"
        case .guardian: return "Guardian Zone"
        }
    }

    var displayName: String {
        name
    }

    var shortName: String {
        switch self {
        case .streamer: return "Streamer"
        case .utility: return "Utility"
        case .guardian: return "Guardian"
        }
    }

    var maxAmount: Double {
        switch self {
        case .streamer: return 25.0
        case .utility: return 150.0
        case .guardian: return 500.0
        }
    }

    var requiredSwapsToGraduate: Int? {
        switch self {
        case .streamer: return 5
        case .utility: return 5
        case .guardian: return nil // Top tier
        }
    }

    var requiredRating: Double? {
        switch self {
        case .streamer: return 4.5
        case .utility: return nil
        case .guardian: return nil
        }
    }

    var color: Color {
        switch self {
        case .streamer: return .purple
        case .utility: return .blue
        case .guardian: return .orange
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .streamer: return [.purple, .pink]
        case .utility: return [.blue, .cyan]
        case .guardian: return [.orange, .yellow]
        }
    }

    var icon: String {
        switch self {
        case .streamer: return "play.tv.fill"
        case .utility: return "bolt.fill"
        case .guardian: return "shield.fill"
        }
    }

    var description: String {
        switch self {
        case .streamer:
            return "Swap streaming & subscription bills up to $25"
        case .utility:
            return "Swap utility bills up to $150"
        case .guardian:
            return "Swap major bills up to $500"
        }
    }

    var nextTier: TrustTier? {
        switch self {
        case .streamer: return .utility
        case .utility: return .guardian
        case .guardian: return nil
        }
    }

    var unlockRequirements: [String] {
        switch self {
        case .streamer:
            return ["Email verified", "Phone verified"]
        case .utility:
            return ["Complete Tier 1", "5 successful swaps", "4.5+ rating"]
        case .guardian:
            return ["Complete Tier 2", "5 more swaps", "Government ID verified"]
        }
    }
}

// MARK: - Bill Categories by Tier

enum SwapBillCategory: String, Codable, CaseIterable, Identifiable {
    // Tier 1 - Streaming/Subscriptions
    case netflix
    case spotify
    case disneyPlus = "disney_plus"
    case xboxGamePass = "xbox_game_pass"
    case gym

    // Tier 2 - Utilities
    case water
    case electric
    case gas
    case internet

    // Tier 3 - Guardian
    case carInsurance = "car_insurance"
    case phonePlan = "phone_plan"
    case medical

    var id: String { rawValue }

    var tier: TrustTier {
        switch self {
        case .netflix, .spotify, .disneyPlus, .xboxGamePass, .gym:
            return .streamer
        case .water, .electric, .gas, .internet:
            return .utility
        case .carInsurance, .phonePlan, .medical:
            return .guardian
        }
    }

    var displayName: String {
        switch self {
        case .netflix: return "Netflix"
        case .spotify: return "Spotify"
        case .disneyPlus: return "Disney+"
        case .xboxGamePass: return "Xbox Game Pass"
        case .gym: return "Gym Membership"
        case .water: return "Water"
        case .electric: return "Electric"
        case .gas: return "Gas"
        case .internet: return "Internet"
        case .carInsurance: return "Car Insurance"
        case .phonePlan: return "Phone Plan"
        case .medical: return "Medical"
        }
    }

    var icon: String {
        switch self {
        case .netflix: return "tv.fill"
        case .spotify: return "music.note"
        case .disneyPlus: return "sparkles.tv.fill"
        case .xboxGamePass: return "gamecontroller.fill"
        case .gym: return "figure.strengthtraining.traditional"
        case .water: return "drop.fill"
        case .electric: return "bolt.fill"
        case .gas: return "flame.fill"
        case .internet: return "wifi"
        case .carInsurance: return "car.fill"
        case .phonePlan: return "iphone"
        case .medical: return "cross.case.fill"
        }
    }

    var color: Color {
        switch self {
        case .netflix: return .red
        case .spotify: return .green
        case .disneyPlus: return .blue
        case .xboxGamePass: return .green
        case .gym: return .orange
        case .water: return .cyan
        case .electric: return .yellow
        case .gas: return .orange
        case .internet: return .purple
        case .carInsurance: return .blue
        case .phonePlan: return .gray
        case .medical: return .red
        }
    }

    var typicalAmountRange: ClosedRange<Double> {
        switch self {
        case .netflix: return 6.99...22.99
        case .spotify: return 9.99...15.99
        case .disneyPlus: return 7.99...13.99
        case .xboxGamePass: return 9.99...16.99
        case .gym: return 10.00...50.00
        case .water: return 30.00...100.00
        case .electric: return 50.00...200.00
        case .gas: return 30.00...150.00
        case .internet: return 50.00...150.00
        case .carInsurance: return 100.00...300.00
        case .phonePlan: return 50.00...200.00
        case .medical: return 50.00...500.00
        }
    }

    static var streamerCategories: [SwapBillCategory] {
        [.netflix, .spotify, .disneyPlus, .xboxGamePass, .gym]
    }

    static var utilityCategories: [SwapBillCategory] {
        [.water, .electric, .gas, .internet]
    }

    static var guardianCategories: [SwapBillCategory] {
        [.carInsurance, .phonePlan, .medical]
    }

    static func categories(for tier: TrustTier) -> [SwapBillCategory] {
        switch tier {
        case .streamer: return streamerCategories
        case .utility: return utilityCategories
        case .guardian: return guardianCategories
        }
    }

    static func availableCategories(upToTier tier: TrustTier) -> [SwapBillCategory] {
        var categories: [SwapBillCategory] = []
        for t in TrustTier.allCases where t.rawValue <= tier.rawValue {
            categories.append(contentsOf: Self.categories(for: t))
        }
        return categories
    }
}

// MARK: - Swap Status

enum SwapStatus: String, Codable, CaseIterable {
    case pending
    case matched
    case feePending = "fee_pending"
    case feePaid = "fee_paid"
    case legAComplete = "leg_a_complete"
    case legBComplete = "leg_b_complete"
    case completed
    case disputed
    case failed
    case cancelled
    case refunded

    var displayName: String {
        switch self {
        case .pending: return "Finding Match"
        case .matched: return "Matched!"
        case .feePending: return "Awaiting Fee"
        case .feePaid: return "Ready to Execute"
        case .legAComplete: return "Your Payment Sent"
        case .legBComplete: return "Partner Payment Sent"
        case .completed: return "Completed"
        case .disputed: return "Under Review"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "magnifyingglass"
        case .matched: return "person.2.fill"
        case .feePending: return "creditcard"
        case .feePaid: return "checkmark.circle"
        case .legAComplete, .legBComplete: return "arrow.right.circle"
        case .completed: return "checkmark.seal.fill"
        case .disputed: return "exclamationmark.triangle"
        case .failed: return "xmark.circle"
        case .cancelled: return "xmark"
        case .refunded: return "arrow.uturn.backward"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .matched: return .blue
        case .feePending: return .orange
        case .feePaid: return .cyan
        case .legAComplete, .legBComplete: return .yellow
        case .completed: return .green
        case .disputed: return .yellow
        case .failed: return .red
        case .cancelled: return .gray
        case .refunded: return .purple
        }
    }

    var isActive: Bool {
        switch self {
        case .pending, .matched, .feePending, .feePaid, .legAComplete, .legBComplete:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled, .refunded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Verification Status

enum ScreenshotVerificationStatus: String, Codable {
    case pending
    case autoVerified = "auto_verified"
    case manualReview = "manual_review"
    case verified
    case rejected

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .autoVerified: return "Auto-Verified"
        case .manualReview: return "Under Manual Review"
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .autoVerified, .verified: return .green
        case .manualReview: return .orange
        case .rejected: return .red
        }
    }
}

// MARK: - Dispute Reason

enum DisputeReason: String, Codable, CaseIterable, Identifiable {
    case ghost
    case fakeScreenshot = "fake_screenshot"
    case wrongAmount = "wrong_amount"
    case wrongProvider = "wrong_provider"
    case harassment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ghost: return "Partner disappeared"
        case .fakeScreenshot: return "Fake or edited screenshot"
        case .wrongAmount: return "Wrong payment amount"
        case .wrongProvider: return "Paid wrong provider"
        case .harassment: return "Harassment"
        case .other: return "Other issue"
        }
    }

    var icon: String {
        switch self {
        case .ghost: return "person.fill.questionmark"
        case .fakeScreenshot: return "photo.fill"
        case .wrongAmount: return "dollarsign.circle"
        case .wrongProvider: return "building.2"
        case .harassment: return "exclamationmark.bubble"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Payday Type

enum PaydayType: String, Codable, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case semiMonthly = "semi_monthly"
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .semiMonthly: return "Twice a Month"
        case .monthly: return "Monthly"
        }
    }

    var description: String {
        switch self {
        case .weekly: return "Same day every week"
        case .biweekly: return "Every other week"
        case .semiMonthly: return "Two specific days per month (e.g., 1st & 15th)"
        case .monthly: return "Same day every month"
        }
    }

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar"
        case .semiMonthly: return "calendar.badge.2"
        case .monthly: return "calendar.circle"
        }
    }
}

// MARK: - Fee Transaction Status

enum FeeTransactionStatus: String, Codable {
    case pending
    case completed
    case refunded
    case failed
}
