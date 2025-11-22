import Foundation

// MARK: - Focus Area Model

struct FocusArea: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let icon: String
    var isEnabled: Bool

    static let lowerUtilities = FocusArea(
        id: UUID(),
        title: "Lower my utility bills",
        icon: "bolt.fill",
        isEnabled: true
    )

    static let fixInternet = FocusArea(
        id: UUID(),
        title: "Fix my internet/phone plan",
        icon: "wifi",
        isEnabled: true
    )

    static let cleanSubscriptions = FocusArea(
        id: UUID(),
        title: "Clean up my subscriptions",
        icon: "square.stack.fill",
        isEnabled: false
    )

    static let prepareMove = FocusArea(
        id: UUID(),
        title: "Prepare to move out (rent / bills)",
        icon: "house.fill",
        isEnabled: false
    )

    static let understandBills = FocusArea(
        id: UUID(),
        title: "Just understand my bills better",
        icon: "chart.bar.fill",
        isEnabled: true
    )

    static let all: [FocusArea] = [
        .lowerUtilities,
        .fixInternet,
        .cleanSubscriptions,
        .prepareMove,
        .understandBills
    ]
}

// MARK: - Savings Goal

struct SavingsGoal: Codable, Equatable {
    var targetAmount: Double
    var currentSavings: Double

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentSavings / targetAmount, 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var targetString: String {
        String(format: "$%.0f", targetAmount)
    }

    var currentString: String {
        String(format: "$%.0f", currentSavings)
    }
}

// MARK: - Preview Data

extension SavingsGoal {
    static let preview = SavingsGoal(
        targetAmount: 100.0,
        currentSavings: 65.0
    )

    static let previewJustStarted = SavingsGoal(
        targetAmount: 150.0,
        currentSavings: 15.0
    )

    static let previewAlmostThere = SavingsGoal(
        targetAmount: 80.0,
        currentSavings: 75.0
    )
}
