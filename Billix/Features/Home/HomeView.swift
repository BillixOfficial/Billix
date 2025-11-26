//
//  HomeView.swift
//  Billix
//
//  The "Today" Dashboard - Everything above the fold answers:
//  "What should I do with my money today in under 60 seconds?"
//

import SwiftUI

// MARK: - Theme

private enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "#F5F7F6")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#1A2421")
    static let secondaryText = Color(hex: "#6B7B75")
    static let tertiaryText = Color(hex: "#9BA8A2")
    static let accent = Color(hex: "#4A7C59")
    static let accentLight = Color(hex: "#4A7C59").opacity(0.08)

    // Semantic colors
    static let success = Color(hex: "#3D9A6E")
    static let warning = Color(hex: "#E09D3D")
    static let danger = Color(hex: "#D66B5B")
    static let info = Color(hex: "#4A9BD9")
    static let purple = Color(hex: "#8B6CAF")

    // MARK: - Typography Scale
    enum Font {
        static let largeTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = SwiftUI.Font.system(size: 22, weight: .bold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 15, weight: .regular)
        static let callout = SwiftUI.Font.system(size: 14, weight: .medium)
        static let caption = SwiftUI.Font.system(size: 12, weight: .medium)
        static let micro = SwiftUI.Font.system(size: 11, weight: .medium)
    }

    // MARK: - Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 28
    static let cardSpacing: CGFloat = 14
    static let cornerRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12

    // MARK: - Shadows (Layered for depth)
    static let shadowColor = Color.black.opacity(0.04)
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4

    // Secondary shadow for layered effect
    static let shadowColorLight = Color.black.opacity(0.02)
    static let shadowRadiusLight: CGFloat = 20

    // MARK: - Animation
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Card Modifier

private struct CardStyle: ViewModifier {
    var hasShadow: Bool = true
    var padding: CGFloat = Theme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
                    .shadow(
                        color: hasShadow ? Theme.shadowColorLight : .clear,
                        radius: hasShadow ? Theme.shadowRadiusLight : 0,
                        x: 0, y: 8
                    )
                    .shadow(
                        color: hasShadow ? Theme.shadowColor : .clear,
                        radius: hasShadow ? Theme.shadowRadius : 0,
                        x: 0, y: Theme.shadowY
                    )
            )
    }
}

// MARK: - Animated Card Modifier

private struct AnimatedCardStyle: ViewModifier {
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .onAppear {
                withAnimation(Theme.Animation.spring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Subtle Glow Modifier

private struct SubtleGlow: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(color.opacity(0.08))
                    .blur(radius: 8)
                    .offset(y: 4)
            )
    }
}

private extension View {
    func cardStyle(shadow: Bool = true, padding: CGFloat = Theme.cardPadding) -> some View {
        modifier(CardStyle(hasShadow: shadow, padding: padding))
    }

    func animatedCard(delay: Double = 0) -> some View {
        modifier(AnimatedCardStyle(delay: delay))
    }

    func subtleGlow(_ color: Color) -> some View {
        modifier(SubtleGlow(color: color))
    }

