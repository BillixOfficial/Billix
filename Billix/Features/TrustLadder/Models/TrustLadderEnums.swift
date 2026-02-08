//
//  TrustLadderEnums.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Enums for the Trust Ladder progressive swapping system
//

import Foundation
import SwiftUI

// MARK: - Reputation Tier (New 3-Tier System for Bill Connection)

/// Reputation tiers for the Bill Connection feature
/// Based on verification level and successful connections
enum ReputationTier: Int, Codable, CaseIterable {
    case neighbor = 1       // Entry level: SMS + Social OAuth
    case contributor = 2    // Verified Prime + Gov ID
    case pillar = 3         // 15 clean connections

    var name: String {
        switch self {
        case .neighbor: return "Neighbor"
        case .contributor: return "Contributor"
        case .pillar: return "Pillar"
        }
    }

    var displayName: String {
        name
    }

    var shortName: String {
        name
    }

    var maxAmount: Double {
        switch self {
        case .neighbor: return 25.0
        case .contributor: return 150.0
        case .pillar: return 500.0
        }
    }

    /// Maximum connections per month (nil = unlimited)
    var velocityLimit: Int? {
        switch self {
        case .neighbor: return 1      // 1 connection per month
        case .contributor: return nil // Unlimited
        case .pillar: return nil      // Unlimited
        }
    }

    var requiredConnectionsToGraduate: Int? {
        switch self {
        case .neighbor: return nil    // Upgrade via verification, not connections
        case .contributor: return 15  // 15 clean connections to reach Pillar
        case .pillar: return nil      // Top tier
        }
    }

    var color: Color {
        switch self {
        case .neighbor: return Color(hex: "#5B8A6B")    // billixMoneyGreen
        case .contributor: return Color(hex: "#9B7B9F") // billixPurple
        case .pillar: return Color(hex: "#E8B54D")      // billixGoldenAmber
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .neighbor: return [Color(hex: "#5B8A6B"), Color(hex: "#7DAD8D")]
        case .contributor: return [Color(hex: "#9B7B9F"), Color(hex: "#B99BBD")]
        case .pillar: return [Color(hex: "#E8B54D"), Color(hex: "#F0C86B")]
        }
    }

    var icon: String {
        switch self {
        case .neighbor: return "person.fill"
        case .contributor: return "person.2.fill"
        case .pillar: return "building.columns.fill"
        }
    }

    var description: String {
        switch self {
        case .neighbor:
            return "Support bills up to $25, 1 connection per month"
        case .contributor:
            return "Support bills up to $150, unlimited connections"
        case .pillar:
            return "Support bills up to $500, community leader status"
        }
    }

    var nextTier: ReputationTier? {
        switch self {
        case .neighbor: return .contributor
        case .contributor: return .pillar
        case .pillar: return nil
        }
    }

    var requirements: String {
        switch self {
        case .neighbor:
            return "SMS + Social OAuth verified"
        case .contributor:
            return "Verified Prime + Government ID"
        case .pillar:
            return "15 successful connections"
        }
    }

    var unlockRequirements: [String] {
        switch self {
        case .neighbor:
            return ["SMS verified", "Social OAuth connected"]
        case .contributor:
            return ["Verified Prime member", "Government ID verified"]
        case .pillar:
            return ["15 clean connections", "No disputes in last 30 days"]
        }
    }
}

// MARK: - Legacy Trust Tier (Backwards Compatibility)

/// Legacy trust tier enum - use ReputationTier for new code
/// Kept for backwards compatibility with existing code
typealias TrustTier = ReputationTier

extension ReputationTier {
    /// Legacy compatibility: map old tier names to new
    static var streamer: ReputationTier { .neighbor }
    static var utility: ReputationTier { .contributor }
    static var guardian: ReputationTier { .pillar }

    /// Legacy compatibility: requiredSwapsToGraduate maps to requiredConnectionsToGraduate
    var requiredSwapsToGraduate: Int? {
        requiredConnectionsToGraduate
    }

