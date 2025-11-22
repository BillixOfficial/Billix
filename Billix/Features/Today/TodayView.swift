//
//  TodayView.swift
//  Billix
//
//  Redesigned with modern dark theme inspired by Netflix-quality UI
//  Design System v2 - Clean, sophisticated, content-first approach
//

import SwiftUI

/// Main "Today" Dashboard - Modern dark theme with sophisticated styling
struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color.dsBackgroundPrimary,
                        Color.dsBackgroundSecondary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // SECTION 1: Modern Header
                        ModernHeaderSection(
                            userName: viewModel.userName,
                            billixScore: viewModel.billixScore
                        )

                        // SECTION 2: Hero Financial Snapshot
                        FinancialHeroCard(
                            totalDue: viewModel.totalMonthlyBills,
                            overdueBills: viewModel.userBills.filter { $0.isOverdue }.count,
                            upcomingBills: viewModel.userBills.filter { !$0.isPaid && !$0.isOverdue }.count
                        )
                        .dsScreenPadding()

                        // SECTION 3: Stats Grid (2x2)
                        StatsGridSection(
                            billixScore: viewModel.billixScore,
                            streak: viewModel.currentStreak,
                            savedAmount: 1247.0, // TODO: Calculate from bills
                            billsPaidCount: viewModel.userBills.filter { $0.isPaid }.count
                        )
                        .dsScreenPadding()

                        // SECTION 4: Priority Actions
                        PriorityActionsSection(tasks: viewModel.dailyTasks, onTaskTap: viewModel.handleTaskTap)
                            .dsScreenPadding()

                        // SECTION 5: Bills Snapshot
                        BillsSnapshotV2(
                            bills: viewModel.userBills,
                            totalMonthly: viewModel.totalMonthlyBills
                        )
                        .dsScreenPadding()

                        // SECTION 6: Today's Focus (Daily Brief + Actions)
                        if let brief = viewModel.dailyBrief {
                            TodaysFocusCard(
                                brief: brief,
                                topTasks: Array(viewModel.dailyTasks.prefix(3))
                            )
                            .dsScreenPadding()
                        }

                        // SECTION 7: Community Engagement
                        if let poll = viewModel.currentPoll {
                            CommunitySection(
                                poll: poll,
                                selectedOption: viewModel.selectedPollOption != nil ?
                                    poll.options.firstIndex(where: { $0.id == viewModel.selectedPollOption }) : nil,
                                hasVoted: viewModel.hasVotedToday,
                                ranking: viewModel.communityRanking,
                                onVote: { index in
                                    viewModel.submitVote(poll.options[index].id)
                                }
                            )
                            .dsScreenPadding()
                        }

                        // SECTION 8: Flash Drop (if available)
                        if let flashDrop = viewModel.currentFlashDrop {
                            FlashDropCardV2(flashDrop: flashDrop)
                                .dsScreenPadding()
                        }

                        // SECTION 9: Quick Links Grid
                        QuickLinksSection(
                            learnArticles: viewModel.learnArticles,
                            featuredCluster: viewModel.featuredCluster,
                            inviteCode: viewModel.userInviteCode
                        )
                        .dsScreenPadding()

                        // Bottom safe area spacing
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func refreshData() async {
        isRefreshing = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        viewModel.loadMockData()
        isRefreshing = false
    }
}

// MARK: - DailyTask Extension

extension DailyTask {
    var accentColor: Color {
        switch taskType {
        case .swipeVerify: return .dsPrimaryAccent
        case .dailyVote: return .dsWarning
        case .scanReceipt: return .dsInfo
        case .uploadBill: return .dsSuccess
        case .checkInsight: return .dsGold
        }
    }
}

// MARK: - SECTION 1: Modern Header

struct ModernHeaderSection: View {
    let userName: String
    let billixScore: Int

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(greeting)
                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .medium))
                    .foregroundColor(.dsTextTertiary)

                Text(userName)
                    .font(.system(size: DesignSystem.Typography.Size.h2, weight: .bold, design: .rounded))
                    .foregroundColor(.dsTextPrimary)
            }

            Spacer()

            // Billix Score Badge
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Text("\(billixScore)")
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .bold, design: .rounded))
                    .foregroundColor(.dsTextPrimary)

                Image(systemName: "star.fill")
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                    .foregroundColor(.dsGold)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(Color.dsGold.opacity(DesignSystem.Opacity.backgroundTint))
            )

            // Profile Button
            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.dsTextSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenEdge)
        .padding(.top, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.xs)
    }
}

