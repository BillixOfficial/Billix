import SwiftUI

@MainActor
class TodayViewModel: ObservableObject {
    // MARK: - Published Properties

    // User Info
    @Published var userName: String = "Sarah"
    @Published var userZip: String = "07101"

    // Gamification
    @Published var billixScore: Int = 74
    @Published var currentStreak: Int = 3

    // Daily Tasks
    @Published var dailyTasks: [DailyTask] = []

    // Market Data
    @Published var marketUpdates: [MarketUpdate] = []

    // Daily Brief
    @Published var dailyBrief: BillBrief?

    // Community Vote
    @Published var currentPoll: Poll?
    @Published var selectedPollOption: UUID?
    @Published var hasVotedToday: Bool = false

    // Community Ranking
    @Published var communityRanking: CommunityRanking = .mockRanking

    // Flash Drops
    @Published var currentFlashDrop: FlashDrop?

    // Clusters
    @Published var featuredCluster: ProviderCluster?

    // Learn & Invite
    @Published var learnArticles: [LearnArticle] = []
    @Published var userInviteCode: String = "SARAH2024"

    // Bills
    @Published var userBills: [Bill] = []
    @Published var totalMonthlyBills: Double = 0

    // MARK: - Initialization

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        // Mock daily tasks
        dailyTasks = [
            DailyTask(
                icon: "👉",
                title: "Swipe to verify 3 bills",
                subtitle: "Quick verification needed",
                points: 50,
                taskType: .swipeVerify,
                isCompleted: false
            ),
            DailyTask(
                icon: "🗳️",
                title: "Daily Vote: Best Internet?",
                subtitle: "Share your opinion",
                points: 20,
                taskType: .dailyVote,
                isCompleted: false
            ),
            DailyTask(
                icon: "📸",
                title: "Scan a receipt for points",
                subtitle: "Any receipt works",
                points: 30,
                taskType: .scanReceipt,
                isCompleted: false
            )
        ]

        // Mock market data
        marketUpdates = MarketUpdate.mockUpdates

        // Mock daily brief
        dailyBrief = BillBrief.mockBrief

        // Mock poll
        currentPoll = Poll.mockPoll

        // Community ranking already set with default value

        // Mock flash drop
        currentFlashDrop = FlashDrop.mockDrop

        // Mock cluster
        featuredCluster = ProviderCluster.mockCluster

        // Mock learn articles
        learnArticles = LearnArticle.mockArticles

        // Mock bills
        userBills = Bill.mockBills
        totalMonthlyBills = Bill.mockTotalMonthly
    }

    func refreshData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Reload data
        loadMockData()
    }

    // MARK: - Task Handling

    func handleTaskTap(_ task: DailyTask) {
        switch task.taskType {
        case .swipeVerify:
            // Navigate to MicroVerifyScreen
            print("Navigate to MicroVerifyScreen")
        case .dailyVote:
            // Navigate to poll or show inline
            print("Navigate to poll")
        case .scanReceipt:
            // Navigate to ReceiptScanScreen
            print("Navigate to ReceiptScanScreen")
        case .uploadBill:
            // Navigate to UploadView
            print("Navigate to UploadView")
        case .checkInsight:
            // Navigate to insights
            print("Navigate to insights")
        }
    }

    func completeTask(_ task: DailyTask) {
        if let index = dailyTasks.firstIndex(where: { $0.id == task.id }) {
            dailyTasks[index].isCompleted = true

            // Award points
            awardPoints(task.points)

            // Update streak
            updateStreak()
        }
    }

    // MARK: - Gamification

    private func awardPoints(_ points: Int) {
        // TODO: Integrate with PointsManager when implemented
        print("Awarded \(points) points")

        // Show confetti or celebration
        showCelebration()
    }

    private func updateStreak() {
        // TODO: Integrate with StreakManager when implemented
        print("Streak updated")
    }

    private func showCelebration() {
        // TODO: Show confetti animation
        print("🎉 Celebration!")
    }

    // MARK: - Poll Voting

    func submitVote(_ optionId: UUID) {
        selectedPollOption = optionId
        hasVotedToday = true

        // Award points for voting
        awardPoints(20)

        // TODO: Submit vote to backend
        print("Voted for option: \(optionId)")
    }
}