    /// Legacy compatibility: minimum rating required to advance (only for Neighbor tier)
    var requiredRating: Double? {
        switch self {
        case .neighbor: return 4.0  // Need 4.0+ rating to graduate to Contributor
        case .contributor: return nil
        case .pillar: return nil
        }
    }
}

// MARK: - Bill Categories by Tier

enum SwapBillCategory: String, Codable, CaseIterable, Identifiable {
    // MARK: Tier 1 - Streaming & Subscriptions (up to $25)

    // Streaming Services
    case netflix
    case spotify
    case disneyPlus = "disney_plus"
    case hulu
    case hboMax = "hbo_max"
    case primeVideo = "prime_video"
    case peacock
    case paramountPlus = "paramount_plus"
    case appleTvPlus = "apple_tv_plus"
    case youtubeMusic = "youtube_music"
    case appleMusic = "apple_music"
    case tidal

    // Gaming Subscriptions
    case xboxGamePass = "xbox_game_pass"
    case playstationPlus = "playstation_plus"
    case nintendoOnline = "nintendo_online"

    // Fitness & Wellness
    case gym
    case fitnessApp = "fitness_app"

    // Cloud & Software
    case cloudStorage = "cloud_storage"
    case softwareSubscription = "software_subscription"

    // Meal & Delivery
    case mealKit = "meal_kit"
    case groceryDelivery = "grocery_delivery"

    // MARK: Tier 2 - Utilities & Moderate Bills ($25-150)

    // Household Utilities
    case electric
    case naturalGas = "natural_gas"
    case water
    case sewer
    case trash
    case heatingOil = "heating_oil"
    case propane

    // Telecom
    case internet
    case cable
    case landline
    case phonePlan = "phone_plan"

    // Insurance (Moderate)
    case rentersInsurance = "renters_insurance"
    case petInsurance = "pet_insurance"

    // Pet Care
    case petGrooming = "pet_grooming"
    case petBoarding = "pet_boarding"

    // Home Services
    case securitySystem = "security_system"
    case pestControl = "pest_control"
    case lawnCare = "lawn_care"
    case houseCleaning = "house_cleaning"

    // Storage
    case selfStorage = "self_storage"

    // Memberships
    case clubDues = "club_dues"
    case professionalMembership = "professional_membership"

    // MARK: Tier 3 - Guardian Bills ($150-500)

    // Transportation
    case carInsurance = "car_insurance"
    case carPayment = "car_payment"
    case transitPass = "transit_pass"

    // Housing
    case rent
    case mortgage
    case hoaFees = "hoa_fees"
    case homeInsurance = "home_insurance"

    // Health & Medical
    case healthInsurance = "health_insurance"
    case dentalInsurance = "dental_insurance"
    case visionInsurance = "vision_insurance"
    case lifeInsurance = "life_insurance"
    case medical

    // Education
    case studentLoan = "student_loan"
    case tuition
    case daycare

    // Financial
    case creditCard = "credit_card"
    case personalLoan = "personal_loan"

    // Other
    case childSupport = "child_support"
    case coworkingSpace = "coworking_space"

    var id: String { rawValue }

