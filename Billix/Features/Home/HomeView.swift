//
//  HomeView.swift
//  Billix
//
//  The "Today" Dashboard - Everything above the fold answers:
//  "What should I do with my money today in under 60 seconds?"
//

import SwiftUI

// MARK: - Notification Name Extension

extension NSNotification.Name {
    static let navigateToTab = NSNotification.Name("navigateToTab")
}

// MARK: - Theme

private enum Theme {
    // Colors - Softer, calmer palette
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)

    // Semantic colors - Muted versions
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let danger = Color(hex: "#E07A6B")
    static let info = Color(hex: "#5BA4D4")
    static let purple = Color(hex: "#9B7EB8")

    // Spacing - More breathing room
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    // Shadow - Subtler
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8
}

// MARK: - Card Modifier

private struct CardStyle: ViewModifier {
    var hasShadow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(
                color: hasShadow ? Theme.shadowColor : .clear,
                radius: hasShadow ? Theme.shadowRadius : 0,
                x: 0, y: 2
            )
    }
}

private extension View {
    func cardStyle(shadow: Bool = true) -> some View {
        modifier(CardStyle(hasShadow: shadow))
    }

    func sectionHeader() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Theme.secondaryText)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Haptic Helper

private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

// MARK: - Home View

struct HomeView: View {
    // Set to true to show the Accessible Routing Demo for screenshots
    @State private var showRoutingDemo = false

    // Real user data from AuthService
    @StateObject private var authService = AuthService.shared
    @StateObject private var streakService = StreakService.shared

    // First-time setup questions
    @State private var showSetupQuestions = false

    // Computed properties for user data
    private var userName: String {
        // Get first name only from display name
        let fullName = authService.currentUser?.displayName ?? "Friend"
        return fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    private var userZip: String {
        authService.currentUser?.zipCode ?? ""
    }

    private var userCity: String {
        // Format as "City, ST" from billixProfile
        if let profile = authService.currentUser?.billixProfile,
           let city = profile.city,
           let state = profile.state {
            return "\(city), \(state)"
        }
        return authService.currentUser?.zipCode ?? ""
    }

    private var billixScore: Int {
        authService.currentUser?.vault.trustScore ?? 0
    }

    // Real streak from StreakService
    private var streakDays: Int {
        streakService.currentStreak
    }
    @State private var notificationCount = 3

    // Section rotation - show different sections on different days
    private var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var showLearnToLower: Bool {
        // Show Learn to Lower on Tue, Thu, Sat (3, 5, 7)
        [3, 5, 7].contains(dayOfWeek)
    }

    var body: some View {
        regularHomeView
    }

    private var regularHomeView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    // Top section - Header & Search
                    VStack(spacing: Theme.cardSpacing) {
                        HeaderZone(
                            userName: userName,
                            location: userCity,
                            zipCode: userZip,
                            score: billixScore,
                            streak: streakDays,
                            notificationCount: notificationCount
                        )
                    }

                    // Today's Utility News
                    UtilityNewsBanner()

                    // Primary Actions
                    QuickActionsZone()

                    // Your Bills (with empty state if no bills)
                    BillsListZone()

                    // Market Context - National Averages
                    BillTickerZone(zipCode: userZip)

                    // 30-Second Utility Checkup (Regional Signals)
                    UtilityCheckupZone()

                    // Weather-Based Utility Insight
                    UtilityInsightZone(zipCode: userZip)

                    // Education (Contextual - rotates)
                    if showLearnToLower {
                        LearnToLowerZone()
                    }

                    // Invite & Earn (Referral System)
                    InviteEarnBannerNew()

                    // Emotional Closure - Permission to relax
                    AllClearBanner()

                    Spacer().frame(height: 100)
                }
                .padding(.top, 12)
            }
            .refreshable {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                // Refresh streak on pull-to-refresh
                try? await streakService.fetchStreak()
            }
            .task {
                // Load streak and record activity when view appears
                do {
                    try await streakService.recordActivity()
                } catch {
                    print("❌ Error recording streak activity: \(error)")
                }
            }
            .onAppear {
                // Show setup questions for first-time users
                if let user = authService.currentUser, user.needsHomeSetup {
                    // Delay slightly to let the main view settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSetupQuestions = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showSetupQuestions) {
                HomeSetupQuestionsView()
            }
        }
    }
}

// MARK: - All Clear Banner (Emotional Closure)

private struct AllClearBanner: View {
    // Mock data - would come from real bill status
    private let hasUrgentItems = false
    private let nextActionDays = 5  // Days until next important action

    private var hour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var isEvening: Bool {
        hour >= 18 || hour < 6
    }

    private var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var isWeekend: Bool {
        dayOfWeek == 1 || dayOfWeek == 7
    }

    // Dynamic message based on context
    private var closureMessage: String {
        if hasUrgentItems {
            return "You have \(nextActionDays) day\(nextActionDays == 1 ? "" : "s") until your next action."
        } else if isWeekend {
            return "You handled everything that could impact you this week."
        } else if isEvening {
            return "You're all set — nothing urgent right now."
        } else {
            return "Everything's on track. We'll alert you if anything changes."
        }
    }

