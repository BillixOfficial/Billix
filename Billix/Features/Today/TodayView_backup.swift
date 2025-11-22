import SwiftUI

/// Main "Today" Dashboard - Answers "What should I do with my money today in under 60 seconds?"
/// Hand-crafted aesthetic with organic spacing, varied radii, and personality
struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background - subtle off-white
                Color.billixLightGreen
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) { // Organic spacing (not 16 or 20)
                        // SECTION 1: Top Bar
                        TodayTopBar(
                            userName: viewModel.userName,
                            zip: viewModel.userZip,
                            billixScore: viewModel.billixScore,
                            streak: viewModel.currentStreak
                        )
                        .padding(.horizontal, 18) // Imperfect spacing
                        .padding(.top, 11)

                        // SECTION 2: Today's Market
                        TodaysMarketTicker(marketUpdates: viewModel.marketUpdates)

                        // SECTION 3: Your Actions Today
                        YourActionsToday(
                            tasks: viewModel.dailyTasks,
                            onTaskTap: viewModel.handleTaskTap
                        )

                        // SECTION 4: Daily Bill Brief
                        if let brief = viewModel.dailyBrief {
                            DailyBillBriefCard(brief: brief)
                        }

                        // SECTION 5: Community Vote
                        if let poll = viewModel.currentPoll {
                            CommunityVoteCard(
                                poll: poll,
                                selectedOption: viewModel.selectedPollOption,
                                hasVoted: viewModel.hasVotedToday,
                                onVote: viewModel.submitVote
                            )
                        }

                        // SECTION 7: How You're Doing
                        CommunityRankingCard(ranking: viewModel.communityRanking)

                        // SECTION 8: Upload Bill CTA
                        UploadBillCTA()

                        // SECTION 9: Flash Drop Highlight
                        if let flashDrop = viewModel.currentFlashDrop {
                            FlashDropHighlight(flashDrop: flashDrop)
                        }

                        // SECTION 10: Clusters Teaser
                        if let cluster = viewModel.featuredCluster {
                            ClustersTeaserCard(cluster: cluster)
                        }

                        // SECTION 11: Learn + Invite & Earn
                        LearnAndEarnSection(
                            learnArticles: viewModel.learnArticles,
                            inviteCode: viewModel.userInviteCode
                        )

                        // Bottom spacer for nav bar
                        Spacer()
                            .frame(height: 97)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func refreshData() async {
        isRefreshing = true
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        await viewModel.refreshData()
        isRefreshing = false
    }
}

// MARK: - Section 1: Top Bar

struct TodayTopBar: View {
    let userName: String
    let zip: String
    let billixScore: Int
    let streak: Int

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }

    var timeOfDayIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "🌤️"
        case 17..<20: return "🌆"
        default: return "🌙"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) { // Odd spacing
            // Left: Greeting + Location
            HStack(spacing: 6) {
                Text("\(greeting), \(userName)!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.billixDarkGreen)

                Text(zip)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .cornerRadius(8)

                Text(timeOfDayIcon)
                    .font(.system(size: 14))
            }

            Spacer()

            // Right: Score + Streak
            HStack(spacing: 9) {
                BillixScoreChip(score: billixScore)
                StreakIndicator(days: streak)
            }
        }
        .padding(.vertical, 11)
    }
}

struct BillixScoreChip: View {
    let score: Int

    var scoreColor: Color {
        if score >= 70 { return .billixMoneyGreen }
        else if score >= 50 { return .billixStarGold }
        else { return .billixPendingOrange }
    }

    var trendIcon: String {
        // Mock trend - in real implementation, compare to last score
        return "↗"
    }

    var body: some View {
        HStack(spacing: 5) {
            Text("Score:")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.billixMediumGreen)

            Text("\(score)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(scoreColor)

            Text(trendIcon)
                .font(.system(size: 11))
                .foregroundColor(scoreColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct StreakIndicator: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 16))

            Text("\(days)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.billixDarkGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.billixStarGold.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Section 3: Your Actions Today

struct YourActionsToday: View {
    let tasks: [DailyTask]
    let onTaskTap: (DailyTask) -> Void

    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Actions Today")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                Text("\(completedCount)/\(tasks.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 18)

            VStack(spacing: 8) { // Tight spacing for list
                ForEach(tasks) { task in
                    DailyTaskRow(task: task)
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onTaskTap(task)
                        }
                }
            }
            .padding(.horizontal, 18)
        }
    }
}

struct DailyTaskRow: View {
    let task: DailyTask

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(task.isCompleted ? Color.billixMoneyGreen.opacity(0.15) : Color.billixPendingOrange.opacity(0.12))
                    .frame(width: 38, height: 38)

                Text(task.icon)
                    .font(.system(size: 20))
            }

            // Task details
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .strikethrough(task.isCompleted)

                Text(task.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()

            // Points badge or checkmark
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.billixMoneyGreen)
            } else {
                Text("+\(task.points)pts")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.billixStarGold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.billixStarGold.opacity(0.12))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .cornerRadius(14) // Varied radius
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    task.isCompleted ? Color.billixMoneyGreen.opacity(0.3) : Color.gray.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Section 8: Upload Bill CTA

