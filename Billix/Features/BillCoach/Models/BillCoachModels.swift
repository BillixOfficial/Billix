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

    var potentialSavings: String {
        switch self {
        case .negotiateInternet: return "$15-30/mo"
        case .cancelGym: return "$30-60/mo"
        case .lowerInsurance: return "$20-50/mo"
        case .reduceElectric: return "$10-25/mo"
        case .cutStreaming: return "$20-40/mo"
        case .refinanceAuto: return "$50-100/mo"
        }
    }
}

// MARK: - Coaching Flow Step

/// The 6 progressive interaction types - user sees ONE at a time
enum CoachingStep: Int, CaseIterable {
    case billWalkthrough = 1    // Entry point - contextual, lowers anxiety
    case whatIfSlider = 2       // Immediate proof - skepticism killer
    case decisionQuiz = 3       // Micro-validation - confidence checkpoint
    case coachMission = 4       // Convert learning to action
    case confidenceScore = 5    // Progress without pressure (ambient)
    case communityComparison = 6 // Passive reinforcement

    var description: String {
        switch self {
        case .billWalkthrough: return "Interactive Bill Walkthrough"
        case .whatIfSlider: return "What-If Sliders"
        case .decisionQuiz: return "Quick Check"
        case .coachMission: return "Your Mission"
        case .confidenceScore: return "Confidence Building"
        case .communityComparison: return "Community Insight"
        }
    }

    /// What psychological need this step solves
    var solves: String {
        switch self {
        case .billWalkthrough: return "Fear & confusion"
        case .whatIfSlider: return "Skepticism"
        case .decisionQuiz: return "Self-doubt"
        case .coachMission: return "Inaction"
        case .confidenceScore: return "Anxiety"
        case .communityComparison: return "Isolation"
        }
    }
}

// MARK: - Bill Line Item (for walkthrough)

struct BillLineItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let description: String
    let isHighlighted: Bool
    let savingsTip: String?
    let potentialSavings: Double?

    static let sampleInternetBill: [BillLineItem] = [
        BillLineItem(
            name: "Internet Service",
            amount: 79.99,
            description: "1 Gig Speed Plan",
            isHighlighted: true,
            savingsTip: "Most households only need 300Mbps. You could save $20/mo by downgrading.",
            potentialSavings: 20.0
        ),
        BillLineItem(
            name: "Equipment Rental",
            amount: 14.00,
            description: "Router/Modem Combo",
            isHighlighted: true,
            savingsTip: "Buy your own modem for $80 - pays for itself in 6 months!",
            potentialSavings: 14.0
        ),
        BillLineItem(
            name: "Taxes & Fees",
            amount: 8.50,
            description: "Regulatory charges",
            isHighlighted: false,
            savingsTip: nil,
            potentialSavings: nil
        )
    ]

    static let sampleGymBill: [BillLineItem] = [
        BillLineItem(
            name: "Monthly Membership",
            amount: 49.99,
            description: "Premium Access",
            isHighlighted: true,
            savingsTip: "If you go less than 2x/week, a pay-per-visit option saves money.",
            potentialSavings: 30.0
        ),
        BillLineItem(
            name: "Annual Enhancement Fee",
            amount: 4.17,
            description: "$50 divided monthly",
            isHighlighted: true,
            savingsTip: "This hidden fee is negotiable. Ask to waive it when renewing.",
            potentialSavings: 4.17
        )
    ]

    static let sampleInsuranceBill: [BillLineItem] = [
        BillLineItem(
            name: "Liability Coverage",
            amount: 65.00,
            description: "100/300/100 limits",
            isHighlighted: false,
            savingsTip: nil,
            potentialSavings: nil
        ),
        BillLineItem(
            name: "Collision Coverage",
            amount: 45.00,
            description: "$500 deductible",
            isHighlighted: true,
            savingsTip: "Raising your deductible to $1000 could save $15/mo.",
            potentialSavings: 15.0
        ),
        BillLineItem(
            name: "Comprehensive",
            amount: 22.00,
            description: "$500 deductible",
            isHighlighted: true,
            savingsTip: "Bundle with home insurance for 10-15% off.",
            potentialSavings: 8.0
        )
    ]
}