    private var closureIcon: String {
        if hasUrgentItems {
            return "clock.fill"
        } else if isWeekend {
            return "checkmark.seal.fill"
        } else {
            return "checkmark.shield.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: closureIcon)
                .font(.system(size: 18))
                .foregroundColor(Theme.success)

            // Message
            Text(closureMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.secondaryText)

            Spacer()

            // Subtle trust indicator
            HStack(spacing: 4) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 11))
                Text("Alerts on")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Theme.accent.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Theme.success.opacity(0.06), Theme.accent.opacity(0.04)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.success.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Utility News Banner (Today's News)

private struct UtilityNewsBanner: View {
    @StateObject private var newsService = UtilityNewsService.shared
    @State private var isExpanded = false

    var body: some View {
        Button {
            haptic()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(spacing: 0) {
                // Main banner (always visible)
                HStack(alignment: .top, spacing: 12) {
                    // News icon
                    ZStack {
                        Circle()
                            .fill(Color.billixMoneyGreen.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "newspaper.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.billixMoneyGreen)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S UTILITY NEWS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#8B9A94"))
                            .tracking(0.5)

                        if let news = newsService.todaysNews {
                            Text(news.headline)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "#2D3B35"))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            if let source = news.sourceName {
                                Text("Source: \(source)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#5B8A6B"))
                            }
                        } else if newsService.isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading today's news...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#8B9A94"))
                            }
                        } else {
                            Text("Tap to load news")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
                .padding(16)

                // Expanded content
                if isExpanded, let news = newsService.todaysNews {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()

                        Text(news.summary)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#5D6D66"))
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)

                        // Category badge and source link
                        HStack(spacing: 8) {
                            categoryBadge(news.category, icon: news.categoryIcon)

                            if let region = news.region, region != "national" {
                                Text(region.capitalized)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "#8B9A94"))
                            }

                            Spacer()

                            if let urlString = news.sourceUrl,
                               let url = URL(string: urlString) {
                                Link(destination: url) {
                                    Text("Read more →")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.billixMoneyGreen)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            await newsService.fetchTodaysNews()
        }
    }

    @ViewBuilder
    private func categoryBadge(_ category: String, icon: String) -> some View {
        let color = categoryColor(category)
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(category.capitalized)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }

    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "rates": return Color(hex: "#F59E0B")
        case "policy": return Color(hex: "#3B82F6")
        case "industry": return Color(hex: "#8B5CF6")
        default: return Color(hex: "#5B8A6B")
        }
    }
}

// MARK: - Zone A: Header

private struct HeaderZone: View {
    let userName: String
    let location: String
    let zipCode: String
    let score: Int
    let streak: Int
    let notificationCount: Int

    @State private var showNotifications = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var scoreLabel: String {
        switch score {
        case 750...: return "Excellent"
        case 700..<750: return "Very Efficient"
        case 650..<700: return "Good"
        default: return "Needs Work"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting), \(userName)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Button {
                        haptic()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("\(location) \(zipCode)")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                    }
                }

                Spacer()

                Button {
                    haptic()
                    showNotifications = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.cardBackground)
                            .frame(width: 40, height: 40)
                            .shadow(color: Theme.shadowColor, radius: 4)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.accent)

                        if notificationCount > 0 {
                            Text("\(notificationCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Theme.danger)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                // Score chip with social ranking
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accent)
                        Text("\(score)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText)
                        Text("· \(scoreLabel)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                    }

                    // Social ranking micro-label
                    Text("Top 18% in \(zipCode)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .cornerRadius(14)
                .shadow(color: Theme.shadowColor, radius: 4)

                // Streak chip
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    Text("\(streak) Day Streak")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Theme.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#FEF3E2"))
                .cornerRadius(20)

                Spacer()
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
    }
}

// MARK: - Notifications Sheet

private struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let notifications = [
        NotificationItem(
            icon: "bolt.fill",
            iconColor: Color(hex: "#E8A54B"),
            title: "Electric bill is due soon",
            subtitle: "DTE Energy · Due in 3 days",
            time: "2h ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "arrow.down.circle.fill",
            iconColor: Color(hex: "#4CAF7A"),
            title: "You saved $23 this month!",
            subtitle: "Your negotiation with Xfinity worked",
            time: "1d ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "person.2.fill",
            iconColor: Color(hex: "#9B7EB8"),
            title: "New swap partner available",
            subtitle: "Sarah M. wants to swap bills",
            time: "2d ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "star.fill",
            iconColor: Color(hex: "#5BA4D4"),
            title: "Achievement unlocked!",
            subtitle: "You earned the 'Budget Master' badge",
            time: "3d ago",
            isUnread: false
        ),
        NotificationItem(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: Color(hex: "#5B8A6B"),
            title: "Your Billix Score increased",
            subtitle: "Up 12 points to 742",
            time: "5d ago",
            isUnread: false
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                        if notification.id != notifications.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding()
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Mark all read") {
                        haptic()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
    }
}

private struct NotificationItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    let isUnread: Bool
}

private struct NotificationRow: View {
    let notification: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: notification.icon)
                    .font(.system(size: 16))
                    .foregroundColor(notification.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 15, weight: notification.isUnread ? .semibold : .regular))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Spacer()

                    if notification.isUnread {
                        Circle()
                            .fill(Color(hex: "#5B8A6B"))
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Text(notification.time)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94").opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(notification.isUnread ? Color(hex: "#5B8A6B").opacity(0.03) : Color.clear)
    }
}