// MARK: - SECTION 2: Financial Hero Card

struct FinancialHeroCard: View {
    let totalDue: Double
    let overdueBills: Int
    let upcomingBills: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Title
            Text("Your Financial Snapshot")
                .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                .foregroundColor(.dsTextPrimary)

            // Total Due Amount
            Text("$\(String(format: "%.2f", totalDue))")
                .font(.system(size: DesignSystem.Typography.Size.display, weight: .bold, design: .rounded))
                .foregroundColor(.dsTextPrimary)

            Text("Total Due This Month")
                .font(.system(size: DesignSystem.Typography.Size.body, weight: .medium))
                .foregroundColor(.dsTextSecondary)

            // Stats Row
            HStack(spacing: DesignSystem.Spacing.lg) {
                StatPill(
                    icon: "exclamationmark.circle.fill",
                    value: "\(overdueBills)",
                    label: "Overdue",
                    color: .dsError
                )

                StatPill(
                    icon: "clock.fill",
                    value: "\(upcomingBills)",
                    label: "Due Soon",
                    color: .dsWarning
                )

                Spacer()

                // CTA Button
                Button(action: {}) {
                    Text("Pay Now")
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                                .fill(Color.dsPrimaryAccent)
                        )
                }
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .dsCardPadding()
        .heroCard()
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .bold, design: .rounded))
                    .foregroundColor(.dsTextPrimary)

                Text(label)
                    .font(.system(size: DesignSystem.Typography.Size.caption, weight: .medium))
                    .foregroundColor(.dsTextTertiary)
            }
        }
    }
}

// MARK: - SECTION 3: Stats Grid (2x2)

struct StatsGridSection: View {
    let billixScore: Int
    let streak: Int
    let savedAmount: Double
    let billsPaidCount: Int

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                TodayStatCard(
                    icon: "star.fill",
                    value: "\(billixScore)",
                    label: "Billix Score",
                    accentColor: .dsPrimaryAccent
                )

                TodayStatCard(
                    icon: "flame.fill",
                    value: "\(streak)",
                    label: "Day Streak",
                    accentColor: .dsWarning
                )
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                TodayStatCard(
                    icon: "dollarsign.circle.fill",
                    value: "$\(Int(savedAmount))",
                    label: "Saved",
                    accentColor: .dsSuccess
                )

                TodayStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(billsPaidCount)",
                    label: "Paid",
                    accentColor: .dsInfo
                )
            }
        }
    }
}

struct TodayStatCard: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(accentColor)

            Text(value)
                .font(.system(size: DesignSystem.Typography.Size.h2, weight: .bold, design: .rounded))
                .foregroundColor(.dsTextPrimary)

            Text(label)
                .font(.system(size: DesignSystem.Typography.Size.caption, weight: .medium))
                .foregroundColor(.dsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .statCard(accentColor: accentColor)
    }
}

// MARK: - SECTION 4: Priority Actions

struct PriorityActionsSection: View {
    let tasks: [DailyTask]
    let onTaskTap: (DailyTask) -> Void

    var topTasks: [DailyTask] {
        Array(tasks.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            Text("Priority Actions")
                .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                .foregroundColor(.dsTextPrimary)

            // Tasks List
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(topTasks) { task in
                    ActionTaskRow(task: task, onTap: { onTaskTap(task) })
                }
            }
        }
        .dsCardPadding()
        .billixCard()
    }
}