    var tier: ReputationTier {
        switch self {
        // Tier 1 - Neighbor: Streaming & Subscriptions (up to $25)
        case .netflix, .spotify, .disneyPlus, .hulu, .hboMax, .primeVideo, .peacock,
             .paramountPlus, .appleTvPlus, .youtubeMusic, .appleMusic, .tidal,
             .xboxGamePass, .playstationPlus, .nintendoOnline,
             .gym, .fitnessApp, .cloudStorage, .softwareSubscription,
             .mealKit, .groceryDelivery:
            return .neighbor

        // Tier 2 - Contributor: Utilities (up to $150)
        case .electric, .naturalGas, .water, .sewer, .trash, .heatingOil, .propane,
             .internet, .cable, .landline, .phonePlan,
             .rentersInsurance, .petInsurance, .petGrooming, .petBoarding,
             .securitySystem, .pestControl, .lawnCare, .houseCleaning,
             .selfStorage, .clubDues, .professionalMembership:
            return .contributor

        // Tier 3 - Pillar: Major bills (up to $500)
        case .carInsurance, .carPayment, .transitPass,
             .rent, .mortgage, .hoaFees, .homeInsurance,
             .healthInsurance, .dentalInsurance, .visionInsurance, .lifeInsurance, .medical,
             .studentLoan, .tuition, .daycare,
             .creditCard, .personalLoan, .childSupport, .coworkingSpace:
            return .pillar
        }
    }

    var displayName: String {
        switch self {
        // Streaming
        case .netflix: return "Netflix"
        case .spotify: return "Spotify"
        case .disneyPlus: return "Disney+"
        case .hulu: return "Hulu"
        case .hboMax: return "HBO Max"
        case .primeVideo: return "Prime Video"
        case .peacock: return "Peacock"
        case .paramountPlus: return "Paramount+"
        case .appleTvPlus: return "Apple TV+"
        case .youtubeMusic: return "YouTube Music"
        case .appleMusic: return "Apple Music"
        case .tidal: return "Tidal"

        // Gaming
        case .xboxGamePass: return "Xbox Game Pass"
        case .playstationPlus: return "PlayStation Plus"
        case .nintendoOnline: return "Nintendo Online"

        // Fitness
        case .gym: return "Gym"
        case .fitnessApp: return "Fitness App"

        // Cloud & Software
        case .cloudStorage: return "Cloud Storage"
        case .softwareSubscription: return "Software"

        // Meal & Delivery
        case .mealKit: return "Meal Kit"
        case .groceryDelivery: return "Grocery Delivery"

        // Utilities
        case .electric: return "Electric"
        case .naturalGas: return "Natural Gas"
        case .water: return "Water"
        case .sewer: return "Sewer"
        case .trash: return "Trash"
        case .heatingOil: return "Heating Oil"
        case .propane: return "Propane"

        // Telecom
        case .internet: return "Internet"
        case .cable: return "Cable TV"
        case .landline: return "Landline"
        case .phonePlan: return "Phone Plan"

        // Insurance (Moderate)
        case .rentersInsurance: return "Renters Insurance"
        case .petInsurance: return "Pet Insurance"

        // Pet Care
        case .petGrooming: return "Pet Grooming"
        case .petBoarding: return "Pet Boarding"

        // Home Services
        case .securitySystem: return "Security System"
        case .pestControl: return "Pest Control"
        case .lawnCare: return "Lawn Care"
        case .houseCleaning: return "House Cleaning"

        // Storage
        case .selfStorage: return "Self Storage"

        // Memberships
        case .clubDues: return "Club Dues"
        case .professionalMembership: return "Professional Membership"

        // Transportation
        case .carInsurance: return "Car Insurance"
        case .carPayment: return "Car Payment"
        case .transitPass: return "Transit Pass"

        // Housing
        case .rent: return "Rent"
        case .mortgage: return "Mortgage"
        case .hoaFees: return "HOA Fees"
        case .homeInsurance: return "Home Insurance"

        // Health
        case .healthInsurance: return "Health Insurance"
        case .dentalInsurance: return "Dental Insurance"
        case .visionInsurance: return "Vision Insurance"
        case .lifeInsurance: return "Life Insurance"
        case .medical: return "Medical"

        // Education
        case .studentLoan: return "Student Loan"
        case .tuition: return "Tuition"
        case .daycare: return "Daycare"

        // Financial
        case .creditCard: return "Credit Card"
        case .personalLoan: return "Personal Loan"

        // Other
        case .childSupport: return "Child Support"
        case .coworkingSpace: return "Coworking Space"
        }
    }