struct UploadBillCTA: View {
    @State private var showUploadSheet = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.billixLoginTeal.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 22))
                    .foregroundColor(.billixLoginTeal)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Add a bill to unlock insights")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.billixDarkGreen)

                Text("Get personalized savings opportunities")
                    .font(.system(size: 12))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()

            // Plus icon
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.billixLoginTeal)
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .foregroundColor(.billixLoginTeal.opacity(0.4))
        )
        .padding(.horizontal, 18)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showUploadSheet = true
        }
        .sheet(isPresented: $showUploadSheet) {
            UploadView()
        }
    }
}

// MARK: - Section 2: Today's Market Ticker

struct TodaysMarketTicker: View {
    let marketUpdates: [MarketUpdate]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Market")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(marketUpdates) { update in
                        MarketTickerCard(update: update)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

struct MarketTickerCard: View {
    let update: MarketUpdate

    var body: some View {
        HStack(spacing: 7) {
            Text(update.categoryIcon)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(update.category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.billixDarkGreen)

                HStack(spacing: 4) {
                    Image(systemName: update.changeDirection)
                        .font(.system(size: 10))
                        .foregroundColor(update.changeColor)

                    Text(update.formattedChange)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(update.changeColor)

                    Text("in \(update.zipPrefix)")
                        .font(.system(size: 11))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Section 5: Community Vote

struct CommunityVoteCard: View {
    let poll: Poll
    let selectedOption: UUID?
    let hasVoted: Bool
    let onVote: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("🗳️")
                        .font(.system(size: 20))

                    Text("Community Vote")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)
                }

                Spacer()

                if !hasVoted {
                    Text("+20pts")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.billixStarGold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.billixStarGold.opacity(0.12))
                        .cornerRadius(8)
                }
            }

            // Question
            Text(poll.question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.billixDarkGreen)

            // Options
            VStack(spacing: 10) {
                ForEach(poll.options) { option in
                    PollOptionRow(
                        option: option,
                        isSelected: selectedOption == option.id,
                        hasVoted: hasVoted
                    )
                    .onTapGesture {
                        if !hasVoted {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onVote(option.id)
                        }
                    }
                }
            }

            // Meta
            HStack(spacing: 8) {
                Text("\(poll.totalVotes.formatted()) votes")
                    .font(.system(size: 12))
                    .foregroundColor(.billixMediumGreen)

                Text("•")
                    .foregroundColor(.billixMediumGreen.opacity(0.5))

                Text("Ends in \(poll.timeRemaining)")
                    .font(.system(size: 12))
                    .foregroundColor(.billixPendingOrange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

struct PollOptionRow: View {
    let option: PollOption
    let isSelected: Bool
    let hasVoted: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Selection indicator
            if !hasVoted {
                Circle()
                    .stroke(isSelected ? Color.billixLoginTeal : Color.gray.opacity(0.3), lineWidth: 2)
                    .fill(isSelected ? Color.billixLoginTeal : Color.clear)
                    .frame(width: 20, height: 20)
            }

            // Option text
            Text(option.text)
                .font(.system(size: 14, weight: hasVoted && isSelected ? .semibold : .regular))
                .foregroundColor(.billixDarkGreen)

            Spacer()

            // Results (if voted)
            if hasVoted {
                Text("\(Int(option.percentage))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            GeometryReader { geometry in
                if hasVoted {
                    Rectangle()
                        .fill(isSelected ? Color.billixLoginTeal.opacity(0.15) : Color.billixLightGreen)
                        .frame(width: geometry.size.width * (option.percentage / 100))
                }
            }
        )
        .background(hasVoted ? Color.gray.opacity(0.05) : Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected && !hasVoted ? Color.billixLoginTeal : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Section 7: Community Ranking

struct CommunityRankingCard: View {
    let ranking: CommunityRanking

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How You're Doing")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            // Main ranking
            VStack(alignment: .center, spacing: 6) {
                Text("You're in the")
                    .font(.system(size: 15))
                    .foregroundColor(.billixMediumGreen)

                Text("TOP \(ranking.percentile)%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.billixLoginTeal)
                    .tracking(1)

                Text("of Billix users")
                    .font(.system(size: 15))
                    .foregroundColor(.billixMediumGreen)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .background(Color.gray.opacity(0.2))

            // Stats
            VStack(spacing: 12) {
                RankingStatRow(icon: "🎯", label: "Billix Score", value: "\(ranking.billixScore)/100")
                RankingStatRow(icon: "💰", label: "Avg Savings", value: "$\(ranking.avgSavings)/mo")
                RankingStatRow(icon: "📊", label: "Bills Tracked", value: "\(ranking.billsTracked)")
            }
        }
        .padding(18)
        .background(
            Color.billixLoginTeal.opacity(0.06)
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixLoginTeal.opacity(0.2), lineWidth: 1.5)
        )
        .padding(.horizontal, 18)
    }
}

struct RankingStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 18))

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.billixMediumGreen)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

// MARK: - Section 4: Daily Bill Brief

struct DailyBillBriefCard: View {
    let brief: BillBrief

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image header (placeholder for now)
            Rectangle()
                .fill(Color.billixLightGreen)
                .frame(height: 140)
                .overlay(
                    VStack {
                        Text(brief.categoryIcon)
                            .font(.system(size: 48))
                    }
                )
                .clipped()