struct ActionTaskRow: View {
    let task: DailyTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Icon
                Image(systemName: task.icon)
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                    .foregroundColor(task.accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(task.accentColor.opacity(DesignSystem.Opacity.backgroundTint))
                    )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .medium))
                        .foregroundColor(.dsTextPrimary)

                    Text(task.subtitle)
                        .font(.system(size: DesignSystem.Typography.Size.caption, weight: .regular))
                        .foregroundColor(.dsTextTertiary)
                }

                Spacer()

                // Points Badge
                if !task.isCompleted {
                    Text("+\(task.points)pts")
                        .font(.system(size: DesignSystem.Typography.Size.caption, weight: .bold))
                        .foregroundColor(.dsGold)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .fill(Color.dsGold.opacity(DesignSystem.Opacity.backgroundTint))
                        )
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignSystem.Typography.Size.h3))
                        .foregroundColor(.dsSuccess)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SECTION 5: Bills Snapshot V2

struct BillsSnapshotV2: View {
    let bills: [Bill]
    let totalMonthly: Double
    @State private var isExpanded = false

    var overdueBills: [Bill] {
        bills.filter { $0.isOverdue }
    }

    var upcomingBills: [Bill] {
        bills.filter { !$0.isPaid && !$0.isOverdue }
    }

    var paidBills: [Bill] {
        bills.filter { $0.isPaid }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Text("Bills This Month")
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                    .foregroundColor(.dsTextPrimary)

                Spacer()

                Button(action: { withAnimation(DesignSystem.Animation.spring) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: DesignSystem.Typography.Size.h3))
                        .foregroundColor(.dsTextSecondary)
                }
            }

            // Summary Pills
            HStack(spacing: DesignSystem.Spacing.xs) {
                BillStatusPill(
                    count: overdueBills.count,
                    label: "Overdue",
                    color: .dsError
                )

                BillStatusPill(
                    count: upcomingBills.count,
                    label: "Due Soon",
                    color: .dsWarning
                )

                BillStatusPill(
                    count: paidBills.count,
                    label: "Paid",
                    color: .dsSuccess
                )
            }

            // Expanded Bill List
            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(upcomingBills.prefix(5)) { bill in
                        BillRow(bill: bill)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .dsCardPadding()
        .billixCard()
    }
}

struct BillStatusPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Text("\(count)")
                .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .bold, design: .rounded))
                .foregroundColor(.dsTextPrimary)

            Text(label)
                .font(.system(size: DesignSystem.Typography.Size.caption, weight: .medium))
                .foregroundColor(.dsTextSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(color.opacity(DesignSystem.Opacity.backgroundTint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BillRow: View {
    let bill: Bill

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.providerName)
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .medium))
                    .foregroundColor(.dsTextPrimary)

                Text(bill.dueDate, style: .date)
                    .font(.system(size: DesignSystem.Typography.Size.caption))
                    .foregroundColor(.dsTextTertiary)
            }

            Spacer()

            Text("$\(String(format: "%.2f", bill.amount))")
                .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .bold, design: .rounded))
                .foregroundColor(.dsTextPrimary)
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

// MARK: - SECTION 6: Today's Focus Card

struct TodaysFocusCard: View {
    let brief: BillBrief
    let topTasks: [DailyTask]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            Text("Today's Focus")
                .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                .foregroundColor(.dsTextPrimary)

            // Brief Summary
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(brief.title)
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))
                    .foregroundColor(.dsTextPrimary)

                Text(brief.excerpt ?? brief.content)
                    .font(.system(size: DesignSystem.Typography.Size.body))
                    .foregroundColor(.dsTextSecondary)
                    .lineLimit(isExpanded ? nil : 2)
            }

            // Read More Button
            Button(action: { withAnimation(DesignSystem.Animation.spring) { isExpanded.toggle() } }) {
                Text(isExpanded ? "Show Less" : "Read More")
                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .semibold))
                    .foregroundColor(.dsPrimaryAccent)
            }
        }
        .dsCardPadding()
        .billixCard()
    }
}

// MARK: - SECTION 7: Community Section

struct CommunitySection: View {
    let poll: Poll
    let selectedOption: Int?
    let hasVoted: Bool
    let ranking: CommunityRanking
    let onVote: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            Text("Community")
                .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                .foregroundColor(.dsTextPrimary)

