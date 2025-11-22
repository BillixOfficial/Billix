import Foundation

struct DailyTask: Identifiable, Codable {
    let id: UUID
    let icon: String // Emoji
    let title: String
    let subtitle: String
    let points: Int
    let taskType: TaskType
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        icon: String,
        title: String,
        subtitle: String,
        points: Int,
        taskType: TaskType,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.points = points
        self.taskType = taskType
        self.isCompleted = isCompleted
    }

    enum TaskType: String, Codable {
        case swipeVerify
        case dailyVote
        case scanReceipt
        case uploadBill
        case checkInsight
    }
}

// MARK: - Mock Data

extension DailyTask {
    static let mockTasks: [DailyTask] = [
        DailyTask(
            icon: "👉",
            title: "Swipe to verify 3 bills",
            subtitle: "Quick verification needed",
            points: 50,
            taskType: .swipeVerify
        ),
        DailyTask(
            icon: "🗳️",
            title: "Daily Vote: Best Internet?",
            subtitle: "Share your opinion",
            points: 20,
            taskType: .dailyVote
        ),
        DailyTask(
            icon: "📸",
            title: "Scan a receipt for points",
            subtitle: "Any receipt works",
            points: 30,
            taskType: .scanReceipt
        ),
        DailyTask(
            icon: "📄",
            title: "Upload a new bill",
            subtitle: "Unlock personalized insights",
            points: 100,
            taskType: .uploadBill
        ),
        DailyTask(
            icon: "💡",
            title: "Check your savings insights",
            subtitle: "New opportunities found",
            points: 10,
            taskType: .checkInsight
        )
    ]

    static let completedTask = DailyTask(
        icon: "✅",
        title: "Completed task example",
        subtitle: "This is done!",
        points: 50,
        taskType: .swipeVerify,
        isCompleted: true
    )
}