            // Content
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Text(brief.categoryIcon)
                        .font(.system(size: 16))

                    Text(brief.category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Text(brief.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Text("\(brief.readTime) min read")
                        .font(.system(size: 12))
                        .foregroundColor(.billixMediumGreen)

                    Text("•")
                        .foregroundColor(.billixMediumGreen.opacity(0.5))

                    Text(brief.publishedDate, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.billixMediumGreen)
                }
            }
            .padding(15)
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

// MARK: - Section 9: Flash Drop Highlight

struct FlashDropHighlight: View {
    let flashDrop: FlashDrop
    @State private var timeRemaining: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with countdown
            HStack {
                HStack(spacing: 6) {
                    Text("⚡️")
                        .font(.system(size: 20))

                    Text("Flash Drop")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.billixPendingOrange)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Spacer()

                Text("Ends in \(timeRemaining)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
            }

            // Deal details
            VStack(alignment: .leading, spacing: 8) {
                Text(flashDrop.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                HStack(alignment: .bottom, spacing: 4) {
                    Text("Save")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(flashDrop.savingsAmount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)

                    Text("/mo")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            // CTA Button
            NavigationLink(destination: FlashDropsScreen()) {
                HStack {
                    Text("Claim Deal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Color.billixStarGold
                )
                .cornerRadius(12)
            }
        }
        .padding(18)
        .background(Color.billixPendingOrange.opacity(0.12))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixPendingOrange, lineWidth: 2)
        )
        .padding(.horizontal, 18)
        .onAppear {
            updateTimeRemaining()
        }
    }

    func updateTimeRemaining() {
        timeRemaining = flashDrop.formattedTimeRemaining
    }
}

// MARK: - Section 10: Clusters Teaser

struct ClustersTeaserCard: View {
    let cluster: ProviderCluster

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(cluster.categoryIcon)
                    .font(.system(size: 18))

                Text("\(cluster.category) Providers in \(cluster.zipPrefix)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }

            // Provider pills
            HStack(spacing: 8) {
                ForEach(cluster.topProviders.prefix(3)) { provider in
                    Text(provider.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixDarkGreen)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.billixLightGreen)
                        .cornerRadius(18)
                }

                if cluster.totalProviders > 3 {
                    Text("+\(cluster.totalProviders - 3) more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            // Stats
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Avg:")
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)

                    Text("$\(cluster.averagePrice)/mo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)
                }

                Text("•")
                    .foregroundColor(.billixMediumGreen.opacity(0.5))

                Text("\(cluster.memberCount) members")
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
            }

            // CTA
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                // Navigate to ClustersScreen
            }) {
                HStack {
                    Text("See All Clusters")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixLoginTeal)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.billixLoginTeal)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

// MARK: - Section 11: Learn + Invite & Earn

struct LearnAndEarnSection: View {
    let learnArticles: [LearnArticle]
    let inviteCode: String

    var body: some View {
        VStack(spacing: 16) {
            // Learn section
            LearnToLowerCard(articles: learnArticles)

            // Invite section
            InviteAndEarnCard(inviteCode: inviteCode)
        }
    }
}

struct LearnToLowerCard: View {
    let articles: [LearnArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📚")
                    .font(.system(size: 20))

                Text("Learn to Lower Your Bills")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                NavigationLink(destination: LearnScreen()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixLoginTeal)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(articles.prefix(3)) { article in
                        LearnArticlePill(article: article)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

struct LearnArticlePill: View {
    let article: LearnArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.icon)
                .font(.system(size: 28))

            Text(article.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.billixDarkGreen)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            Text(article.category)
                .font(.system(size: 11))
                .foregroundColor(.billixMediumGreen)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .padding(12)
        .frame(width: 140, height: 110)
        .background(Color.billixLightGreen)
        .cornerRadius(14)
    }
}

struct InviteAndEarnCard: View {
    let inviteCode: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Text("🎁")
                .font(.system(size: 32))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite & Earn")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text("Give $5, Get $5 in Bill Credits")
                    .font(.system(size: 13))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()

            // Button
            NavigationLink(destination: InviteScreen()) {
                HStack(spacing: 5) {
                    Text("Share")
                        .font(.system(size: 14, weight: .semibold))

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.billixLoginTeal)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.billixStarGold.opacity(0.10))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixStarGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

// MARK: - Preview

#Preview {
    TodayView()
}