    var icon: String {
        switch self {
        // Streaming
        case .netflix, .hulu, .hboMax, .primeVideo, .peacock, .paramountPlus, .appleTvPlus:
            return "tv.fill"
        case .disneyPlus: return "sparkles.tv.fill"
        case .spotify, .youtubeMusic, .appleMusic, .tidal:
            return "music.note"

        // Gaming
        case .xboxGamePass, .playstationPlus, .nintendoOnline:
            return "gamecontroller.fill"

        // Fitness
        case .gym: return "figure.strengthtraining.traditional"
        case .fitnessApp: return "figure.run"

        // Cloud & Software
        case .cloudStorage: return "cloud.fill"
        case .softwareSubscription: return "app.fill"

        // Meal & Delivery
        case .mealKit: return "fork.knife"
        case .groceryDelivery: return "cart.fill"

        // Utilities
        case .electric: return "bolt.fill"
        case .naturalGas: return "flame.fill"
        case .water: return "drop.fill"
        case .sewer: return "arrow.down.to.line"
        case .trash: return "trash.fill"
        case .heatingOil: return "thermometer.sun.fill"
        case .propane: return "flame"

        // Telecom
        case .internet: return "wifi"
        case .cable: return "antenna.radiowaves.left.and.right"
        case .landline: return "phone.fill"
        case .phonePlan: return "iphone"

        // Insurance
        case .rentersInsurance: return "house.lodge.fill"
        case .petInsurance: return "pawprint.fill"

        // Pet Care
        case .petGrooming: return "scissors"
        case .petBoarding: return "bed.double.fill"

        // Home Services
        case .securitySystem: return "shield.fill"
        case .pestControl: return "ant.fill"
        case .lawnCare: return "leaf.fill"
        case .houseCleaning: return "sparkles"

        // Storage
        case .selfStorage: return "shippingbox.fill"

        // Memberships
        case .clubDues: return "person.3.fill"
        case .professionalMembership: return "briefcase.fill"

        // Transportation
        case .carInsurance: return "car.fill"
        case .carPayment: return "car.circle.fill"
        case .transitPass: return "bus.fill"

        // Housing
        case .rent: return "house.fill"
        case .mortgage: return "building.2.fill"
        case .hoaFees: return "building.columns.fill"
        case .homeInsurance: return "house.lodge.fill"

        // Health
        case .healthInsurance: return "heart.fill"
        case .dentalInsurance: return "mouth.fill"
        case .visionInsurance: return "eye.fill"
        case .lifeInsurance: return "person.fill.checkmark"
        case .medical: return "cross.case.fill"

        // Education
        case .studentLoan: return "graduationcap.fill"
        case .tuition: return "book.fill"
        case .daycare: return "figure.and.child.holdinghands"

        // Financial
        case .creditCard: return "creditcard.fill"
        case .personalLoan: return "dollarsign.circle.fill"

        // Other
        case .childSupport: return "figure.2.and.child.holdinghands"
        case .coworkingSpace: return "desktopcomputer"
        }
    }

