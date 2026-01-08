//
//  QuickTasksScreen.swift
//  Billix
//
//  Quick Earnings Hub - Task tracking with Supabase integration
//  Supports daily/weekly resets, progress tracking, and point claiming
//

import SwiftUI

struct QuickTasksScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel = TasksViewModel.shared

    // Sheet presentation states
    @State private var showPollView = false
    @State private var showQuizView = false
    @State private var showTipView = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with Streak Badge
                    headerSection

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        // Quick Earnings Tasks Grid
                        quickEarningsGridView
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color(hex: "#F3F4F6").ignoresSafeArea())

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

            // Claim Success Overlay (only for Quick Earnings tasks)
            if viewModel.showClaimSuccess && isQuickEarningsTask(viewModel.claimedTaskTitle) {
                claimSuccessOverlay
            }

            // Check-in Success Overlay (NOT shown in Quick Earnings - check-in is not a Quick Earnings task)
            // Daily check-in notifications appear in the main tasks view only
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadTasks()
        }
        // Notification listeners for navigation
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPoll"))) { _ in
            print("📥 RECEIVED NavigateToPoll notification")
            showPollView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToQuiz"))) { _ in
            print("📥 RECEIVED NavigateToQuiz notification")
            showQuizView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTip"))) { _ in
            print("📥 RECEIVED NavigateToTip notification")
            showTipView = true
        }
        // Sheet presentations
        .sheet(isPresented: $showPollView) {
            PollView()
        }
        .sheet(isPresented: $showQuizView) {
            QuizView()
        }
        .sheet(isPresented: $showTipView) {
            TipView()
        }
        // Listen for task updates (when poll/quiz/tip/social is completed)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PointsUpdated"))) { _ in
            print("📥 [QUICK EARNINGS] PointsUpdated notification received - refreshing tasks")
            Task {
                await viewModel.loadTasks()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Earnings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text("Complete daily micro-tasks for quick points")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Unclaimed Tasks Indicator
            if viewModel.hasUnclaimedQuickEarnings {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 12))
                    Text("\(viewModel.unclaimedQuickEarningsCount) task\(viewModel.unclaimedQuickEarningsCount == 1 ? "" : "s") ready to claim!")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#10B981"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "#10B981").opacity(0.1))
                )
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Quick Earnings Grid View

    private var quickEarningsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.quickEarningsTasks) { task in
                QuickTaskCard(task: task) {
                    viewModel.handleTaskTap(task)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Retry") {
                Task {
                    await viewModel.loadTasks()
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.billixMediumGreen)
            .cornerRadius(10)
        }
        .padding(.top, 100)
    }

    // MARK: - Claim Success Overlay

    private var claimSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissClaimSuccess()
                }

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 60))

                Text("+ \(viewModel.claimedPoints) Points!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Text(viewModel.claimedTaskTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .padding(40)
        }
        .transition(.opacity)
        .onAppear {
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.dismissClaimSuccess()
            }
        }
    }

    // MARK: - Check-in Success Overlay

    private var checkInSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissCheckInSuccess()
                }

            VStack(spacing: 16) {
                if let streak = viewModel.checkInStreak {
                    Text(streak.flameEmoji)
                        .font(.system(size: 60))

                    if let milestone = streak.milestoneMessage {
                        Text(milestone)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(streak.streakText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.billixDarkGreen)
                    }

                    Text("+ \(viewModel.claimedPoints) Points!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#10B981"))

                    if streak.isNewRecord {
                        Text("🏆 New Record!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .padding(40)
        }
        .transition(.opacity)
        .onAppear {
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewModel.dismissCheckInSuccess()
            }
        }
    }

    // MARK: - Helper Methods

    /// Check if a task title belongs to Quick Earnings tasks (poll, quiz, tip, social)
    private func isQuickEarningsTask(_ taskTitle: String) -> Bool {
        viewModel.quickEarningsTasks.contains { $0.title == taskTitle }
    }
}

// MARK: - Quick Task Card

struct QuickTaskCard: View {
    let task: UserTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Main card content
                VStack(alignment: .center, spacing: 0) {
                    // Icon section
                    Group {
                        if let customImage = task.customImage {
                            Image(customImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: task.iconName)
                                .font(.system(size: 80, weight: .regular))
                                .foregroundColor(task.iconSwiftUIColor)
                                .frame(width: 100, height: 100)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .padding(.top, 44)
                    .padding(.bottom, 16)
                    .opacity(task.isClaimed ? 0.3 : 1.0)

                    // Title
                    Text(task.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(task.isClaimed ? .gray : .black)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(height: 18)
                        .padding(.horizontal, 8)

                    Spacer().frame(height: 6)

                    // Description
                    Text(task.description)
                        .font(.system(size: 11, weight: .regular))
                        .lineSpacing(0)
                        .foregroundColor(task.isClaimed ? .gray.opacity(0.6) : Color.black.opacity(0.6))
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 48, maxHeight: 64, alignment: .top)
                        .padding(.horizontal, 8)

                    // Progress Bar (for multi-step tasks)
                    if task.showsProgressBar {
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)

                                    // Progress
                                    Rectangle()
                                        .fill(Color(hex: "#10B981"))
                                        .frame(width: geometry.size.width * task.progressPercentage, height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, 8)

                            Text(task.progressText)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    } else {
                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    // CTA Button
                    Text(task.buttonState == .completed ? "Completed ✓" : task.buttonState == .claim ? "Claim" : task.ctaText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(task.buttonState.color)
                        .frame(height: 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(task.isClaimed ? Color.gray.opacity(0.1) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )

                // Point badge
                Text(task.isClaimed ? "✓" : task.canClaim ? "Claim!" : "+ \(task.points)")
                    .font(.system(size: task.canClaim ? 12 : 20, weight: .bold))
                    .foregroundColor(task.isClaimed ? .gray : task.canClaim ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .disabled(!task.buttonState.isEnabled)
    }
}

// MARK: - Preview

#Preview {
    QuickTasksScreen()
}