    func sectionHeader() -> some View {
        self
            .font(Theme.Font.caption)
            .foregroundColor(Theme.secondaryText)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

// MARK: - Haptic Helper

private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

// MARK: - Home View

struct HomeView: View {
    @State private var userName = "David"
    @State private var userZip = "48067"
    @State private var userCity = "Royal Oak, MI"
    @State private var billixScore = 742
    @State private var streakDays = 6
    @State private var searchText = ""
    @State private var notificationCount = 3
    @State private var savingsGoal = 500.0
    @State private var currentSavings = 127.0

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Theme.background,
                    Theme.background.opacity(0.95),
                    Color(hex: "#EEF2F0")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    // SECTION 1: Context & Status
                    VStack(spacing: Theme.cardSpacing) {
                        HeaderZone(
                            userName: userName,
                            location: userCity,
                            zipCode: userZip,
                            score: billixScore,
                            streak: streakDays,
                            notificationCount: notificationCount
                        )
                        .animatedCard(delay: 0)

                        WeatherTipZone()
                            .animatedCard(delay: 0.05)

                        BillSnapshotZone()
                            .animatedCard(delay: 0.1)
                    }

                    // SECTION 2: Actions
                    VStack(spacing: Theme.cardSpacing) {
                        SearchBarZone(searchText: $searchText)
                            .animatedCard(delay: 0.15)

                        QuickActionsZone()
                            .animatedCard(delay: 0.2)

                        SavingsGoalZone(current: currentSavings, goal: savingsGoal)
                            .animatedCard(delay: 0.25)
                    }

                    // SECTION 3: Engagement
                    VStack(spacing: Theme.cardSpacing) {
                        MicroTasksZone()
                            .animatedCard(delay: 0.3)

                        AchievementBadgesZone()
                            .animatedCard(delay: 0.35)
                    }

                    // SECTION 4: Market Data
                    VStack(spacing: Theme.cardSpacing) {
                        BillTickerZone(zipCode: userZip)
                            .animatedCard(delay: 0.4)

                        FlashDropZone()
                            .animatedCard(delay: 0.45)
                    }

                    // SECTION 5: Discovery
                    VStack(spacing: Theme.cardSpacing) {
                        ClustersTeaser(zipCode: userZip)
                            .animatedCard(delay: 0.5)

                        DailyBillBrief()
                            .animatedCard(delay: 0.55)
                    }

                    // SECTION 6: Community
                    CommunityPollZone()
                        .animatedCard(delay: 0.6)

                    // SECTION 7: Growth
                    VStack(spacing: Theme.cardSpacing) {
                        LearnToLowerZone()
                            .animatedCard(delay: 0.65)

                        InviteEarnBanner()
                            .animatedCard(delay: 0.7)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 16)
            }
            .refreshable {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
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
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(greeting), \(userName)")
                        .font(Theme.Font.title)
                        .foregroundColor(Theme.primaryText)

                    Button {
                        haptic()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10, weight: .medium))
                            Text("\(location) \(zipCode)")
                                .font(Theme.Font.caption)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accentLight)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.96))
                }

                Spacer()

                Button { haptic() } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.cardBackground)
                            .frame(width: 44, height: 44)
                            .shadow(color: Theme.shadowColor, radius: 6, y: 2)
                            .shadow(color: Theme.shadowColorLight, radius: 12, y: 4)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.accent)

                        if notificationCount > 0 {
                            Text("\(notificationCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(Theme.danger)
                                        .shadow(color: Theme.danger.opacity(0.4), radius: 4, y: 2)
                                )
                                .offset(x: 12, y: -12)
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.92))
            }

            HStack(spacing: 10) {
                // Score chip
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text("\(score)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                    Text("· \(scoreLabel)")
                        .font(Theme.Font.caption)
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.cardBackground)
                        .shadow(color: Theme.shadowColor, radius: 6, y: 2)
                )

                // Streak chip with subtle animation
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.multicolor)
                    Text("\(streak) Day Streak")
                        .font(Theme.Font.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Theme.warning)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.warning.opacity(0.12))
                )

                Spacer()
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Search Bar

