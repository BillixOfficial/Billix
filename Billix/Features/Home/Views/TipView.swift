//
//  TipView.swift
//  Billix
//
//  Created by Claude Code
//  Daily money-saving tip viewer for Quick Earnings
//

import SwiftUI

struct TipView: View {
    @StateObject private var viewModel = TipViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#FAFAFA")
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let tipData = viewModel.tipData {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Icon header
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: tipData.tip.iconColor ?? "#10B981").opacity(0.2),
                                                    Color(hex: tipData.tip.iconColor ?? "#10B981").opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)

                                    Image(systemName: tipData.tip.iconName ?? "lightbulb.fill")
                                        .font(.system(size: 44, weight: .semibold))
                                        .foregroundColor(Color(hex: tipData.tip.iconColor ?? "#10B981"))
                                }

                                // Category badge
                                if let category = tipData.tip.category {
                                    Text(category.capitalized)
                                        .font(.system(size: 12, weight: .bold))
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: "#6B7280"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(hex: "#F3F4F6"))
                                        )
                                }
                            }
                            .padding(.top, 40)
                            .padding(.bottom, 24)

                            // Title
                            Text(tipData.tip.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#1F2937"))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)

                            // Content
                            Text(tipData.tip.content)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color(hex: "#374151"))
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                )
                                .padding(.horizontal, 20)

                            // Already read indicator
                            if tipData.hasRead {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)

                                    Text("You've already read this tip")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#6B7280"))
                                }
                                .padding(.top, 20)
                            }

                            // Mark as read button (only if not read)
                            if !tipData.hasRead {
                                Button(action: {
                                    Task {
                                        await viewModel.markAsRead()
                                    }
                                }) {
                                    HStack {
                                        Text("I've Read This")
                                            .font(.system(size: 17, weight: .semibold))

                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 32)
                            }

                            // Tip footer
                            VStack(spacing: 12) {
                                Divider()
                                    .padding(.horizontal, 24)

                                HStack(spacing: 16) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#9CA3AF"))

                                    Text("Daily Money-Saving Tip")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(hex: "#6B7280"))
                                }
                                .padding(.bottom, 8)
                            }
                            .padding(.top, 32)

                            Spacer(minLength: 40)
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Tip")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text(errorMessage)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button("Try Again") {
                            Task {
                                await viewModel.loadTip()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // Toast notification
                EmptyView()
            }
            .toast(
                isShowing: $viewModel.showToast,
                message: "Tip saved!",
                points: 5
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                }
            }
        }
        .task {
            await viewModel.loadTip()
        }
    }
}

// MARK: - ViewModel

@MainActor
class TipViewModel: ObservableObject {
    @Published var tipData: TipWithReadStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false

    private let tipsService = TipsService.shared
    private let rewardsService = RewardsService()
    private let taskService = TaskTrackingService()
    private let authService = AuthService.shared

    func loadTip() async {
        isLoading = true
        errorMessage = nil

        do {
            tipData = try await tipsService.getTipWithReadStatus()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ Error loading tip: \(error)")
        }
    }

    func markAsRead() async {
        guard let tipId = tipData?.tip.id else { return }

        do {
            // 1. Mark tip as read
            try await tipsService.markTipAsRead(tipId: tipId, readDuration: nil)

            // Update local state
            if let tipData = tipData {
                self.tipData = TipWithReadStatus(
                    tip: tipData.tip,
                    hasRead: true,
                    tipView: nil
                )
            }

            // 2. Track task completion AND auto-claim
            if let userId = authService.currentUser?.id {
                // Mark as completed
                _ = try await taskService.incrementTaskProgress(
                    userId: userId,
                    taskKey: "daily_read_tip",
                    sourceId: tipId
                )

                // Auto-claim points
                let claimResult = try await taskService.claimTaskReward(
                    userId: userId,
                    taskKey: "daily_read_tip"
                )

                if claimResult.success {
                    // Award points via RewardsService
                    try await rewardsService.addPoints(
                        userId: userId,
                        amount: claimResult.pointsAwarded,
                        type: "task_completion",
                        description: "Daily tip read",
                        source: "daily_read_tip"
                    )

                    // Notify RewardsViewModel to refresh
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PointsUpdated"),
                        object: nil
                    )

                    print("✅ Tip completed and claimed: +\(claimResult.pointsAwarded) pts")

                    // Show toast notification
                    showToast = true

                    // Auto-dismiss toast after 2 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        showToast = false
                    }
                }
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error marking tip as read: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Tip View") {
    TipView()
}
