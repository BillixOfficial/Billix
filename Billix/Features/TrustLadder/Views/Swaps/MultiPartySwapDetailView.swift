//
//  MultiPartySwapDetailView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Detailed view for multi-party swap management
//

import SwiftUI

struct MultiPartySwapDetailView: View {
    let swapId: UUID

    @StateObject private var swapService = MultiPartySwapService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var swap: MultiPartySwap?
    @State private var participants: [SwapParticipant] = []
    @State private var isLoading = true
    @State private var showBoostSheet = false
    @State private var showCancelAlert = false
    @State private var showStartAlert = false
    @State private var errorMessage: String?

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    private var isOrganizer: Bool {
        swap?.organizerId == SupabaseService.shared.currentUserId
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(accent)
            } else if let swap = swap {
                ScrollView {
                    VStack(spacing: 20) {
                        // Status header
                        statusHeader(swap)

                        // Progress card
                        progressCard(swap)

                        // Actions (for organizer)
                        if isOrganizer {
                            organizerActions(swap)
                        }

                        // Participants
                        participantsSection

                        // Timeline
                        timelineSection(swap)

                        // Legal
                        DisclaimerBanner(type: .swapConfirmation, isExpandable: true)
                    }
                    .padding()
                }
            } else {
                Text("Swap not found")
                    .foregroundColor(secondaryText)
            }
        }
        .navigationTitle("Swap Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOrganizer, let swap = swap, swap.swapStatus == .recruiting {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showBoostSheet = true
                        } label: {
                            Label("Boost Swap", systemImage: "flame.fill")
                        }

                        Button(role: .destructive) {
                            showCancelAlert = true
                        } label: {
                            Label("Cancel Swap", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(primaryText)
                    }
                }
            }
        }
        .sheet(isPresented: $showBoostSheet) {
            if let swap = swap {
                PriorityListingView(swap: swap) {
                    Task { await loadSwapDetails() }
                }
            }
        }
        .alert("Cancel Swap?", isPresented: $showCancelAlert) {
            Button("Keep Swap", role: .cancel) { }
            Button("Cancel", role: .destructive) {
                cancelSwap()
            }
        } message: {
            Text("This will cancel the swap and notify all participants. This cannot be undone.")
        }
        .alert("Start Swap?", isPresented: $showStartAlert) {
            Button("Not Yet", role: .cancel) { }
            Button("Start") {
                startSwap()
            }
        } message: {
            Text("Starting the swap will notify all participants to begin making their payments.")
        }
        .task {
            await loadSwapDetails()
        }
        .refreshable {
            await loadSwapDetails()
        }
    }

    // MARK: - Load Data

    private func loadSwapDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let summary = try await swapService.getSwapSummary(swapId)
            swap = summary.swap
            participants = summary.participants
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Status Header

    private func statusHeader(_ swap: MultiPartySwap) -> some View {
        VStack(spacing: 12) {
            // Status badge
            HStack {
                Image(systemName: swap.swapStatus?.icon ?? "circle")
                    .font(.system(size: 18))
                Text(swap.swapStatus?.displayName ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(swap.swapStatus?.color ?? .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background((swap.swapStatus?.color ?? .gray).opacity(0.15))
            .cornerRadius(20)

            // Type and created
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: swap.type?.icon ?? "arrow.left.arrow.right")
                        .foregroundColor(swap.type?.color ?? accent)
                    Text(swap.type?.displayName ?? "Swap")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)
                }

                Text("Created \(swap.createdAt, style: .relative)")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Progress Card

    private func progressCard(_ swap: MultiPartySwap) -> some View {
        VStack(spacing: 16) {
            // Amount display
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filled")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                    Text(swap.formattedFilledAmount)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(accent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                    Text(swap.formattedTargetAmount)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(primaryText)
                }
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(secondaryText.opacity(0.2))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [swap.type?.color ?? accent, (swap.type?.color ?? accent).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * swap.fillPercentage, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(Int(swap.fillPercentage * 100))% complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryText)

                    Spacer()

                    Text("\(swap.formattedRemainingAmount) remaining")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }
            }

            // Stats
            HStack(spacing: 0) {
                statItem(
                    value: "\(participants.count)",
                    label: "Participants",
                    icon: "person.2"
                )

                Divider()
                    .frame(height: 30)
                    .background(secondaryText.opacity(0.3))

                statItem(
                    value: "\(swap.maxParticipants)",
                    label: "Max",
                    icon: "person.3"
                )

                if let deadline = swap.executionDeadline {
                    Divider()
                        .frame(height: 30)
                        .background(secondaryText.opacity(0.3))

                    statItem(
                        value: deadline.formatted(date: .abbreviated, time: .omitted),
                        label: "Deadline",
                        icon: "calendar"
                    )
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(accent)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryText)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Organizer Actions

    private func organizerActions(_ swap: MultiPartySwap) -> some View {
        VStack(spacing: 10) {
            if swap.swapStatus == .filled {
                Button {
                    showStartAlert = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Swap")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent)
                    .cornerRadius(12)
                }
            }

            if swap.swapStatus == .inProgress {
                Button {
                    completeSwap()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Complete")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }

            if swap.swapStatus == .recruiting {
                Button {
                    showBoostSheet = true
                } label: {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("Boost Visibility")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            if participants.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.3")
                            .font(.system(size: 24))
                            .foregroundColor(secondaryText)
                        Text("No participants yet")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(participants) { participant in
                        participantRow(participant)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func participantRow(_ participant: SwapParticipant) -> some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(participant.participantStatus?.color.opacity(0.2) ?? secondaryText.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(participant.participantStatus?.color ?? secondaryText)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(participant.formattedContribution)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                HStack(spacing: 6) {
                    Image(systemName: participant.participantStatus?.color == .green ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 10))
                        .foregroundColor(participant.participantStatus?.color ?? secondaryText)

                    Text(participant.participantStatus?.displayName ?? "Pending")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }
            }

            Spacer()

            // Verification badge
            if participant.screenshotVerified == true {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            } else if participant.screenshotUrl != nil {
                Text("Pending")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(background)
        .cornerRadius(10)
    }

    // MARK: - Timeline Section

    private func timelineSection(_ swap: MultiPartySwap) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 0) {
                timelineItem(
                    title: "Created",
                    date: swap.createdAt,
                    isCompleted: true,
                    isFirst: true
                )

                timelineItem(
                    title: "Recruiting",
                    date: nil,
                    isCompleted: swap.swapStatus != .pending,
                    isCurrent: swap.swapStatus == .recruiting
                )

                timelineItem(
                    title: "Filled",
                    date: nil,
                    isCompleted: [.filled, .inProgress, .completed].contains(swap.swapStatus),
                    isCurrent: swap.swapStatus == .filled
                )

                timelineItem(
                    title: "In Progress",
                    date: nil,
                    isCompleted: [.inProgress, .completed].contains(swap.swapStatus),
                    isCurrent: swap.swapStatus == .inProgress
                )

                timelineItem(
                    title: "Completed",
                    date: swap.swapStatus == .completed ? swap.updatedAt : nil,
                    isCompleted: swap.swapStatus == .completed,
                    isLast: true
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func timelineItem(
        title: String,
        date: Date?,
        isCompleted: Bool,
        isCurrent: Bool = false,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Line and dot
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(isCompleted ? accent : secondaryText.opacity(0.3))
                        .frame(width: 2, height: 20)
                }

                ZStack {
                    Circle()
                        .fill(isCompleted ? accent : (isCurrent ? accent.opacity(0.3) : secondaryText.opacity(0.2)))
                        .frame(width: 12, height: 12)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.black)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted && !isCurrent ? accent : secondaryText.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: isCompleted || isCurrent ? .semibold : .regular))
                    .foregroundColor(isCompleted || isCurrent ? primaryText : secondaryText)

                if let date = date {
                    Text(date, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }
            }
            .padding(.vertical, 4)

            Spacer()
        }
    }

    // MARK: - Actions

    private func cancelSwap() {
        Task {
            do {
                try await swapService.cancelSwap(swapId)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startSwap() {
        Task {
            do {
                try await swapService.startSwap(swapId)
                await loadSwapDetails()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func completeSwap() {
        Task {
            do {
                try await swapService.completeSwap(swapId)
                await loadSwapDetails()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        MultiPartySwapDetailView(swapId: UUID())
    }
    .preferredColorScheme(.dark)
}
