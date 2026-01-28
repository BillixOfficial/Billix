//
//  TasksViewModel.swift
//  Billix
//
//  ViewModel for task tracking system
//  Manages daily/weekly tasks, progress, claims, and check-ins
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TasksViewModel: ObservableObject {

    // MARK: - Singleton

    nonisolated(unsafe) static let shared = TasksViewModel()

    // MARK: - Services

    private let taskTrackingService: TaskTrackingService
    private let rewardsService: RewardsService
    private let authService: AuthService
    private let streakService: StreakService

    // MARK: - Published State

    @Published var tasks: [UserTask] = []
    @Published var currentStreak: Int = 0
    @Published var weeklyCheckIns: [Bool] = Array(repeating: false, count: 7)  // Mon-Sun check-in status
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Claim success feedback
    @Published var showClaimSuccess: Bool = false
    @Published var claimedPoints: Int = 0
    @Published var claimedTaskTitle: String = ""

    // Check-in success feedback
    @Published var showCheckInSuccess: Bool = false
    @Published var checkInStreak: CheckInStreak?

    // MARK: - Computed Properties

    /// Tasks grouped by category for UI sections
    var taskSections: [TaskSection] {
        let grouped = Dictionary(grouping: tasks) { $0.category }

        return TaskCategory.allCases.compactMap { category in
            guard let categoryTasks = grouped[category], !categoryTasks.isEmpty else {
                return nil
            }

            return TaskSection(
                id: category.rawValue,
                category: category,
                tasks: categoryTasks.sorted { $0.taskKey < $1.taskKey }
            )
        }.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    /// Daily tasks only
    var dailyTasks: [UserTask] {
        tasks.filter { $0.category == .daily }
    }

    /// Weekly tasks only
    var weeklyTasks: [UserTask] {
        tasks.filter { $0.category == .weekly || $0.category == .unlimited }
    }

    /// Unlimited tasks
    var unlimitedTasks: [UserTask] {
        tasks.filter { $0.category == .unlimited }
    }

    /// One-time tasks
    var oneTimeTasks: [UserTask] {
        tasks.filter { $0.category == .oneTime }
    }

    /// Quick Earnings tasks only (poll, quiz, tip, social)
    var quickEarningsTasks: [UserTask] {
        tasks.filter { task in
            task.taskType == .poll ||
            task.taskType == .quiz ||
            task.taskType == .tip ||
            task.taskType == .social
        }.sorted {
            if $0.points == $1.points {
                return $0.taskKey < $1.taskKey  // Secondary sort by task key for consistent ordering
            }
            return $0.points < $1.points  // Primary sort by points (least to highest)
        }
    }

    /// Check if any quick earnings tasks can be claimed
    var hasUnclaimedQuickEarnings: Bool {
        quickEarningsTasks.contains { $0.canClaim }
    }

    /// Count of unclaimed quick earnings tasks
    var unclaimedQuickEarningsCount: Int {
        quickEarningsTasks.filter { $0.canClaim }.count
    }

    /// Check if any tasks can be claimed
    var hasUnclaimedTasks: Bool {
        tasks.contains { $0.canClaim }
    }

    /// Count of unclaimed tasks
    var unclaimedTaskCount: Int {
        tasks.filter { $0.canClaim }.count
    }

    // MARK: - Notification Observers

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private nonisolated init(
        taskTrackingService: TaskTrackingService = TaskTrackingService(),
        rewardsService: RewardsService = RewardsService(),
        authService: AuthService = AuthService.shared,
        streakService: StreakService = StreakService.shared
    ) {
        self.taskTrackingService = taskTrackingService
        self.rewardsService = rewardsService
        self.authService = authService
        self.streakService = streakService

        Task { @MainActor in
            setupNotificationObservers()
        }
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Listen for bill upload completions
        NotificationCenter.default.publisher(for: NSNotification.Name("BillUploadCompleted"))
            .sink { [weak self] notification in
                guard let billId = notification.userInfo?["billId"] as? UUID else {
                    print("❌ Error: No billId found in notification userInfo")
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.trackBillUpload(billId: billId)
                }
            }
            .store(in: &cancellables)

        // Listen for game completions
        NotificationCenter.default.publisher(for: NSNotification.Name("GameCompleted"))
            .sink { [weak self] notification in
                guard let sessionId = notification.userInfo?["sessionId"] as? UUID,
                      let pointsEarned = notification.userInfo?["pointsEarned"] as? Int else {
                    print("❌ Error: Missing sessionId or pointsEarned in notification")
                    return
                }
                Task { @MainActor [weak self] in
                    await self?.trackGameCompletion(sessionId: sessionId, pointsEarned: pointsEarned)
                }
            }
            .store(in: &cancellables)

        // Listen for points updates (Quick Earnings completions)
        NotificationCenter.default.publisher(for: NSNotification.Name("PointsUpdated"))
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadTasks()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load all tasks for current user
    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let userId = authService.currentUser?.id else {
                errorMessage = "No authenticated user"
                isLoading = false
                print("❌ Error: No authenticated user")
                return
            }

            // Fetch tasks from Supabase
            let taskDTOs = try await taskTrackingService.getUserTasks(userId: userId)

            // Convert to domain models
            tasks = taskDTOs.map { UserTask(from: $0) }

            // Fetch weekly check-in history
            weeklyCheckIns = try await taskTrackingService.getWeeklyCheckIns(userId: userId)

            // CRITICAL FIX: Fetch current streak from StreakService
            try await streakService.fetchStreak()

            // Update local currentStreak from StreakService
            currentStreak = streakService.currentStreak

            isLoading = false
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error loading tasks: \(error)")
        }
    }

    /// Handle task tap - routes to start/claim based on button state
    func handleTaskTap(_ task: UserTask) {
        // Check-in is special - always performs check-in regardless of button state
        if task.taskType == .checkIn {
            Task {
                await performCheckIn()
            }
            return
        }

        switch task.buttonState {
        case .start:
            startTask(task)
        case .claim:
            Task {
                await claimTask(task)
            }
        case .completed:
            // Do nothing - task already claimed
            break
        }
    }

    /// Start a task - navigate to appropriate screen
    private func startTask(_ task: UserTask) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Navigate based on task type
        switch task.taskType {
        case .checkIn:
            Task {
                await performCheckIn()
            }
        case .billUpload:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToUpload"), object: nil)
        case .poll:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToPoll"), object: nil)
        case .quiz:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToQuiz"), object: nil)
        case .tip:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTip"), object: nil)
        case .game:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToGame"), object: nil)
        case .referral:
            NotificationCenter.default.post(name: NSNotification.Name("ShowReferralSheet"), object: nil)
        case .social:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToSocial"), object: nil)
        }
    }

    /// Perform daily check-in
    func performCheckIn() async {
        guard let userId = authService.currentUser?.id else {
            print("❌ Error: No user ID for check-in")
            return
        }

        do {
            let result = try await taskTrackingService.checkInDaily(userId: userId)

            if result.success {
                // Update streak
                currentStreak = result.currentStreak

                // Show success feedback
                checkInStreak = CheckInStreak(
                    currentStreak: result.currentStreak,
                    longestStreak: result.currentStreak,
                    isNewRecord: result.isNewRecord,
                    milestoneReached: result.milestoneReached
                )
                showCheckInSuccess = true

                // Award points via RewardsViewModel
                if result.pointsAwarded > 0 {
                    _ = try await rewardsService.addPoints(
                        userId: userId,
                        amount: result.pointsAwarded,
                        type: "task_completion",
                        description: "Daily check-in"
                    )

                    // Notify RewardsViewModel to refresh balance
                    NotificationCenter.default.post(name: NSNotification.Name("PointsUpdated"), object: nil)

                    // Show claim feedback
                    claimedPoints = result.pointsAwarded
                    claimedTaskTitle = "Daily Check-In"
                    showClaimSuccess = true
                }

                // Refresh tasks
                await loadTasks()

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

            } else {
                errorMessage = result.message
            }
        } catch {
            errorMessage = "Check-in failed: \(error.localizedDescription)"
            print("❌ Error during check-in: \(error)")
        }
    }

    /// Claim reward for completed task
    func claimTask(_ task: UserTask) async {
        guard let userId = authService.currentUser?.id else { return }

        do {
            let result = try await taskTrackingService.claimTaskReward(
                userId: userId,
                taskKey: task.taskKey
            )

            if result.success {
                // Award points via RewardsService
                _ = try await rewardsService.addPoints(
                    userId: userId,
                    amount: result.pointsAwarded,
                    type: "task_completion",
                    description: result.taskTitle
                )

                // Notify RewardsViewModel to refresh balance
                NotificationCenter.default.post(name: NSNotification.Name("PointsUpdated"), object: nil)

                // Show success feedback
                claimedPoints = result.pointsAwarded
                claimedTaskTitle = result.taskTitle
                showClaimSuccess = true

                // Refresh tasks
                await loadTasks()

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

            } else {
                errorMessage = result.message
            }
        } catch {
            errorMessage = "Failed to claim task: \(error.localizedDescription)"
            print("❌ Error claiming task: \(error)")
        }
    }

    // MARK: - Auto-Tracking Methods

    /// Track bill upload completion
    private func trackBillUpload(billId: UUID) async {
        guard let userId = authService.currentUser?.id else {
            print("❌ Error: No authenticated user - cannot track bill upload")
            return
        }

        do {
            // Track daily_upload_bill task
            _ = try await taskTrackingService.incrementTaskProgress(
                userId: userId,
                taskKey: "daily_upload_bill",
                sourceId: billId
            )

            // Track weekly_upload_5_bills task
            _ = try await taskTrackingService.incrementTaskProgress(
                userId: userId,
                taskKey: "weekly_upload_5_bills",
                sourceId: billId
            )

            // Refresh tasks
            await loadTasks()

        } catch {
            print("❌ Error tracking bill upload: \(error)")
        }
    }

    /// Track game completion
    private func trackGameCompletion(sessionId: UUID, pointsEarned: Int) async {
        guard let userId = authService.currentUser?.id else { return }

        do {
            // Track weekly_play_7_games task
            let result = try await taskTrackingService.incrementTaskProgress(
                userId: userId,
                taskKey: "weekly_play_7_games",
                sourceId: sessionId,
                metadata: ["points_earned": pointsEarned]
            )

            // Refresh tasks
            await loadTasks()

        } catch {
            print("❌ Error tracking game completion: \(error)")
        }
    }

    // MARK: - Helper Methods

    /// Dismiss success overlay
    func dismissClaimSuccess() {
        withAnimation {
            showClaimSuccess = false
        }
    }

    /// Dismiss check-in success overlay
    func dismissCheckInSuccess() {
        withAnimation {
            showCheckInSuccess = false
        }
    }
}

// MARK: - TaskCategory Extension

extension TaskCategory: CaseIterable {
    static var allCases: [TaskCategory] {
        [.daily, .weekly, .unlimited, .oneTime]
    }
}
