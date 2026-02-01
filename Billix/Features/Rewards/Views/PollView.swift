//
//  PollView.swift
//  Billix
//
//  Created by Claude Code
//  Daily poll voting interface for Quick Earnings
//

import SwiftUI

struct PollView: View {
    @StateObject private var viewModel = PollViewModel()
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
                } else if let pollData = viewModel.pollData {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Daily Poll")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#6B7280"))
                                    .textCase(.uppercase)

                                Text(pollData.poll.question)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#1F2937"))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 40)
                            .padding(.horizontal, 24)

                            // Poll options or results
                            if pollData.hasVoted {
                                // Show results
                                ResultsView(poll: pollData.poll, selectedOption: pollData.selectedOption)
                                    .padding(.horizontal, 24)
                            } else {
                                // Show voting options
                                VStack(spacing: 16) {
                                    VotingOptionButton(
                                        option: .a,
                                        text: pollData.poll.optionA,
                                        isSelected: viewModel.selectedOption == .a,
                                        action: { viewModel.selectOption(.a) }
                                    )

                                    VotingOptionButton(
                                        option: .b,
                                        text: pollData.poll.optionB,
                                        isSelected: viewModel.selectedOption == .b,
                                        action: { viewModel.selectOption(.b) }
                                    )
                                }
                                .padding(.horizontal, 24)

                                // Submit button
                                Button(action: {
                                    Task {
                                        await viewModel.submitVote()
                                    }
                                }) {
                                    HStack {
                                        Text("Submit Vote")
                                            .font(.system(size: 17, weight: .semibold))

                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        LinearGradient(
                                            colors: viewModel.selectedOption != nil
                                                ? [Color(hex: "#F97316"), Color(hex: "#E11D48")]
                                                : [Color(hex: "#D1D5DB"), Color(hex: "#9CA3AF")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                .disabled(viewModel.selectedOption == nil)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }

                            // Poll metadata
                            if !pollData.hasVoted {
                                VStack(spacing: 8) {
                                    HStack(spacing: 16) {
                                        Label("\(pollData.poll.totalVotes) votes", systemImage: "person.2.fill")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(hex: "#6B7280"))

                                        if let category = pollData.poll.category {
                                            Label(category.capitalized, systemImage: "tag.fill")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Color(hex: "#6B7280"))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            Spacer(minLength: 40)
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Poll")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text(errorMessage)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button("Try Again") {
                            Task {
                                await viewModel.loadPoll()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // No poll available today
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#6B7280"))

                        Text("No Poll Today")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1F2937"))

                        Text("Check back tomorrow for a new daily poll!")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // Toast notification
                EmptyView()
            }
            .toast(
                isShowing: $viewModel.showToast,
                message: "Vote submitted!",
                points: 2
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
            await viewModel.loadPoll()
        }
    }
}

// MARK: - Components

struct VotingOptionButton: View {
    let option: PollOption
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.rawValue.uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? Color(hex: "#F97316") : Color(hex: "#6B7280"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "#FEF3C7") : Color(hex: "#F3F4F6"))
                    )

                Text(text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1F2937"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#F97316"))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: isSelected ? Color(hex: "#F97316").opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 12 : 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#F97316") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ResultsView: View {
    let poll: CommunityPoll
    let selectedOption: PollOption?

    var body: some View {
        VStack(spacing: 16) {
            ResultBar(
                option: .a,
                text: poll.optionA,
                percentage: poll.percentageA,
                voteCount: poll.voteCountA,
                isSelected: selectedOption == .a
            )

            ResultBar(
                option: .b,
                text: poll.optionB,
                percentage: poll.percentageB,
                voteCount: poll.voteCountB,
                isSelected: selectedOption == .b
            )

            // Total votes
            Text("\(poll.totalVotes) total votes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#6B7280"))
                .padding(.top, 8)
        }
    }
}

struct ResultBar: View {
    let option: PollOption
    let text: String
    let percentage: Double
    let voteCount: Int
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Text(option.rawValue.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Text(text)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#1F2937"))

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "#F97316") : Color(hex: "#6B7280"))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#F3F4F6"))
                        .frame(height: 12)

                    // Progress bar
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [Color(hex: "#F97316"), Color(hex: "#E11D48")]
                                    : [Color(hex: "#6B7280"), Color(hex: "#4B5563")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100.0), height: 12)
                }
            }
            .frame(height: 12)

            if isSelected {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Your vote")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(hex: "#F97316"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color(hex: "#F97316") : Color.clear, lineWidth: 2)
        )
    }
}


// MARK: - ViewModel

@MainActor
class PollViewModel: ObservableObject {
    @Published var pollData: PollWithUserResponse?
    @Published var selectedOption: PollOption?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false

    private let pollService = CommunityPollService.shared
    private let rewardsService = RewardsService()
    private let taskService = TaskTrackingService()
    private let authService = AuthService.shared

    func loadPoll() async {
        isLoading = true
        errorMessage = nil

        do {
            pollData = try await pollService.getPollWithUserResponse()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ Error loading poll: \(error)")
        }
    }

    func selectOption(_ option: PollOption) {
        selectedOption = option

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func submitVote() async {
        guard let pollId = pollData?.poll.id,
              let option = selectedOption else { return }

        do {
            // 1. Submit vote
            let updatedPoll = try await pollService.submitVote(pollId: pollId, option: option)

            // 2. Update poll data to show results
            pollData = PollWithUserResponse(
                poll: updatedPoll,
                userResponse: PollResponse(
                    id: UUID(),
                    pollId: pollId,
                    userId: authService.currentUser?.id ?? UUID(),
                    selectedOption: option.rawValue,
                    createdAt: Date()
                ),
                hasVoted: true
            )

            // 3. Track task completion AND auto-claim
            if let userId = authService.currentUser?.id {
                // Mark as completed
                _ = try await taskService.incrementTaskProgress(
                    userId: userId,
                    taskKey: "daily_poll_vote",
                    sourceId: pollId
                )

                // Auto-claim points
                let claimResult = try await taskService.claimTaskReward(
                    userId: userId,
                    taskKey: "daily_poll_vote"
                )

                if claimResult.success {
                    // Award points via RewardsService
                    _ = try await rewardsService.addPoints(
                        userId: userId,
                        amount: claimResult.pointsAwarded,
                        type: "task_completion",
                        description: "Daily poll vote"
                    )

                    // Notify RewardsViewModel to refresh
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PointsUpdated"),
                        object: nil
                    )

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
            print("❌ Error submitting vote: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Poll - Not Voted") {
    PollView()
}