// MARK: - What-If Scenario

struct WhatIfScenario: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let minValue: Double
    let maxValue: Double
    let currentValue: Double
    let suggestedValue: Double
    let unit: String
    let savingsPerUnit: Double

    var maxSavings: Double {
        (currentValue - minValue) * savingsPerUnit
    }

    static let sampleInternetScenarios: [WhatIfScenario] = [
        WhatIfScenario(
            title: "Internet Speed",
            description: "What speed do you actually need?",
            minValue: 100,
            maxValue: 1000,
            currentValue: 1000,
            suggestedValue: 300,
            unit: "Mbps",
            savingsPerUnit: 0.03
        ),
        WhatIfScenario(
            title: "Equipment",
            description: "Own vs Rent your router",
            minValue: 0,
            maxValue: 14,
            currentValue: 14,
            suggestedValue: 0,
            unit: "$/mo",
            savingsPerUnit: 1.0
        )
    ]
}

// MARK: - Quiz Question

struct CoachQuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let encouragement: String

    static let sampleInternetQuestions: [CoachQuizQuestion] = [
        CoachQuizQuestion(
            question: "What internet speed does Netflix recommend for 4K streaming?",
            options: ["25 Mbps", "100 Mbps", "500 Mbps", "1000 Mbps"],
            correctIndex: 0,
            explanation: "Netflix only needs 25 Mbps for 4K! Most plans are overkill.",
            encouragement: "You're learning what the providers don't want you to know!"
        ),
        CoachQuizQuestion(
            question: "What's the #1 negotiation tactic that works?",
            options: ["Threaten to cancel", "Ask for loyalty discount", "Mention competitor pricing", "Request a supervisor"],
            correctIndex: 2,
            explanation: "Mentioning competitor pricing works 73% of the time. It gives them a concrete reason to match.",
            encouragement: "You now have leverage in your next call!"
        )
    ]

    static let sampleGymQuestions: [CoachQuizQuestion] = [
        CoachQuizQuestion(
            question: "When is the best time to cancel a gym membership?",
            options: ["January", "End of contract", "After 30 days notice", "Any time"],
            correctIndex: 1,
            explanation: "Most contracts auto-renew. Cancel right before renewal to avoid fees.",
            encouragement: "Timing is everything - you've got this!"
        )
    ]

    static let sampleInsuranceQuestions: [CoachQuizQuestion] = [
        CoachQuizQuestion(
            question: "What typically lowers your car insurance premium the most?",
            options: ["Higher deductible", "Bundling policies", "Good driver discount", "All of the above"],
            correctIndex: 3,
            explanation: "Combining all three can save you 20-40% on your premium!",
            encouragement: "You're building real financial knowledge!"
        )
    ]
}

// MARK: - Coach Mission

struct CoachMission: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let actionVerb: String
    let estimatedTime: String
    let pointsReward: Int
    let steps: [String]
    let scriptTemplate: String?

    static let sampleInternetMission = CoachMission(
        title: "Call Your Provider",
        description: "Based on your bill, here's your personalized negotiation plan.",
        actionVerb: "Negotiate",
        estimatedTime: "15 min",
        pointsReward: 100,
        steps: [
            "Call the number on your bill",
            "Say: 'I'd like to discuss lowering my bill'",
            "Mention the competitor offer you found",
            "Ask for a loyalty discount",
            "If needed, ask for retention department"
        ],
        scriptTemplate: "Hi, I've been a customer for [X years] and I noticed [competitor] is offering similar service for $[amount]. I'd like to stay but need help with my bill."
    )

    static let sampleGymMission = CoachMission(
        title: "Send Cancellation Request",
        description: "Here's exactly how to cancel without the runaround.",
        actionVerb: "Cancel",
        estimatedTime: "10 min",
        pointsReward: 75,
        steps: [
            "Check your contract end date",
            "Send written cancellation (email or certified mail)",
            "Keep confirmation for your records",
            "Monitor for unauthorized charges"
        ],
        scriptTemplate: "I am writing to cancel my membership effective [date]. Please confirm cancellation and that no further charges will be made to my account."
    )

    static let sampleInsuranceMission = CoachMission(
        title: "Get 3 Competing Quotes",
        description: "The best way to lower insurance is to shop around.",
        actionVerb: "Compare",
        estimatedTime: "20 min",
        pointsReward: 150,
        steps: [
            "Gather your current policy details",
            "Get quotes from 3 different providers",
            "Compare coverage AND price",
            "Call current provider with best quote"
        ],
        scriptTemplate: nil
    )
}