// MARK: - Quick Actions

private enum QuickActionType: String, Identifiable {
    case addBill = "Add Bill"
    case chat = "Chat"
    case compare = "Swap"
    case budget = "Budget"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .addBill: return "plus.circle.fill"
        case .chat: return "message.fill"
        case .compare: return "arrow.left.arrow.right.circle.fill"
        case .budget: return "chart.pie.fill"
        }
    }

    var color: Color {
        switch self {
        case .addBill: return Theme.accent
        case .chat: return Theme.info
        case .compare: return Theme.purple
        case .budget: return Theme.warning
        }
    }

    var subtitle: String? {
        switch self {
        case .compare: return "Bill Swap"
        default: return nil
        }
    }
}

private struct QuickActionsZone: View {
    @State private var showSwapHub = false
    @State private var showAddBill = false
    @State private var showChat = false
    @State private var showBudget = false

    private let actions: [QuickActionType] = [.addBill, .chat, .compare, .budget]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions) { action in
                Button {
                    haptic()
                    handleAction(action)
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(action.color.opacity(0.12))
                                .frame(width: 52, height: 52)

                            Image(systemName: action.icon)
                                .font(.system(size: 22))
                                .foregroundColor(action.color)
                        }

                        VStack(spacing: 2) {
                            Text(action.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.primaryText)

                            if let subtitle = action.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(action.color)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(14)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
        .padding(.horizontal, Theme.horizontalPadding)
        .fullScreenCover(isPresented: $showSwapHub) {
            BillSwapView()
        }
        .sheet(isPresented: $showAddBill) {
            AddBillActionSheet()
        }
        .sheet(isPresented: $showChat) {
            ChatHubView()
        }
        .sheet(isPresented: $showBudget) {
            BudgetOverviewView()
        }
    }

    private func handleAction(_ action: QuickActionType) {
        switch action {
        case .compare:
            showSwapHub = true
        case .addBill:
            showAddBill = true
        case .chat:
            showChat = true
        case .budget:
            showBudget = true
        }
    }
}

// MARK: - Upcoming Estimates (AI-Generated Regional Predictions)

private struct UpcomingEstimatesZone: View {
    let zipCode: String

    @State private var estimates: [UpcomingEstimate] = []
    @State private var isLoading = true

    @StateObject private var weatherService = WeatherService.shared
    private let openAIService = OpenAIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.info)
                Text("Upcoming").sectionHeader()

                Spacer()

                Text("Next 30 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }

            // Estimates list
            VStack(spacing: 0) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 30)
                        Spacer()
                    }
                } else if estimates.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryText.opacity(0.5))
                        Text("Predictions loading...")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(estimates.enumerated()), id: \.offset) { index, estimate in
                        UpcomingEstimateRow(estimate: estimate)

                        if index < estimates.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .padding(14)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)

            // Footer
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Based on regional patterns for \(zipCode)")
                    .font(.system(size: 11))
            }
            .foregroundColor(Theme.secondaryText.opacity(0.7))
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            await loadEstimates()
        }
    }

    @MainActor
    private func loadEstimates() async {
        isLoading = true

        // Get weather data
        let weather = weatherService.currentWeather

        do {
            estimates = try await openAIService.generateUpcomingEstimates(
                zipCode: zipCode,
                city: weather?.cityName,
                state: nil, // Could be extracted from ZIP
                temperature: weather?.temperature,
                weatherCondition: weather?.condition,
                weatherForecast: nil, // Could add 5-day forecast
                billCategories: ["Electric", "Gas", "Internet", "Water"]
            )
        } catch {
            print("❌ Failed to load upcoming estimates: \(error)")
            // Fallback estimates are returned by the service
        }

        isLoading = false
    }
}

private struct UpcomingEstimateRow: View {
    let estimate: UpcomingEstimate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: estimate.icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.info)
                .frame(width: 36, height: 36)
                .background(Theme.info.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(2)
                Text(estimate.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}


// MARK: - Achievement Badges (Tied to Real Capabilities)

private struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let isUnlocked: Bool
    let capability: String       // What capability this unlocks
    let capabilityIcon: String
    let benefit: String          // Concrete benefit description
    let progress: Double?        // Progress toward unlock (0-1), nil if unlocked
}

private struct AchievementBadgesZone: View {
    @State private var selectedAchievement: Achievement? = nil

