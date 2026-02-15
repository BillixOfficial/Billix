//
//  BillCoachModels.swift
//  Billix
//
//  The Golden Rule: User experiences ONE interaction type at a time.
//  Progressive flow through 6 stages builds trust and knowledge.
//

import Foundation
import SwiftUI

// MARK: - Coaching Topic

enum CoachingTopic: String, CaseIterable, Identifiable {
    case negotiateInternet = "negotiate_internet"
    case cancelGym = "cancel_gym"
    case lowerInsurance = "lower_insurance"
    case reduceElectric = "reduce_electric"
    case cutStreaming = "cut_streaming"
    case refinanceAuto = "refinance_auto"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .negotiateInternet: return "Negotiate Internet"
        case .cancelGym: return "Cancel Gym"
        case .lowerInsurance: return "Lower Insurance"
        case .reduceElectric: return "Reduce Electric"
        case .cutStreaming: return "Cut Streaming"
        case .refinanceAuto: return "Refinance Auto"
        }
    }

    var icon: String {
        switch self {
        case .negotiateInternet: return "wifi"
        case .cancelGym: return "dumbbell.fill"
        case .lowerInsurance: return "car.fill"
        case .reduceElectric: return "bolt.fill"
        case .cutStreaming: return "play.tv.fill"
        case .refinanceAuto: return "car.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .negotiateInternet: return Color(hex: "#5BA4D4")
        case .cancelGym: return Color(hex: "#E07A6B")
        case .lowerInsurance: return Color(hex: "#9B7EB8")
        case .reduceElectric: return Color(hex: "#E8A54B")
        case .cutStreaming: return Color(hex: "#4CAF7A")
        case .refinanceAuto: return Color(hex: "#5B8A6B")
        }
    }

    var estimatedDuration: String {
        switch self {
        case .negotiateInternet: return "15 min"
        case .cancelGym: return "10 min"
        case .lowerInsurance: return "20 min"
        case .reduceElectric: return "5 min"
        case .cutStreaming: return "8 min"
        case .refinanceAuto: return "25 min"
        }
    }

    var savingsPotential: String {
        switch self {
        case .negotiateInternet: return "High savings potential"
        case .cancelGym: return "Significant savings possible"
        case .lowerInsurance: return "Good savings potential"
        case .reduceElectric: return "Moderate savings possible"
        case .cutStreaming: return "Good savings potential"
        case .refinanceAuto: return "High savings potential"
        }
    }
}

// MARK: - Coaching Flow Step

/// The 3 progressive interaction types - user sees ONE at a time
/// Simplified flow: Walkthrough → Savings Slider → Community Insight
enum CoachingStep: Int, CaseIterable {
    case billWalkthrough = 1    // Entry point - contextual, lowers anxiety
    case whatIfSlider = 2       // Immediate proof - skepticism killer
    case communityComparison = 3 // Passive reinforcement

    var description: String {
        switch self {
        case .billWalkthrough: return "Interactive Bill Walkthrough"
        case .whatIfSlider: return "What-If Sliders"
        case .communityComparison: return "Community Insight"
        }
    }

    /// What psychological need this step solves
    var solves: String {
        switch self {
        case .billWalkthrough: return "Fear & confusion"
        case .whatIfSlider: return "Skepticism"
        case .communityComparison: return "Isolation"
        }
    }
}

// MARK: - Bill Line Item (for walkthrough)

struct BillLineItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isHighlighted: Bool
    let savingsTip: String?

    static let sampleInternetBill: [BillLineItem] = [
        BillLineItem(
            name: "Internet Service",
            description: "Your current speed plan",
            isHighlighted: true,
            savingsTip: "Most households don't need the fastest speeds. Consider if a lower tier meets your needs."
        ),
        BillLineItem(
            name: "Equipment Rental",
            description: "Router/Modem Combo",
            isHighlighted: true,
            savingsTip: "Buying your own modem can eliminate this recurring charge entirely."
        ),
        BillLineItem(
            name: "Taxes & Fees",
            description: "Regulatory charges",
            isHighlighted: false,
            savingsTip: nil
        )
    ]

    static let sampleGymBill: [BillLineItem] = [
        BillLineItem(
            name: "Monthly Membership",
            description: "Premium Access",
            isHighlighted: true,
            savingsTip: "If you go less than twice a week, a pay-per-visit option may save you money."
        ),
        BillLineItem(
            name: "Annual Enhancement Fee",
            description: "Hidden annual charge",
            isHighlighted: true,
            savingsTip: "This hidden fee is often negotiable. Ask to waive it when renewing."
        )
    ]

    static let sampleInsuranceBill: [BillLineItem] = [
        BillLineItem(
            name: "Liability Coverage",
            description: "Required coverage",
            isHighlighted: false,
            savingsTip: nil
        ),
        BillLineItem(
            name: "Collision Coverage",
            description: "Current deductible",
            isHighlighted: true,
            savingsTip: "Raising your deductible can lower your premium. Consider what you can afford out-of-pocket."
        ),
        BillLineItem(
            name: "Comprehensive",
            description: "Current deductible",
            isHighlighted: true,
            savingsTip: "Bundling with home or renters insurance often unlocks discounts."
        )
    ]
}

// MARK: - Usage Assessment (conceptual choices)

struct UsageAssessment: Identifiable {
    let id = UUID()
    let title: String
    let question: String
    let options: [UsageOption]

