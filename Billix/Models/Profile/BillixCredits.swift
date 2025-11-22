import Foundation

// MARK: - Billix Credits Model

struct BillixCredits: Codable, Equatable {
    var balance: Int
    var transactions: [CreditTransaction]
    var earnTasks: [EarnTask]

    var recentTransactions: [CreditTransaction] {
        Array(transactions.prefix(10))
    }

    var availableEarnTasks: [EarnTask] {
        earnTasks.filter { $0.status != .completed }
    }

    var completedEarnTasks: [EarnTask] {
        earnTasks.filter { $0.status == .completed }
    }
}

// MARK: - Credit Transaction

struct CreditTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: TransactionType
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

enum TransactionType: String, Codable {
    case earned = "Earned"
    case spent = "Spent"
    case bonus = "Bonus"
}

// MARK: - Earn Task

struct EarnTask: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let reward: Int
    var status: TaskStatus
    var progress: Double // 0.0 to 1.0

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var rewardString: String {
        "+\(reward) credits"
    }
}

enum TaskStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
}

// MARK: - Preview Data

extension BillixCredits {
    static let preview = BillixCredits(
        balance: 85,
        transactions: [
            CreditTransaction(
                id: UUID(),
                type: .earned,
                amount: 10,
                description: "Uploaded internet bill",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            CreditTransaction(
                id: UUID(),
                type: .spent,
                amount: -5,
                description: "Unlocked premium report",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            CreditTransaction(
                id: UUID(),
                type: .earned,
                amount: 15,
                description: "Friend signed up and uploaded bill",
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            CreditTransaction(
                id: UUID(),
                type: .bonus,
                amount: 25,
                description: "Welcome bonus",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
            ),
            CreditTransaction(
                id: UUID(),
                type: .earned,
                amount: 10,
                description: "Completed Bill Health action plan",
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date()
            )
        ],
        earnTasks: [
            EarnTask(
                id: UUID(),
                title: "Upload your first utility bill",
                description: "Add a utility bill to get started",
                reward: 10,
                status: .completed,
                progress: 1.0
            ),
            EarnTask(
                id: UUID(),
                title: "Complete your profile",
                description: "Add your phone number and verify email",
                reward: 15,
                status: .inProgress,
                progress: 0.5
            ),
            EarnTask(
                id: UUID(),
                title: "Invite a friend who uploads a bill",
                description: "Share Billix with friends and earn when they upload their first bill",
                reward: 20,
                status: .notStarted,
                progress: 0.0
            ),
            EarnTask(
                id: UUID(),
                title: "Upload bills from 3 different categories",
                description: "Help us understand your full bill picture",
                reward: 25,
                status: .inProgress,
                progress: 0.66
            ),
            EarnTask(
                id: UUID(),
                title: "Complete your first Bill Health action plan",
                description: "Take action on a savings opportunity",
                reward: 10,
                status: .completed,
                progress: 1.0
            )
        ]
    )
}