private struct SearchBarZone: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? Theme.accent : Theme.tertiaryText)

            TextField("Search bills, providers, tips...", text: $searchText)
                .font(Theme.Font.body)
                .foregroundColor(Theme.primaryText)
                .focused($isFocused)

            if !searchText.isEmpty {
                Button {
                    withAnimation(Theme.Animation.quick) {
                        searchText = ""
                    }
                    haptic()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.tertiaryText)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.shadowColorLight, radius: 16, y: 6)
                .shadow(color: Theme.shadowColor, radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous)
                .stroke(isFocused ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .animation(Theme.Animation.quick, value: isFocused)
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Quick Actions

private struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

private struct QuickActionsZone: View {
    private let actions = [
        QuickAction(icon: "plus.circle.fill", title: "Add Bill", color: Theme.accent),
        QuickAction(icon: "square.and.arrow.up", title: "Upload", color: Theme.info),
        QuickAction(icon: "arrow.left.arrow.right", title: "Compare", color: Theme.purple),
        QuickAction(icon: "chart.pie.fill", title: "Budget", color: Theme.warning),
    ]

    var body: some View {
        HStack(spacing: 14) {
            ForEach(actions) { action in
                Button { haptic() } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(action.color.opacity(0.12))
                                .frame(width: 52, height: 52)

                            Image(systemName: action.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(action.color.gradient)
                        }

                        Text(action.title)
                            .font(Theme.Font.caption)
                            .foregroundColor(Theme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.94))
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Savings Goal Progress

private struct SavingsGoalZone: View {
    let current: Double
    let goal: Double
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        min(current / goal, 1.0)
    }

    private var percentComplete: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.success.gradient)
                    Text("Monthly Savings Goal").sectionHeader()
                }
                Spacer()
                Text("\(percentComplete)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.success)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$\(Int(current))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                        .contentTransition(.numericText())
                    Text("of $\(Int(goal))")
                        .font(Theme.Font.callout)
                        .foregroundColor(Theme.secondaryText)
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.success.opacity(0.12))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.success, Theme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProgress, height: 10)
                            .shadow(color: Theme.success.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .frame(height: 10)

                Text("$\(Int(goal - current)) more to reach your goal!")
                    .font(Theme.Font.caption)
                    .foregroundColor(Theme.tertiaryText)
            }
            .cardStyle()
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .onAppear {
            withAnimation(Theme.Animation.spring.delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Achievement Badges

private struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let isUnlocked: Bool
}

private struct AchievementBadgesZone: View {
    private let achievements = [
        Achievement(icon: "star.fill", title: "First Bill", color: Theme.warning, isUnlocked: true),
        Achievement(icon: "flame.fill", title: "7 Day Streak", color: Theme.danger, isUnlocked: true),
        Achievement(icon: "dollarsign.circle.fill", title: "$100 Saved", color: Theme.success, isUnlocked: true),
        Achievement(icon: "person.2.fill", title: "Referral", color: Theme.purple, isUnlocked: false),
        Achievement(icon: "crown.fill", title: "Bill Master", color: Theme.info, isUnlocked: false),
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
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
        }
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? achievement.color : Color.gray.opacity(0.4))

                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .offset(x: 18, y: 18)
                }
            }

            Text(achievement.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(achievement.isUnlocked ? Theme.primaryText : Theme.secondaryText)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

// MARK: - Weather-Based Tip

private struct WeatherTipZone: View {
    var body: some View {
        Button { haptic() } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("92°F Today")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.primaryText)
                        Text("· Royal Oak")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }

                    Text("Set AC to 78° to save ~$8 this week")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, Theme.horizontalPadding)
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

    private let items = [
        TickerItem(icon: "bolt.fill", category: "Electric", value: "$142.30", change: "+2.1%", isUp: true),
        TickerItem(icon: "wifi", category: "Internet", value: "$71.20", change: "-0.6%", isUp: false),
        TickerItem(icon: "flame.fill", category: "Gas", value: "$3.45", change: "+1.8%", isUp: true),
        TickerItem(icon: "iphone", category: "Phone", value: "$85.00", change: "0%", isUp: false),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items) { item in
                    TickerCard(item: item)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
        }
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

// MARK: - Zone C: Micro Tasks

private struct MicroTask: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let points: Int
}

private struct MicroTasksZone: View {
    private let tasks = [
        MicroTask(icon: "checkmark.circle.fill", color: Theme.info, title: "Verify Transactions", subtitle: "Swipe 3 to confirm", points: 10),
        MicroTask(icon: "hand.thumbsup.fill", color: Theme.purple, title: "Daily Vote", subtitle: "Is $65 too much for 500Mbps?", points: 5),
        MicroTask(icon: "doc.text.viewfinder", color: Theme.warning, title: "Scan Receipt", subtitle: "Quick photo for points", points: 15),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("30-Second Checkup").sectionHeader()
                Spacer()
                Text("Earn points")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, Theme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tasks) { task in
                        MicroTaskCard(task: task)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
        }
    }
}

private struct MicroTaskCard: View {
    let task: MicroTask

