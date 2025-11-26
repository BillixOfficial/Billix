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
    // Colors
    static let background = Color(hex: "#EDF3EF")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#1A2F23")
    static let secondaryText = Color(hex: "#6B7280")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.12)

    // Semantic colors
    static let success = Color(hex: "#27AE60")
    static let warning = Color(hex: "#E67E22")
    static let danger = Color(hex: "#E74C3C")
    static let info = Color(hex: "#3498DB")
    static let purple = Color(hex: "#9B59B6")

    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 14

    // Shadow
    static let shadowColor = Color.black.opacity(0.04)
    static let shadowRadius: CGFloat = 6
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
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(Theme.primaryText)
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

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.cardSpacing) {
                    HeaderZone(
                        userName: userName,
                        location: userCity,
                        zipCode: userZip,
                        score: billixScore,
                        streak: streakDays
                    )
                    BillTickerZone(zipCode: userZip)
                    MicroTasksZone()
                    FlashDropZone()
                    ClustersTeaser(zipCode: userZip)
                    DailyBillBrief()
                    CommunityPollZone()
                    BillSnapshotZone()
                    LearnToLowerZone()
                    InviteEarnBanner()
                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
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

                Button { haptic() } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.cardBackground)
                            .frame(width: 40, height: 40)
                            .shadow(color: Theme.shadowColor, radius: 4)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.accent)

                        Circle()
                            .fill(Theme.danger)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
            }

            HStack(spacing: 10) {
                // Score chip
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .cornerRadius(20)
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

    private var formattedTime: String {
        let h = timeRemaining / 3600
        let m = (timeRemaining % 3600) / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var body: some View {
        Button { haptic(.medium) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        Text("FLASH DROP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                        Text(formattedTime)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("AT&T Fiber")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Switch & Save ~$18/mo + 500 Bonus Points")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }

                HStack {
                    Text("Claim Offer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(10)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Theme.accent, Color(hex: "#3D6B4F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
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

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