    static let sampleInternetAssessment = UsageAssessment(
        title: "Internet Usage",
        question: "How would you describe your household's internet use?",
        options: [
            UsageOption(
                label: "Light",
                description: "Email, browsing, and occasional streaming",
                icon: "leaf.fill",
                feedback: "You likely don't need the fastest speeds. A basic plan may work perfectly."
            ),
            UsageOption(
                label: "Moderate",
                description: "Regular streaming, video calls, multiple devices",
                icon: "person.2.fill",
                feedback: "A mid-tier plan usually covers this well. No need for premium speeds."
            ),
            UsageOption(
                label: "Heavy",
                description: "Gaming, 4K streaming, work from home, many devices",
                icon: "bolt.fill",
                feedback: "Higher speeds make sense for you, but shop around for competitive rates."
            )
        ]
    )

    static let sampleGymAssessment = UsageAssessment(
        title: "Gym Usage",
        question: "How often do you actually visit the gym?",
        options: [
            UsageOption(
                label: "Rarely",
                description: "A few times a month or less",
                icon: "figure.walk",
                feedback: "A membership may not be worth it. Consider pay-per-visit or free alternatives."
            ),
            UsageOption(
                label: "Sometimes",
                description: "Once or twice a week",
                icon: "figure.run",
                feedback: "You might save with a basic membership or class packs."
            ),
            UsageOption(
                label: "Frequently",
                description: "Three or more times a week",
                icon: "dumbbell.fill",
                feedback: "A membership likely makes sense, but compare gym options in your area."
            )
        ]
    )

    static let sampleInsuranceAssessment = UsageAssessment(
        title: "Driving Habits",
        question: "How would you describe your driving?",
        options: [
            UsageOption(
                label: "Low Mileage",
                description: "Work from home, minimal driving",
                icon: "house.fill",
                feedback: "You may qualify for low-mileage discounts. Ask your insurer."
            ),
            UsageOption(
                label: "Average",
                description: "Regular commute, typical errands",
                icon: "car.fill",
                feedback: "Compare rates—you may find better deals without changing coverage."
            ),
            UsageOption(
                label: "High Mileage",
                description: "Long commute, frequent road trips",
                icon: "road.lanes",
                feedback: "Focus on finding the best rate for your coverage needs."
            )
        ]
    )
}

struct UsageOption: Identifiable {
    let id = UUID()
    let label: String
    let description: String
    let icon: String
    let feedback: String
}


// MARK: - Community Insight

struct CommunityInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String

    static let sampleInternetInsights: [CommunityInsight] = [
        CommunityInsight(
            title: "Negotiation works",
            description: "Most Billix users who called their provider were able to negotiate a better rate.",
            icon: "phone.fill"
        ),
        CommunityInsight(
            title: "Own your equipment",
            description: "Many users save by buying their own router instead of renting.",
            icon: "wifi.router.fill"
        )
    ]

    static let sampleGymInsights: [CommunityInsight] = [
        CommunityInsight(
            title: "Cancellation is possible",
            description: "Most users who followed the proper steps cancelled without extra fees.",
            icon: "checkmark.circle.fill"
        )
    ]

    static let sampleInsuranceInsights: [CommunityInsight] = [
        CommunityInsight(
            title: "Shopping around pays off",
            description: "The majority of users who compared quotes found a better rate.",
            icon: "magnifyingglass"
        )
    ]
}

// MARK: - User Coaching Progress

struct UserCoachingProgress: Identifiable {
    let id = UUID()
    let topic: CoachingTopic
    var currentStep: CoachingStep
    var completedSteps: Set<CoachingStep>

    var isComplete: Bool {
        completedSteps.count == CoachingStep.allCases.count
    }

    mutating func advanceToNextStep() {
        completedSteps.insert(currentStep)
        if let nextStep = CoachingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }
}

// MARK: - Coaching Session State

class CoachingSession: ObservableObject {
    @Published var topic: CoachingTopic
    @Published var currentStep: CoachingStep = .billWalkthrough
    @Published var completedSteps: Set<CoachingStep> = []
    @Published var selectedLineItemIndex: Int = 0
    @Published var selectedUsageOption: UsageOption?

    // Content based on topic
    var billLineItems: [BillLineItem] {
        switch topic {
        case .negotiateInternet: return BillLineItem.sampleInternetBill
        case .cancelGym: return BillLineItem.sampleGymBill
        case .lowerInsurance: return BillLineItem.sampleInsuranceBill
        default: return BillLineItem.sampleInternetBill
        }
    }

    var usageAssessment: UsageAssessment {
        switch topic {
        case .negotiateInternet: return UsageAssessment.sampleInternetAssessment
        case .cancelGym: return UsageAssessment.sampleGymAssessment
        case .lowerInsurance: return UsageAssessment.sampleInsuranceAssessment
        default: return UsageAssessment.sampleInternetAssessment
        }
    }

    var communityInsights: [CommunityInsight] {
        switch topic {
        case .negotiateInternet: return CommunityInsight.sampleInternetInsights
        case .cancelGym: return CommunityInsight.sampleGymInsights
        case .lowerInsurance: return CommunityInsight.sampleInsuranceInsights
        default: return CommunityInsight.sampleInternetInsights
        }
    }

    init(topic: CoachingTopic) {
        self.topic = topic
    }

    func advanceStep() {
        completedSteps.insert(currentStep)

        if let nextStep = CoachingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }

    func canAdvance() -> Bool {
        switch currentStep {
        case .billWalkthrough:
            return true // Can always advance from walkthrough after viewing
        case .whatIfSlider:
            return selectedUsageOption != nil
        case .communityComparison:
            return true
        }
    }
}