    private let achievements = [
        Achievement(
            icon: "star.fill",
            title: "First Bill",
            color: Theme.warning,
            isUnlocked: true,
            capability: "AI Bill Analysis",
            capabilityIcon: "brain.head.profile",
            benefit: "Get personalized savings recommendations on every bill",
            progress: nil
        ),
        Achievement(
            icon: "flame.fill",
            title: "7-Day Streak",
            color: Theme.danger,
            isUnlocked: true,
            capability: "Premium Forecast",
            capabilityIcon: "chart.line.uptrend.xyaxis",
            benefit: "Unlock 30-day bill predictions and spike alerts",
            progress: nil
        ),
        Achievement(
            icon: "dollarsign.circle.fill",
            title: "$100 Saved",
            color: Theme.success,
            isUnlocked: true,
            capability: "Boosted Flash Drops",
            capabilityIcon: "bolt.shield.fill",
            benefit: "Get 2x points on all Flash Drop offers",
            progress: nil
        ),
        Achievement(
            icon: "person.2.fill",
            title: "Referral Pro",
            color: Theme.purple,
            isUnlocked: false,
            capability: "Early Access",
            capabilityIcon: "clock.badge.checkmark.fill",
            benefit: "See Flash Drops 24 hours before everyone else",
            progress: 0.4  // 2 of 5 referrals
        ),
        Achievement(
            icon: "crown.fill",
            title: "Bill Master",
            color: Theme.info,
            isUnlocked: false,
            capability: "1-on-1 Coach Session",
            capabilityIcon: "person.crop.circle.badge.checkmark",
            benefit: "Free 30-min call with a bill negotiation expert",
            progress: 0.65  // 65% to Bill Master
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.warning)
                    Text("Achievements").sectionHeader()
                }
                Spacer()

                // Progress indicator with what's next
                HStack(spacing: 6) {
                    Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.primaryText)