            // Poll Question
            Text(poll.question)
                .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .medium))
                .foregroundColor(.dsTextPrimary)

            // Poll Options
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<poll.options.count, id: \.self) { index in
                    PollOptionButton(
                        option: poll.options[index].text,
                        index: index,
                        isSelected: selectedOption == index,
                        hasVoted: hasVoted,
                        percentage: hasVoted ? poll.options[index].percentage : 0,
                        onTap: { onVote(index) }
                    )
                }
            }

            // Ranking Badge
            HStack {
                Text("You're in the top \(ranking.percentile)%")
                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .semibold))
                    .foregroundColor(.dsTextPrimary)

                Spacer()

                Text("+20pts")
                    .font(.system(size: DesignSystem.Typography.Size.caption, weight: .bold))
                    .foregroundColor(.dsGold)
                    .pill(backgroundColor: Color.dsGold.opacity(DesignSystem.Opacity.backgroundTint))
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .dsCardPadding()
        .billixCard()
    }
}

struct PollOptionButton: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let hasVoted: Bool
    let percentage: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: hasVoted ? {} : onTap) {
            HStack {
                if !hasVoted {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: DesignSystem.Typography.Size.h3))
                        .foregroundColor(isSelected ? .dsPrimaryAccent : .dsTextTertiary)
                }

                Text(option)
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                    .foregroundColor(.dsTextPrimary)

                Spacer()

                if hasVoted {
                    Text("\(Int(percentage))%")
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .bold, design: .rounded))
                        .foregroundColor(.dsTextPrimary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                        .fill(Color.dsElevatedBackground)

                    if hasVoted {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                                .fill(Color.dsPrimaryAccent.opacity(0.3))
                                .frame(width: geo.size.width * (percentage / 100))
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .stroke(
                        isSelected ? Color.dsPrimaryAccent : Color.white.opacity(DesignSystem.Opacity.backgroundTint),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SECTION 8: Flash Drop V2

struct FlashDropCardV2: View {
    let flashDrop: FlashDrop

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Text("⚡️ Flash Drop")
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .bold))
                    .foregroundColor(.dsTextPrimary)

                Spacer()

                Text("Limited Time")
                    .font(.system(size: DesignSystem.Typography.Size.caption, weight: .bold))
                    .foregroundColor(.dsWarning)
                    .pill(backgroundColor: Color.dsWarning.opacity(DesignSystem.Opacity.backgroundTint))
            }

            // Savings Amount
            Text("Save $\(flashDrop.savingsAmount)")
                .font(.system(size: DesignSystem.Typography.Size.h1, weight: .bold, design: .rounded))
                .foregroundColor(.dsSuccess)

            Text(flashDrop.description ?? flashDrop.title)
                .font(.system(size: DesignSystem.Typography.Size.body))
                .foregroundColor(.dsTextSecondary)

            // CTA Button
            Button(action: {}) {
                Text("Claim Now")
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .actionButton(backgroundColor: .dsWarning)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
        .dsCardPadding()
        .billixCard()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                .stroke(Color.dsWarning.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - SECTION 9: Quick Links Section

struct QuickLinksSection: View {
    let learnArticles: [LearnArticle]
    let featuredCluster: ProviderCluster?
    let inviteCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            Text("Quick Links")
                .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                .foregroundColor(.dsTextPrimary)

            // Links Grid
            VStack(spacing: DesignSystem.Spacing.xs) {
                QuickLinkButton(
                    icon: "book.fill",
                    title: "Learn",
                    subtitle: "Financial tips",
                    accentColor: .dsInfo
                )

                if featuredCluster != nil {
                    QuickLinkButton(
                        icon: "person.3.fill",
                        title: "Clusters",
                        subtitle: "Join groups",
                        accentColor: .dsPrimaryAccent
                    )
                }

                QuickLinkButton(
                    icon: "gift.fill",
                    title: "Invite & Earn",
                    subtitle: "Share code: \(inviteCode)",
                    accentColor: .dsGold
                )
            }
        }
        .dsCardPadding()
        .billixCard()
    }
}

struct QuickLinkButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        Button(action: {}) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(DesignSystem.Opacity.backgroundTint))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))
                        .foregroundColor(.dsTextPrimary)

                    Text(subtitle)
                        .font(.system(size: DesignSystem.Typography.Size.caption))
                        .foregroundColor(.dsTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                    .foregroundColor(.dsTextTertiary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(Color.dsElevatedBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
    }
}