    var color: Color {
        switch self {
        // Streaming - Brand colors
        case .netflix: return .red
        case .spotify: return Color(hex: "#1DB954")
        case .disneyPlus: return Color(hex: "#113CCF")
        case .hulu: return Color(hex: "#1CE783")
        case .hboMax: return Color(hex: "#B431E2")
        case .primeVideo: return Color(hex: "#00A8E1")
        case .peacock: return Color(hex: "#000000")
        case .paramountPlus: return Color(hex: "#0064FF")
        case .appleTvPlus: return .gray
        case .youtubeMusic: return .red
        case .appleMusic: return Color(hex: "#FC3C44")
        case .tidal: return .black

        // Gaming
        case .xboxGamePass: return Color(hex: "#107C10")
        case .playstationPlus: return Color(hex: "#003791")
        case .nintendoOnline: return Color(hex: "#E60012")

        // Fitness
        case .gym, .fitnessApp: return .orange

        // Cloud & Software
        case .cloudStorage: return .blue
        case .softwareSubscription: return .purple

        // Meal & Delivery
        case .mealKit, .groceryDelivery: return Color(hex: "#FF6B35")

        // Utilities
        case .electric: return .yellow
        case .naturalGas: return .orange
        case .water: return .cyan
        case .sewer: return Color(hex: "#6B7280")
        case .trash: return Color(hex: "#374151")
        case .heatingOil: return Color(hex: "#DC2626")
        case .propane: return Color(hex: "#F97316")

        // Telecom
        case .internet: return .purple
        case .cable: return .indigo
        case .landline: return .gray
        case .phonePlan: return .blue

        // Insurance
        case .rentersInsurance, .petInsurance: return Color(hex: "#3B82F6")

        // Pet Care
        case .petGrooming, .petBoarding: return Color(hex: "#A855F7")

        // Home Services
        case .securitySystem: return Color(hex: "#1F2937")
        case .pestControl: return Color(hex: "#84CC16")
        case .lawnCare: return Color(hex: "#22C55E")
        case .houseCleaning: return Color(hex: "#06B6D4")

        // Storage
        case .selfStorage: return Color(hex: "#F59E0B")

        // Memberships
        case .clubDues: return Color(hex: "#8B5CF6")
        case .professionalMembership: return Color(hex: "#6366F1")

        // Transportation
        case .carInsurance, .carPayment: return Color(hex: "#3B82F6")
        case .transitPass: return Color(hex: "#10B981")

        // Housing
        case .rent, .mortgage: return Color(hex: "#059669")
        case .hoaFees: return Color(hex: "#0891B2")
        case .homeInsurance: return Color(hex: "#0D9488")

        // Health
        case .healthInsurance: return Color(hex: "#EF4444")
        case .dentalInsurance: return Color(hex: "#F472B6")
        case .visionInsurance: return Color(hex: "#8B5CF6")
        case .lifeInsurance: return Color(hex: "#6366F1")
        case .medical: return .red

        // Education
        case .studentLoan, .tuition: return Color(hex: "#7C3AED")
        case .daycare: return Color(hex: "#EC4899")

        // Financial
        case .creditCard: return Color(hex: "#F59E0B")
        case .personalLoan: return Color(hex: "#10B981")

        // Other
        case .childSupport: return Color(hex: "#6366F1")
        case .coworkingSpace: return Color(hex: "#8B5CF6")
        }
    }