                    if let nextAchievement = achievements.first(where: { !$0.isUnlocked }) {
                        Text("· Next: \(nextAchievement.title)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isSelected: selectedAchievement?.id == achievement.id,
                            onTap: {
                                haptic()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedAchievement?.id == achievement.id {
                                        selectedAchievement = nil
                                    } else {
                                        selectedAchievement = achievement
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }

            // Show selected achievement details
            if let selected = selectedAchievement {
                AchievementDetailCard(achievement: selected)
                    .padding(.horizontal, Theme.horizontalPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(achievement.color, lineWidth: 2)
                            .frame(width: 62, height: 62)
                    }

                    Circle()
                        .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 24))
                        .foregroundColor(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.4))

                    // Checkmark for unlocked
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.success)
                            .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                            .offset(x: 18, y: 18)
                    } else {
                        // Lock for locked
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .offset(x: 18, y: 18)
                    }
                }

                VStack(spacing: 2) {
                    Text(achievement.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(achievement.isUnlocked ? Theme.primaryText : Theme.secondaryText)
                        .lineLimit(1)

                    // Mini unlock hint
                    if achievement.isUnlocked {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                            Text("Active")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundColor(Theme.success)
                    }
                }
            }
            .frame(width: 75)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct AchievementDetailCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 22))
                        .foregroundColor(achievement.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.primaryText)

                        // Status badge
                        if achievement.isUnlocked {
                            Text("UNLOCKED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Theme.success)
                                .cornerRadius(4)
                        }
                    }

                    // Progress bar for locked achievements
                    if !achievement.isUnlocked, let progress = achievement.progress {
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(achievement.color)
                                        .frame(width: geo.size.width * progress, height: 6)
                                }
                            }
                            .frame(height: 6)

                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(achievement.color)
                        }
                    }
                }

                Spacer()
            }

            // Capability unlock section
            HStack(spacing: 12) {
                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? Theme.success : Theme.secondaryText)

                // Capability info
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(achievement.isUnlocked ? Theme.success.opacity(0.1) : Color.gray.opacity(0.08))
                        .frame(width: 36, height: 36)

                    Image(systemName: achievement.capabilityIcon)
                        .font(.system(size: 16))
                        .foregroundColor(achievement.isUnlocked ? Theme.success : Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.capability)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(achievement.isUnlocked ? Theme.success : Theme.primaryText)

                    Text(achievement.benefit)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(achievement.isUnlocked ? Theme.success.opacity(0.06) : Color.gray.opacity(0.04))
            .cornerRadius(12)
        }
        .padding(14)
        .background(Theme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(achievement.isUnlocked ? Theme.success.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Theme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Weather-Based Tip (AI-Powered with Real Weather)

private struct WeatherTipZone: View {
    let zipCode: String

    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var openAIService = OpenAIService.shared
    @State private var isExpanded = false
    @State private var aiTip: String?
    @State private var isLoadingTip = false

    private var weatherIcon: String {
        weatherService.getWeatherIcon()
    }

    private var temperature: Int {
        weatherService.currentWeather?.temperatureInt ?? 72
    }

    private var cityName: String {
        weatherService.currentWeather?.cityName ?? ""
    }

    private var condition: String {
        weatherService.currentWeather?.condition ?? "Clear"
    }

    private var defaultTip: String {
        weatherService.getWeatherBasedTip() ?? "Check your bills to find savings opportunities"
    }

    private var displayTip: String {
        aiTip ?? defaultTip
    }

    private var gradientColors: [Color] {
        if temperature >= 85 {
            return [Color.orange, Color.yellow]
        } else if temperature <= 40 {
            return [Color.blue, Color.cyan]
        } else {
            return [Theme.accent, Theme.success]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main tip card
            Button {
                haptic()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: weatherIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if weatherService.isLoading {
                                Text("Loading...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.secondaryText)
                            } else {
                                Text("\(temperature)°F Today")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.primaryText)
                                if !cityName.isEmpty {
                                    Text("· \(cityName)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryText)
                                }
                            }
                        }

                        if isLoadingTip {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating tip...")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryText)
                            }
                        } else {
                            Text(displayTip)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryText)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [gradientColors[0].opacity(0.08), gradientColors[1].opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Expanded explanation
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(gradientColors[0].opacity(0.2))

                    AIExplanationRow(
                        icon: "sparkles",
                        title: "AI-Powered Tip",
                        explanation: "This tip is personalized based on your location's weather and typical bill patterns.",
                        color: Theme.purple
                    )

                    if let weather = weatherService.currentWeather {
                        AIExplanationRow(
                            icon: "thermometer.medium",
                            title: "Current Conditions",
                            explanation: "\(weather.condition) with \(weather.humidity)% humidity. Feels like \(weather.feelsLikeInt)°F.",
                            color: Theme.info
                        )
                    }
                }
                .padding(14)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(gradientColors[0].opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            // Fetch weather on appear
            guard !zipCode.isEmpty else { return }
            do {
                try await weatherService.fetchWeather(zipCode: zipCode)

                // Generate AI tip if weather is available
                if let weather = weatherService.currentWeather {
                    isLoadingTip = true
                    do {
                        aiTip = try await openAIService.generateWeatherTip(
                            temperature: weather.temperature,
                            condition: weather.condition,
                            zipCode: zipCode,
                            city: weather.cityName,
                            billTypes: ["Electric", "Gas"]
                        )
                    } catch {
                        print("❌ Failed to generate AI tip: \(error)")
                    }
                    isLoadingTip = false
                }
            } catch {
                print("❌ Failed to fetch weather: \(error)")
            }
        }
    }
}

private struct AIExplanationRow: View {
    let icon: String
    let title: String
    let explanation: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                Text(explanation)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.secondaryText)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Zone B: Bill Ticker

private struct TickerItem: Identifiable {
    let id = UUID()
    let icon: String
    let category: String
    let value: String
    let change: String
    let isUp: Bool
}

private struct BillTickerZone: View {
    let zipCode: String

    @StateObject private var openAIService = OpenAIService.shared
    @State private var averages: [BillAverage] = []
    @State private var isLoading = true

    // Fallback data while loading
    private var displayItems: [TickerItem] {
        if averages.isEmpty {
            return [
                TickerItem(icon: "bolt.fill", category: "Electric", value: "$142", change: "avg", isUp: false),
                TickerItem(icon: "wifi", category: "Internet", value: "$65", change: "avg", isUp: false),
                TickerItem(icon: "flame.fill", category: "Gas", value: "$78", change: "avg", isUp: false),
                TickerItem(icon: "iphone", category: "Phone", value: "$85", change: "avg", isUp: false),
            ]
        }

        return averages.map { avg in
            let icon: String
            switch avg.billType.lowercased() {
            case "electric": icon = "bolt.fill"
            case "internet": icon = "wifi"
            case "gas": icon = "flame.fill"
            case "phone": icon = "iphone"
            default: icon = "dollarsign.circle.fill"
            }

            return TickerItem(
                icon: icon,
                category: avg.billType,
                value: "$\(Int(avg.average))",
                change: "avg",
                isUp: false
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.info)
                    Text("National Averages")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                if !zipCode.isEmpty {
                    Text("for \(zipCode)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            // Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayItems) { item in
                        NationalAverageCard(item: item, isLoading: isLoading && averages.isEmpty)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
        }
        .task {
            guard !zipCode.isEmpty else { return }
            do {
                averages = try await openAIService.getNationalAverages(zipCode: zipCode)
                isLoading = false
            } catch {
                print("❌ Failed to load national averages: \(error)")
                isLoading = false
            }
        }
    }
}

private struct NationalAverageCard: View {
    let item: TickerItem
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .frame(width: 32, height: 32)
                    .background(Theme.accentLight)
                    .cornerRadius(8)

                Text(item.category)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                if isLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.secondaryText.opacity(0.2))
                        .frame(width: 60, height: 20)
                } else {
                    Text(item.value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                }

                Text("/month")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }

            // User comparison placeholder
            HStack(spacing: 4) {
                Text("You: ---")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(width: 110)
        .padding(12)
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
    }
}

private struct TickerCard: View {
    let item: TickerItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Theme.accentLight)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                HStack(spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                    Text(item.change)
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: item.isUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(item.isUp ? Theme.danger : Theme.success)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Zone C: Micro Tasks (30-Second Checkup)

private struct MicroTask: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let points: Int
    var isCompleted: Bool = false
}

private struct MicroTasksZone: View {
    @State private var completedCount = 0
    @State private var tasks = [
        MicroTask(icon: "checkmark.circle.fill", color: Theme.info, title: "Verify Transactions", subtitle: "Swipe 3 to confirm", points: 10),
        MicroTask(icon: "hand.thumbsup.fill", color: Theme.purple, title: "Daily Vote", subtitle: "Is $65 too much for 500Mbps?", points: 5),
    ]

    private var streakSafe: Bool {
        completedCount >= 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with progress
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.info)
                    Text("30-Second Checkup").sectionHeader()
                }

                Spacer()

                // Progress indicator
                HStack(spacing: 4) {
                    Text("\(completedCount) / 2 done")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(streakSafe ? Theme.success : Theme.secondaryText)

                    if streakSafe {
                        Text("— streak safe")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.success)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.warning)
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            // Two task cards side by side
            HStack(spacing: 12) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    MicroTaskCard(task: task) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tasks[index].isCompleted = true
                            completedCount = min(completedCount + 1, 2)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
        }
    }
}

