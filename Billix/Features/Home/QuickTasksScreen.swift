//
//  QuickTasksScreen.swift
//  Billix
//
//  Quick Earnings Hub - Offer Wall with mini-tasks grid
//  Inspired by Bing Rewards vertical card layout
//

import SwiftUI

// MARK: - Quick Task Model

struct QuickTask: Identifiable {
    let id = UUID()
    let icon: String           // SF Symbol name
    let customImage: String?   // Custom asset image name (optional)
    let iconColor: Color
    let title: String
    let description: String
    let points: Int
    let ctaText: String        // Custom CTA text (e.g., "Vote now >")
    let category: TaskCategory
    let frequency: TaskFrequency  // Daily or one-time

    enum TaskCategory {
        case survey, video, email, referral, promotion, social, quiz
    }

    enum TaskFrequency {
        case daily      // Resets every day
        case oneTime    // Can only be completed once ever
    }
}

// MARK: - Quick Tasks Screen

struct QuickTasksScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var completedTaskIDs: Set<UUID> = []  // Track completed tasks
    @State private var lastResetDate: Date = Date()      // Track when daily tasks reset

    // Sample tasks (replace with API data later)
    private let tasks: [QuickTask] = [
        QuickTask(
            icon: "chart.bar.fill",
            customImage: "BarGraph",
            iconColor: Color(hex: "#3B82F6"),
            title: "Share your opinion",
            description: "Vote in the daily poll to see what other members think",
            points: TaskConfiguration.pollVote,
            ctaText: "Vote now >",
            category: .survey,
            frequency: .daily  // DAILY TASK
        ),
        QuickTask(
            icon: "heart.fill",
            customImage: "FollowHeart",
            iconColor: Color(hex: "#EC4899"),
            title: "Stay connected",
            description: "Follow our page to get the latest updates and bonus codes",
            points: TaskConfiguration.followSocial,
            ctaText: "Follow us >",
            category: .social,
            frequency: .oneTime  // ONE-TIME ONLY
        ),
        QuickTask(
            icon: "lightbulb.fill",
            customImage: "LightBulbMoney",
            iconColor: Color(hex: "#F59E0B"),
            title: "Save smarter",
            description: "Read today's quick tip to help you manage your budget better",
            points: TaskConfiguration.readTip,
            ctaText: "Read tip >",
            category: .promotion,
            frequency: .daily  // DAILY TASK
        ),
        QuickTask(
            icon: "graduationcap.fill",
            customImage: "GraduationCap",
            iconColor: Color(hex: "#8B5CF6"),
            title: "Test your knowledge",
            description: "Answer three quick trivia questions to earn bonus points",
            points: TaskConfiguration.completeQuiz,
            ctaText: "Start quiz >",
            category: .quiz,
            frequency: .daily  // DAILY TASK
        )
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Earn More Points")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Complete simple tasks to boost your balance")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // 2-Column Grid of Task Cards
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(tasks) { task in
                            QuickTaskCard(
                                task: task,
                                isCompleted: isTaskCompleted(task)
                            ) {
                                // Handle task tap
                                handleTaskTap(task)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(Color(hex: "#F3F4F6").ignoresSafeArea())  // Light gray like Bing

            // X Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixMediumGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 4)
                    )
            }
            .padding(16)
        }
        .navigationBarHidden(true)
        .onAppear {
            resetDailyTasksIfNeeded()
        }
    }

    private func isTaskCompleted(_ task: QuickTask) -> Bool {
        // Check if task is completed
        return completedTaskIDs.contains(task.id)
    }

    private func handleTaskTap(_ task: QuickTask) {
        // Don't allow tapping completed one-time tasks
        if task.frequency == .oneTime && completedTaskIDs.contains(task.id) {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Mark task as completed
        completedTaskIDs.insert(task.id)

        // TODO: Navigate to task completion flow based on category
        // TODO: Award points to user
        print("Completed task: \(task.title) - Earned \(task.points) points")
    }

    private func resetDailyTasksIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            // New day - reset daily tasks
            let oneTimeTasks = tasks.filter { $0.frequency == .oneTime }.map { $0.id }
            completedTaskIDs = completedTaskIDs.filter { oneTimeTasks.contains($0) }
            lastResetDate = Date()
        }
    }
}

// MARK: - Quick Task Card (Bing Rewards Style)

struct QuickTaskCard: View {
    let task: QuickTask
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Main card content
                VStack(alignment: .center, spacing: 0) {
                    // Icon section - Fixed height area
                    Group {
                        if let customImage = task.customImage {
                            // Custom asset image
                            Image(customImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                        } else {
                            // SF Symbol fallback
                            Image(systemName: task.icon)
                                .font(.system(size: 80, weight: .regular))
                                .foregroundColor(task.iconColor)
                                .frame(width: 100, height: 100)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .padding(.top, 44)  // Space for point badge
                    .padding(.bottom, 16)
                    .opacity(isCompleted ? 0.3 : 1.0)  // Greyed out when completed

                    // Title - Single line, no wrapping
                    Text(task.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isCompleted ? .gray : .black)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(height: 18)  // Fixed height
                        .padding(.horizontal, 8)

                    // Fixed spacing between title and description
                    Spacer()
                        .frame(height: 6)

                    // Description - Fixed height area
                    Text(task.description)
                        .font(.system(size: 11, weight: .regular))
                        .lineSpacing(0)
                        .foregroundColor(isCompleted ? .gray.opacity(0.6) : Color.black.opacity(0.6))
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .frame(height: 48, alignment: .top)  // Fixed height, top aligned
                        .padding(.horizontal, 8)

                    Spacer(minLength: 0)

                    // CTA - Fixed position at bottom
                    Text(isCompleted ? "Completed ✓" : task.ctaText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isCompleted ? .gray : Color(hex: "#3B82F6"))
                        .frame(height: 16)  // Fixed height
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isCompleted ? Color.gray.opacity(0.1) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )

                // Point badge - Overlaid in top-right corner
                Text(isCompleted ? "✓" : "+ \(task.points)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isCompleted ? .gray : Color(hex: "#F59E0B"))
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .disabled(isCompleted)  // Disable button when completed
    }
}

// MARK: - Preview

#Preview {
    QuickTasksScreen()
}
