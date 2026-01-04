//
//  TaskModels.swift
//  Billix
//
//  Domain models for task tracking system
//  Converted from DTOs with computed properties for UI
//

import Foundation
import SwiftUI

// MARK: - Task Category

enum TaskCategory: String, Codable {
    case daily
    case weekly
    case unlimited
    case oneTime = "one_time"

    var displayName: String {
        switch self {
        case .daily: return "Daily Tasks"
        case .weekly: return "Weekly Challenges"
        case .unlimited: return "Unlimited"
        case .oneTime: return "One-Time Rewards"
        }
    }

    var sortOrder: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 2
        case .unlimited: return 3
        case .oneTime: return 4
        }
    }
}

// MARK: - Task Type

enum TaskType: String, Codable {
    case checkIn = "check_in"
    case billUpload = "bill_upload"
    case poll
    case quiz
    case tip
    case game
    case referral
    case social

    var icon: String {
        switch self {
        case .checkIn: return "checkmark.circle.fill"
        case .billUpload: return "doc.fill"
        case .poll: return "chart.bar.fill"
        case .quiz: return "graduationcap.fill"
        case .tip: return "lightbulb.fill"
        case .game: return "gamecontroller.fill"
        case .referral: return "person.2.fill"
        case .social: return "heart.fill"
        }
    }
}

// MARK: - Task Button State

enum TaskButtonState {
    case start          // Not started - show action button
    case claim          // Completed but not claimed - show "Claim" button
    case completed      // Already claimed - show checkmark, greyed out

    var title: String {
        switch self {
        case .start: return "Start"
        case .claim: return "Claim"
        case .completed: return "Completed ✓"
        }
    }

    var color: Color {
        switch self {
        case .start: return Color(hex: "#3B82F6")  // Blue
        case .claim: return Color(hex: "#10B981")   // Green
        case .completed: return .gray
        }
    }

    var isEnabled: Bool {
        self != .completed
    }
}

// MARK: - User Task Model

struct UserTask: Identifiable {
    let id: String  // task_key
    let taskKey: String
    let title: String
    let description: String
    let category: TaskCategory
    let taskType: TaskType
    let points: Int
    let iconName: String
    let customImage: String?
    let iconColor: Color
    let ctaText: String
    let resetType: String
    let requiresCount: Int
    let currentCount: Int
    let isCompleted: Bool
    let isClaimed: Bool
    let canClaim: Bool
    let completedAt: Date?
    let claimedAt: Date?
    let periodStart: Date?
    let periodEnd: Date?

    // MARK: - Computed Properties

    /// Progress percentage (0.0 to 1.0) for multi-step tasks
    var progressPercentage: Double {
        guard requiresCount > 1 else { return isCompleted ? 1.0 : 0.0 }
        return Double(currentCount) / Double(requiresCount)
    }

    /// Progress text (e.g., "3/5" or "7/7")
    var progressText: String {
        guard requiresCount > 1 else { return "" }
        return "\(currentCount)/\(requiresCount)"
    }

    /// Determines which button state to show
    var buttonState: TaskButtonState {
        if isClaimed {
            return .completed
        } else if canClaim {
            return .claim
        } else {
            return .start
        }
    }

    /// Shows progress bar for multi-step tasks
    var showsProgressBar: Bool {
        requiresCount > 1 && !isClaimed
    }

    /// Icon color as SwiftUI Color
    var iconSwiftUIColor: Color {
        iconColor
    }

    // MARK: - Initialization from DTO

    init(from dto: UserTaskDTO) {
        self.id = dto.taskKey
        self.taskKey = dto.taskKey
        self.title = dto.title
        self.description = dto.description
        self.category = TaskCategory(rawValue: dto.category) ?? .daily
        self.taskType = TaskType(rawValue: dto.taskType) ?? .checkIn
        self.points = dto.points
        self.iconName = dto.iconName ?? ""
        self.customImage = dto.customImage
        self.iconColor = Color(hex: dto.iconColor ?? "#3B82F6")
        self.ctaText = dto.ctaText
        self.resetType = dto.resetType
        self.requiresCount = dto.requiresCount
        self.currentCount = dto.currentCount
        self.isCompleted = dto.isCompleted
        self.isClaimed = dto.isClaimed
        self.canClaim = dto.canClaim
        self.completedAt = dto.completedAt
        self.claimedAt = dto.claimedAt
        self.periodStart = dto.periodStart
        self.periodEnd = dto.periodEnd
    }
}

// MARK: - Task Sections

/// Groups tasks by category for UI display
struct TaskSection: Identifiable {
    let id: String
    let category: TaskCategory
    let tasks: [UserTask]

    var title: String {
        category.displayName
    }

    var hasUnclaimedTasks: Bool {
        tasks.contains { $0.canClaim }
    }

    var unclaimedCount: Int {
        tasks.filter { $0.canClaim }.count
    }
}

// MARK: - Check-in Streak

struct CheckInStreak {
    let currentStreak: Int
    let longestStreak: Int
    let isNewRecord: Bool
    let milestoneReached: String?

    var streakText: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }

    var flameEmoji: String {
        if currentStreak >= 30 {
            return "🔥🔥🔥"
        } else if currentStreak >= 7 {
            return "🔥🔥"
        } else if currentStreak >= 1 {
            return "🔥"
        } else {
            return "⚪️"
        }
    }

    var milestoneMessage: String? {
        guard let milestone = milestoneReached else { return nil }

        switch milestone {
        case "7_days":
            return "🎉 7 Day Streak Milestone!"
        case "30_days":
            return "🌟 30 Day Streak Milestone!"
        case "100_days":
            return "👑 100 Day Streak Milestone!"
        default:
            return nil
        }
    }
}