private struct MicroTaskCard: View {
    let task: MicroTask
    let onComplete: () -> Void

    var body: some View {
        Button {
            haptic()
            if !task.isCompleted {
                onComplete()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(task.isCompleted ? Theme.success.opacity(0.15) : task.color.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : task.icon)
                            .font(.system(size: 18))
                            .foregroundColor(task.isCompleted ? Theme.success : task.color)
                    }

                    Spacer()

                    if task.isCompleted {
                        Text("Done")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.success.opacity(0.15))
                            .cornerRadius(8)
                    } else {
                        Text("+\(task.points) pts")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(task.color)
                            .cornerRadius(8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(task.isCompleted ? Theme.secondaryText : Theme.primaryText)
                        .strikethrough(task.isCompleted)

                    Text(task.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(task.isCompleted ? Color.gray.opacity(0.05) : task.color.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(task.isCompleted ? Theme.success.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(task.isCompleted)
    }
}

// MARK: - Zone F: Daily Bill Brief (AI-Powered)

private struct DailyBillBrief: View {
    let zipCode: String

    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var authService = AuthService.shared
    @State private var aiBrief: String?
    @State private var isLoading = false
    @State private var isExpanded = false

    private var defaultBrief: String {
        "Check your upcoming bills and stay on track with your budget this week."
    }

    private var displayBrief: String {
        aiBrief ?? defaultBrief
    }

    private var briefIcon: String {
        if let weather = weatherService.currentWeather {
            if weather.isHot {
                return "thermometer.sun.fill"
            } else if weather.isCold {
                return "thermometer.snowflake"
            }
        }
        return "newspaper.fill"
    }

    private var briefIconColor: Color {
        if let weather = weatherService.currentWeather {
            if weather.isHot {
                return Theme.danger
            } else if weather.isCold {
                return Theme.info
            }
        }
        return Theme.info
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.purple)
                Text("AI Daily Brief").sectionHeader()

                Spacer()

                if aiBrief != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                        Text("Personalized")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Theme.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.purple.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Button {
                haptic()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: briefIcon)
                                .font(.system(size: 14))
                                .foregroundColor(briefIconColor)
                            Text("Your Daily Update")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.primaryText)

                            Spacer()

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.accent)
                        }

                        if isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating personalized brief...")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryText)
                            }
                        } else {
                            Text(displayBrief)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryText)
                                .lineSpacing(4)
                                .lineLimit(isExpanded ? nil : 2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(Theme.cardPadding)

                    // Expanded content
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            // Context used for brief
                            HStack(spacing: 10) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.accent)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.accentLight)
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Location Context")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Theme.secondaryText)
                                    Text(zipCode.isEmpty ? "Add ZIP code for personalized insights" : "Based on \(zipCode) rates and trends")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.primaryText)
                                }
                            }

                            if let weather = weatherService.currentWeather {
                                HStack(spacing: 10) {
                                    Image(systemName: weatherService.getWeatherIcon())
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.info)
                                        .frame(width: 24, height: 24)
                                        .background(Theme.info.opacity(0.12))
                                        .cornerRadius(6)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Weather Factor")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Theme.secondaryText)
                                        Text("\(weather.temperatureInt)°F \(weather.condition) in \(weather.cityName)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Theme.primaryText)
                                    }
                                }
                            }

                            // Refresh button
                            Button {
                                haptic()
                                Task {
                                    await generateBrief()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Refresh Brief")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Theme.accent)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, Theme.cardPadding)
                        .padding(.bottom, Theme.cardPadding)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Theme.purple.opacity(0.08), Theme.info.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.purple.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            await generateBrief()
        }
    }

    private func generateBrief() async {
        guard !zipCode.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        // Get user profile data
        let profile = authService.currentUser?.billixProfile
        let city = profile?.city
        let state = profile?.state

        // Get weather data
        let temperature = weatherService.currentWeather?.temperature
        let weatherCondition = weatherService.currentWeather?.condition

        // Get bill types (would come from user's bills in production)
        let billTypes = ["Electric", "Internet", "Gas", "Phone"]

        // Get upcoming bill info (mock for now)
        let upcomingBillName: String? = "Verizon"
        let upcomingBillDays: Int? = 5

        do {
            aiBrief = try await openAIService.generateDailyBrief(
                zipCode: zipCode,
                city: city,
                state: state,
                temperature: temperature,
                weatherCondition: weatherCondition,
                billTypes: billTypes,
                upcomingBillName: upcomingBillName,
                upcomingBillDays: upcomingBillDays
            )
        } catch {
            print("❌ Failed to generate AI brief: \(error)")
        }
    }
}