    var body: some View {
        Button { haptic() } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: task.icon)
                        .font(.system(size: 22))
                        .foregroundColor(task.color)
                    Spacer()
                    Text("+\(task.points) pts")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.color)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    Text(task.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(width: 160)
            .background(task.color.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone D: Flash Drop

private struct FlashDropZone: View {
    @State private var timeRemaining = 11565
    @State private var isPulsing = false

    private var formattedTime: String {
        let h = timeRemaining / 3600
        let m = (timeRemaining % 3600) / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var body: some View {
        Button { haptic(.medium) } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 4)
                        Text("FLASH DROP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.2)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text(formattedTime)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("AT&T Fiber")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Switch & Save ~$18/mo + 500 Bonus Points")
                        .font(Theme.Font.callout)
                        .foregroundColor(.white.opacity(0.9))
                }

                HStack {
                    Text("Claim Offer")
                        .font(Theme.Font.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: [Theme.accent, Color(hex: "#2D5A42")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Subtle pattern overlay
                    LinearGradient(
                        colors: [.white.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius + 2, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.25), radius: 12, y: 6)
            .shadow(color: Theme.shadowColor, radius: 6, y: 2)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Zone E: Clusters

private struct ClusterItem: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let providerCount: Int
    let avgPrice: String
}

private struct ClustersTeaser: View {
    let zipCode: String

    private let clusters = [
        ClusterItem(category: "Internet", icon: "wifi", providerCount: 4, avgPrice: "$71"),
        ClusterItem(category: "Electricity", icon: "bolt.fill", providerCount: 2, avgPrice: "$102"),
        ClusterItem(category: "Phone", icon: "iphone", providerCount: 6, avgPrice: "$65"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Provider Clusters in \(zipCode)").sectionHeader()
                Spacer()
                Button { haptic() } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            VStack(spacing: 10) {
                ForEach(clusters) { cluster in
                    ClusterRow(cluster: cluster)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
        }
    }
}

private struct ClusterRow: View {
    let cluster: ClusterItem

    var body: some View {
        Button { haptic() } label: {
            HStack(spacing: 14) {
                Image(systemName: cluster.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Theme.accentLight)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cluster.category)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    Text("\(cluster.providerCount) Providers · Avg \(cluster.avgPrice)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            }
            .cardStyle()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone F: Daily Bill Brief

private struct DailyBillBrief: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.info)
                Text("Daily Bill Brief").sectionHeader()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.danger)
                    Text("Heatwave Incoming")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                }

                Text("Expect electric bills to rise ~$12 this week. Pre-cool your home in the morning to save on peak rates.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryText)
                    .lineSpacing(4)

                Button { haptic() } label: {
                    Text("Read Full Tip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.info)
                }
                .padding(.top, 4)
            }
            .padding(Theme.cardPadding)
            .background(Theme.info.opacity(0.1))
            .cornerRadius(Theme.cornerRadius)
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Zone G: Community Poll

private struct CommunityPollZone: View {
    private let percentAgree = 73

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.purple)
                Text("Community Poll").sectionHeader()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Is $120 for car insurance too high?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.primaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#E8E8E8"))
                            .frame(height: 28)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.purple)
                            .frame(width: geo.size.width * CGFloat(percentAgree) / 100, height: 28)

                        Text("\(percentAgree)% say YES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.leading, 12)
                    }
                }
                .frame(height: 28)

                HStack(spacing: 4) {
                    Text("You pay $110")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.success)
                    Text("(Better than average)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .padding(Theme.cardPadding)
            .background(Theme.purple.opacity(0.1))
            .cornerRadius(Theme.cornerRadius)
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Zone H: Bill Snapshot

private struct BillSnapshotZone: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.warning)
                Text("Bill Snapshot").sectionHeader()
                Spacer()
                Button { haptic() } label: {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.danger)
                        .frame(width: 40, height: 40)
                        .background(Theme.danger.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Due: Verizon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.primaryText)
                        Text("$82.10 · Due in 5 days")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryText)
                    }

                    Spacer()

                    Button { haptic() } label: {
                        Text("Pay")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.accent)
                            .cornerRadius(8)
                    }
                }

                Divider()

                HStack {
                    Text("Total Monthly")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryText)
                    Spacer()
                    Text("$1,247")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                }
            }
            .cardStyle()
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

// MARK: - Zone I: Learn to Lower

private struct PlaybookItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let duration: String
    let color: Color
}

private struct LearnToLowerZone: View {
    private let playbooks = [
        PlaybookItem(icon: "phone.fill", title: "Negotiate Internet", duration: "15 min", color: Theme.info),
        PlaybookItem(icon: "xmark.circle.fill", title: "Cancel Gym", duration: "10 min", color: Theme.danger),
        PlaybookItem(icon: "car.fill", title: "Lower Insurance", duration: "20 min", color: Theme.purple),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.success)
                Text("Learn to Lower").sectionHeader()
            }
            .padding(.horizontal, Theme.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(playbooks) { playbook in
                        PlaybookCard(playbook: playbook)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
        }
    }
}

private struct PlaybookCard: View {
    let playbook: PlaybookItem

    var body: some View {
        Button { haptic() } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: playbook.icon)
                    .font(.system(size: 24))
                    .foregroundColor(playbook.color)
                    .frame(width: 48, height: 48)
                    .background(playbook.color.opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(playbook.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(playbook.duration)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.secondaryText)
                }
            }
            .padding(14)
            .frame(width: 140)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone J: Invite & Earn

private struct InviteEarnBanner: View {
    var body: some View {
        Button { haptic(.medium) } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.purple.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Theme.purple.gradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Give $5, Get $5")
                        .font(Theme.Font.headline)
                        .foregroundColor(Theme.primaryText)
                    Text("Invite friends to verify their bills")
                        .font(Theme.Font.caption)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.purple.gradient)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.purple.opacity(0.08), Theme.purple.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .stroke(Theme.purple.opacity(0.2), lineWidth: 1)
                    )
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