    var typicalAmountRange: ClosedRange<Double> {
        switch self {
        // Tier 1 - Streaming & Subscriptions
        case .netflix: return 6.99...22.99
        case .spotify: return 9.99...15.99
        case .disneyPlus: return 7.99...13.99
        case .hulu: return 7.99...17.99
        case .hboMax: return 9.99...15.99
        case .primeVideo: return 8.99...14.99
        case .peacock: return 5.99...11.99
        case .paramountPlus: return 5.99...11.99
        case .appleTvPlus: return 6.99...9.99
        case .youtubeMusic: return 9.99...14.99
        case .appleMusic: return 9.99...16.99
        case .tidal: return 9.99...19.99
        case .xboxGamePass: return 9.99...16.99
        case .playstationPlus: return 9.99...17.99
        case .nintendoOnline: return 3.99...7.99
        case .gym: return 10.00...50.00
        case .fitnessApp: return 9.99...29.99
        case .cloudStorage: return 0.99...14.99
        case .softwareSubscription: return 5.99...24.99
        case .mealKit: return 40.00...100.00
        case .groceryDelivery: return 9.99...14.99

        // Tier 2 - Utilities
        case .electric: return 50.00...200.00
        case .naturalGas: return 30.00...150.00
        case .water: return 30.00...100.00
        case .sewer: return 20.00...80.00
        case .trash: return 20.00...60.00
        case .heatingOil: return 100.00...300.00
        case .propane: return 50.00...200.00
        case .internet: return 50.00...150.00
        case .cable: return 50.00...150.00
        case .landline: return 20.00...50.00
        case .phonePlan: return 50.00...150.00
        case .rentersInsurance: return 15.00...50.00
        case .petInsurance: return 25.00...75.00
        case .petGrooming: return 30.00...100.00
        case .petBoarding: return 25.00...75.00
        case .securitySystem: return 30.00...60.00
        case .pestControl: return 30.00...75.00
        case .lawnCare: return 50.00...150.00
        case .houseCleaning: return 75.00...200.00
        case .selfStorage: return 50.00...200.00
        case .clubDues: return 25.00...100.00
        case .professionalMembership: return 25.00...150.00

        // Tier 3 - Guardian
        case .carInsurance: return 100.00...300.00
        case .carPayment: return 200.00...600.00
        case .transitPass: return 50.00...150.00
        case .rent: return 500.00...2500.00
        case .mortgage: return 800.00...3000.00
        case .hoaFees: return 100.00...500.00
        case .homeInsurance: return 75.00...250.00
        case .healthInsurance: return 200.00...800.00
        case .dentalInsurance: return 25.00...75.00
        case .visionInsurance: return 10.00...30.00
        case .lifeInsurance: return 25.00...150.00
        case .medical: return 50.00...500.00
        case .studentLoan: return 100.00...500.00
        case .tuition: return 500.00...2000.00
        case .daycare: return 800.00...2500.00
        case .creditCard: return 50.00...500.00
        case .personalLoan: return 100.00...500.00
        case .childSupport: return 200.00...1000.00
        case .coworkingSpace: return 100.00...500.00
        }
    }

    // MARK: - Category Lists by Tier

    /// Neighbor tier categories (up to $25)
    static var neighborCategories: [SwapBillCategory] {
        [.netflix, .spotify, .disneyPlus, .hulu, .hboMax, .primeVideo, .peacock,
         .paramountPlus, .appleTvPlus, .youtubeMusic, .appleMusic, .tidal,
         .xboxGamePass, .playstationPlus, .nintendoOnline,
         .gym, .fitnessApp, .cloudStorage, .softwareSubscription,
         .mealKit, .groceryDelivery]
    }

    /// Contributor tier categories (up to $150)
    static var contributorCategories: [SwapBillCategory] {
        [.electric, .naturalGas, .water, .sewer, .trash, .heatingOil, .propane,
         .internet, .cable, .landline, .phonePlan,
         .rentersInsurance, .petInsurance, .petGrooming, .petBoarding,
         .securitySystem, .pestControl, .lawnCare, .houseCleaning,
         .selfStorage, .clubDues, .professionalMembership]
    }

    /// Pillar tier categories (up to $500)
    static var pillarCategories: [SwapBillCategory] {
        [.carInsurance, .carPayment, .transitPass,
         .rent, .mortgage, .hoaFees, .homeInsurance,
         .healthInsurance, .dentalInsurance, .visionInsurance, .lifeInsurance, .medical,
         .studentLoan, .tuition, .daycare,
         .creditCard, .personalLoan, .childSupport, .coworkingSpace]
    }

    // Legacy compatibility aliases
    static var streamerCategories: [SwapBillCategory] { neighborCategories }
    static var utilityCategories: [SwapBillCategory] { contributorCategories }
    static var guardianCategories: [SwapBillCategory] { pillarCategories }

    static func categories(for tier: ReputationTier) -> [SwapBillCategory] {
        switch tier {
        case .neighbor: return neighborCategories
        case .contributor: return contributorCategories
        case .pillar: return pillarCategories
        }
    }

    static func availableCategories(upToTier tier: ReputationTier) -> [SwapBillCategory] {
        var categories: [SwapBillCategory] = []
        for t in ReputationTier.allCases where t.rawValue <= tier.rawValue {
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