// MARK: - Zone G: Community Poll (Enhanced with Social Comparison)

private struct CommunityPollZone: View {
    @State private var hasVoted = false
    @State private var selectedOption: Int? = nil

    private let percentAgree = 73
    private let userPercentile = 61 // User is better than 61% of users
    private let userAmount = 110
    private let pollAmount = 120
    private let voterCount = 1247

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.purple)
                Text("Community Poll").sectionHeader()

                Spacer()

                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 6, height: 6)
                    Text("\(voterCount) votes")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                // Question
                Text("Is $\(pollAmount) for car insurance too high?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.primaryText)

                // Vote buttons or results
                if hasVoted {
                    // Show results after voting
                    VStack(spacing: 10) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#E8E8E8"))
                                    .frame(height: 32)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.purple, Theme.purple.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(percentAgree) / 100, height: 32)

                                HStack {
                                    Text("\(percentAgree)% say YES")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: 32)

                        // Social comparison badge
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.success.opacity(0.12))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.success)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("You're better than \(userPercentile)% of users")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.success)
                                }

                                HStack(spacing: 4) {
                                    Text("You pay $\(userAmount)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.primaryText)
                                    Text("· $\(pollAmount - userAmount) below avg")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.secondaryText)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(12)
                        .background(Theme.success.opacity(0.08))
                        .cornerRadius(12)
                    }
                } else {
                    // Vote buttons
                    HStack(spacing: 12) {
                        PollVoteButton(
                            title: "Yes, too high",
                            icon: "hand.thumbsup.fill",
                            color: Theme.purple,
                            isSelected: selectedOption == 0
                        ) {
                            haptic()
                            selectedOption = 0
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                hasVoted = true
                            }
                        }

                        PollVoteButton(
                            title: "No, fair price",
                            icon: "hand.thumbsdown.fill",
                            color: Theme.secondaryText,
                            isSelected: selectedOption == 1
                        ) {
                            haptic()
                            selectedOption = 1
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                hasVoted = true
                            }
                        }
                    }

                    // Teaser text
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10))
                        Text("Vote to see how you compare")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.purple)
                }
            }
            .padding(Theme.cardPadding)
            .background(Theme.purple.opacity(0.08))
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.purple.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

private struct PollVoteButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone H: Your Bills (With Empty State & ZIP Comparison)

// Helper functions for bill display
private func billIcon(for category: String) -> String {
    switch category.lowercased() {
    case "electric", "electricity": return "bolt.fill"
    case "gas", "natural gas": return "flame.fill"
    case "water": return "drop.fill"
    case "internet", "wifi": return "wifi"
    case "phone", "mobile", "cell": return "phone.fill"
    case "cable", "tv", "streaming": return "tv.fill"
    case "insurance": return "shield.fill"
    case "rent", "mortgage": return "house.fill"
    default: return "doc.text.fill"
    }
}

private func billIconColor(for category: String) -> Color {
    switch category.lowercased() {
    case "electric", "electricity": return .yellow
    case "gas", "natural gas": return .orange
    case "water": return .blue
    case "internet", "wifi": return .purple
    case "phone", "mobile", "cell": return .green
    case "cable", "tv", "streaming": return .red
    case "insurance": return .indigo
    case "rent", "mortgage": return .brown
    default: return Theme.accent
    }
}

private func daysUntilDue(dueDay: Int) -> Int {
    let calendar = Calendar.current
    let today = Date()
    let currentDay = calendar.component(.day, from: today)

    if dueDay >= currentDay {
        return dueDay - currentDay
    } else {
        // Due date is next month
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count else {
            return dueDay
        }
        return (daysInMonth - currentDay) + dueDay
    }
}

private struct BillsListZone: View {
    @State private var bills: [UserBill] = []
    @State private var zipAverages: [BillAverage] = []
    @State private var isLoading = true
    @State private var hasNoBills = false