// MARK: - Community Insight

struct CommunityInsight: Identifiable {
    let id = UUID()
    let text: String
    let percentage: Int
    let context: String

    static let sampleInternetInsights: [CommunityInsight] = [
        CommunityInsight(
            text: "negotiated their internet bill successfully",
            percentage: 68,
            context: "in your area"
        ),
        CommunityInsight(
            text: "saved by buying their own router",
            percentage: 82,
            context: "Billix users"
        )
    ]

    static let sampleGymInsights: [CommunityInsight] = [
        CommunityInsight(
            text: "cancelled without paying a fee",
            percentage: 71,
            context: "who followed these steps"
        )
    ]

    static let sampleInsuranceInsights: [CommunityInsight] = [
        CommunityInsight(
            text: "found a better rate by shopping around",
            percentage: 89,
            context: "in the last 3 months"
        )
    ]
}

// MARK: - User Coaching Progress

struct UserCoachingProgress: Identifiable {
    let id = UUID()
    let topic: CoachingTopic
    var currentStep: CoachingStep
    var confidenceScore: Double // 0-100, ambient
    var completedSteps: Set<CoachingStep>
    var quizScore: Int?
    var missionCompleted: Bool
    var savedAmount: Double?

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
    @Published var confidenceScore: Double = 0
    @Published var completedSteps: Set<CoachingStep> = []
    @Published var selectedLineItemIndex: Int = 0
    @Published var sliderValues: [UUID: Double] = [:]
    @Published var quizAnswers: [UUID: Int] = [:]
    @Published var missionStarted: Bool = false
    @Published var missionCompleted: Bool = false

    // Content based on topic
    var billLineItems: [BillLineItem] {
        switch topic {
        case .negotiateInternet: return BillLineItem.sampleInternetBill
        case .cancelGym: return BillLineItem.sampleGymBill
        case .lowerInsurance: return BillLineItem.sampleInsuranceBill
        default: return BillLineItem.sampleInternetBill
        }
    }

    var whatIfScenarios: [WhatIfScenario] {
        switch topic {
        case .negotiateInternet: return WhatIfScenario.sampleInternetScenarios
        default: return WhatIfScenario.sampleInternetScenarios
        }
    }

    var quizQuestions: [CoachQuizQuestion] {
        switch topic {
        case .negotiateInternet: return CoachQuizQuestion.sampleInternetQuestions
        case .cancelGym: return CoachQuizQuestion.sampleGymQuestions
        case .lowerInsurance: return CoachQuizQuestion.sampleInsuranceQuestions
        default: return CoachQuizQuestion.sampleInternetQuestions
        }
    }

    var mission: CoachMission {
        switch topic {
        case .negotiateInternet: return CoachMission.sampleInternetMission
        case .cancelGym: return CoachMission.sampleGymMission
        case .lowerInsurance: return CoachMission.sampleInsuranceMission
        default: return CoachMission.sampleInternetMission
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

    var totalBillAmount: Double {
        billLineItems.reduce(0) { $0 + $1.amount }
    }

    var totalPotentialSavings: Double {
        billLineItems.compactMap { $0.potentialSavings }.reduce(0, +)
    }

    init(topic: CoachingTopic) {
        self.topic = topic
    }

    func advanceStep() {
        completedSteps.insert(currentStep)
        // Ambient confidence building
        confidenceScore = min(100, confidenceScore + 15)

        if let nextStep = CoachingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }

    func canAdvance() -> Bool {
        switch currentStep {
        case .billWalkthrough:
            return true // Can always advance from walkthrough after viewing
        case .whatIfSlider:
            return !sliderValues.isEmpty
        case .decisionQuiz:
            return !quizAnswers.isEmpty
        case .coachMission:
            return missionStarted
        case .confidenceScore:
            return true
        case .communityComparison:
            return true
        }
    }
}