    private let openAIService = OpenAIService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.accent)
                Text("Your Bills").sectionHeader()

                Spacer()

                if !hasNoBills && !bills.isEmpty {
                    Button {
                        haptic()
                        // Navigate to upload to add bill
                        NotificationCenter.default.post(
                            name: .navigateToTab,
                            object: nil,
                            userInfo: ["tabIndex": 2]
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add Bill")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.accent)
                    }
                }
            }

            if isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 40)
                    Spacer()
                }
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
            } else if hasNoBills || bills.isEmpty {
                // Empty state - prompt to upload
                BillsEmptyState()
            } else {
                // Bills list with insights
                VStack(spacing: 0) {
                    ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                        BillListRow(
                            bill: bill,
                            zipAverage: getZipAverage(for: bill.billCategory)
                        )

                        if index < bills.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            await loadBills()
        }
    }

    private func getZipAverage(for category: String) -> BillAverage? {
        zipAverages.first { $0.billType.lowercased() == category.lowercased() }
    }

    @MainActor
    private func loadBills() async {
        isLoading = true

        // TODO: Fetch real bills from Supabase
        // For now, simulate checking if user has bills
        // In real implementation:
        // let response = try await supabase.from("bills").select()...

        // Simulate empty state for demo
        // When real data is connected, this will fetch from bills table
        bills = []
        hasNoBills = true

        // Fetch ZIP averages for comparison
        do {
            // Use a default ZIP for now - in real app, get from user profile
            zipAverages = try await openAIService.getNationalAverages(zipCode: "07060")
        } catch {
            print("❌ Failed to load ZIP averages: \(error)")
        }

        isLoading = false
    }
}

private struct BillsEmptyState: View {
    var body: some View {
        Button {
            haptic()
            // Navigate to Upload tab
            NotificationCenter.default.post(
                name: .navigateToTab,
                object: nil,
                userInfo: ["tabIndex": 2]
            )
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.accent)
                }

                VStack(spacing: 6) {
                    Text("Upload your first bill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.primaryText)

                    Text("Get insights, find savings,\nand track your spending")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Text("Upload Bill")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .cornerRadius(12)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

private struct BillListRow: View {
    let bill: UserBill
    let zipAverage: BillAverage?

    private var iconName: String {
        billIcon(for: bill.billCategory)
    }

    private var iconColor: Color {
        billIconColor(for: bill.billCategory)
    }

    private var daysToDue: Int {
        daysUntilDue(dueDay: bill.dueDay)
    }

    var body: some View {
        Button {
            haptic()
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                // Bill info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(bill.providerName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.primaryText)

                        // Due date badge
                        if daysToDue <= 7 {
                            Text("Due in \(daysToDue)d")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.danger)
                                .cornerRadius(4)
                        }
                    }

                    // ZIP comparison insight
                    HStack(spacing: 4) {
                        if let avg = zipAverage {
                            let diff = bill.typicalAmount - avg.average
                            if abs(diff) < 5 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                Text("On par with ZIP average")
                                    .font(.system(size: 11, weight: .medium))
                            } else if diff > 0 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 9))
                                Text("$\(Int(diff)) above ZIP avg")
                                    .font(.system(size: 11, weight: .medium))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 9))
                                Text("$\(Int(abs(diff))) below ZIP avg")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }
                    .foregroundColor(zipComparisonColor)
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", bill.typicalAmount))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text("/mo")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var zipComparisonColor: Color {
        guard let avg = zipAverage else { return Theme.secondaryText }
        let diff = bill.typicalAmount - avg.average
        if abs(diff) < 5 {
            return Theme.success
        } else if diff > 0 {
            return Theme.warning
        } else {
            return Theme.success
        }
    }
}

// MARK: - Zone I: Learn to Lower (Interactive Bill Coach)
// TODO: Re-enable after adding BillCoachModels.swift and BillCoachFlowView.swift to Xcode target

/*
private struct LearnToLowerZone: View {
    @State private var selectedTopic: CoachingTopic?

    // Map topics to display
    private let displayTopics: [CoachingTopic] = [
        .negotiateInternet,
        .cancelGym,
        .lowerInsurance
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.success)
                Text("How to Lower").sectionHeader()
                Spacer()
                Text("Interactive guides")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, Theme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayTopics) { topic in
                        PlaybookCard(
                            topic: topic,
                            onTap: {
                                haptic(.medium)
                                selectedTopic = topic
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
        }
        .fullScreenCover(item: $selectedTopic) { topic in
            BillCoachFlowView(topic: topic)
        }
    }
}

private struct PlaybookCard: View {
    let topic: CoachingTopic
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon with glow effect
                ZStack {
                    Circle()
                        .fill(topic.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: topic.icon)
                        .font(.system(size: 22))
                        .foregroundColor(topic.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Savings potential
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.success)
                        Text(topic.potentialSavings)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.success)
                    }

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(topic.estimatedDuration)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Theme.secondaryText)
                }

                // Start indicator
                HStack(spacing: 4) {
                    Text("Start")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(topic.color)
            }
            .padding(14)
            .frame(width: 140)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(topic.color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
*/

// MARK: - Zone J: Invite & Earn

private struct InviteEarnBanner: View {
    var body: some View {
        Button { haptic(.medium) } label: {
            HStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Give $5, Get $5")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                    Text("Invite friends to verify their bills")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.purple)
            }
            .padding(Theme.cardPadding)
            .background(
                LinearGradient(
                    colors: [Theme.purple.opacity(0.1), Theme.purple.opacity(0.15)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
