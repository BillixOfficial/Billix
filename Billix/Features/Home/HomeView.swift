//
//  HomeView.swift
//  Billix
//
//  The "Today" Dashboard - Everything above the fold answers:
//  "What should I do with my money today in under 60 seconds?"
//

import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @State private var userName = "David"
    @State private var userZip = "48067"
    @State private var userCity = "Royal Oak, MI"
    @State private var billixScore = 742
    @State private var streakDays = 6

    var body: some View {
        ZStack {
            // Background - subtle green tint
            Color(hex: "#EDF3EF")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Zone A: Header
                    HeaderZone(
                        userName: userName,
                        location: userCity,
                        zipCode: userZip,
                        score: billixScore,
                        streak: streakDays
                    )

                    // Zone B: Bill Ticker
                    BillTickerZone(zipCode: userZip)

                    // Zone C: 30-Second Checkup
                    MicroTasksZone()

                    // Zone D: Flash Drop Highlight
                    FlashDropZone()

                    // Zone E: Clusters Teaser
                    ClustersTeaser(zipCode: userZip)

                    // Zone F: Daily Bill Brief
                    DailyBillBrief()

                    // Zone G: Community Poll
                    CommunityPollZone()

                    // Zone H: Bill Snapshot
                    BillSnapshotZone()

                    // Zone I: Learn to Lower
                    LearnToLowerZone()

                    // Zone J: Invite & Earn
                    InviteEarnBanner()

                    // Bottom spacer for tab bar
                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .refreshable {
                hapticFeedback(.success)
            }
        }
    }

    private func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Zone A: Header

struct HeaderZone: View {
    let userName: String
    let location: String
    let zipCode: String
    let score: Int
    let streak: Int

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        else if hour < 17 { return "Good Afternoon" }
        else { return "Good Evening" }
    }

    private var scoreLabel: String {
        if score >= 750 { return "Excellent" }
        else if score >= 700 { return "Very Efficient" }
        else if score >= 650 { return "Good" }
        else { return "Needs Work" }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: Greeting and notification
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting), \(userName)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1A2F23"))

                    // Location (clickable)
                    Button {
                        // Change zip action
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text("\(location) \(zipCode)")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#5B8A6B"))
                    }
                }

                Spacer()

                // Notification bell
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#5B8A6B"))

                        // Notification badge
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
            }

            // Score and Streak chips
            HStack(spacing: 10) {
                // Billix Score chip
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                    Text("\(score)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1A2F23"))
                    Text("· \(scoreLabel)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                // Streak chip
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#E67E22"))
                    Text("\(streak) Day Streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#E67E22"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#FEF3E2"))
                .cornerRadius(20)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Zone B: Bill Ticker

struct BillTickerZone: View {
    let zipCode: String

    let tickerItems = [
        TickerItem(icon: "bolt.fill", category: "Electric", location: "48067", value: "$142.30", change: "+2.1%", isUp: true),
        TickerItem(icon: "wifi", category: "Internet", location: "48067", value: "$71.20", change: "-0.6%", isUp: false),
        TickerItem(icon: "flame.fill", category: "Gas", location: "48067", value: "$3.45", change: "+1.8%", isUp: true),
        TickerItem(icon: "iphone", category: "Phone", location: "48067", value: "$85.00", change: "0%", isUp: false),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tickerItems, id: \.category) { item in
                    TickerCard(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct TickerItem {
    let icon: String
    let category: String
    let location: String
    let value: String
    let change: String
    let isUp: Bool
}

struct TickerCard: View {
    let item: TickerItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#5B8A6B"))
                .frame(width: 32, height: 32)
                .background(Color(hex: "#5B8A6B").opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                HStack(spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1A2F23"))
                    Text(item.change)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(item.isUp ? Color(hex: "#E74C3C") : Color(hex: "#27AE60"))
                    Image(systemName: item.isUp ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(item.isUp ? Color(hex: "#E74C3C") : Color(hex: "#27AE60"))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Zone C: Micro Tasks (30-Second Checkup)

struct MicroTasksZone: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("30-Second Checkup")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
                Spacer()
                Text("Earn points")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MicroTaskCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Color(hex: "#3498DB"),
                        title: "Verify Transactions",
                        subtitle: "Swipe 3 to confirm",
                        points: 10,
                        backgroundColor: Color(hex: "#EBF5FB")
                    )

                    MicroTaskCard(
                        icon: "hand.thumbsup.fill",
                        iconColor: Color(hex: "#9B59B6"),
                        title: "Daily Vote",
                        subtitle: "Is $65 too much for 500Mbps?",
                        points: 5,
                        backgroundColor: Color(hex: "#F5EEF8")
                    )

                    MicroTaskCard(
                        icon: "doc.text.viewfinder",
                        iconColor: Color(hex: "#E67E22"),
                        title: "Scan Receipt",
                        subtitle: "Quick photo for points",
                        points: 15,
                        backgroundColor: Color(hex: "#FEF5E7")
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct MicroTaskCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let points: Int
    let backgroundColor: Color

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)

                    Spacer()

                    Text("+\(points) pts")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(iconColor)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2F23"))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(width: 160)
            .background(backgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone D: Flash Drop

struct FlashDropZone: View {
    @State private var timeRemaining = 11565 // seconds (3:12:45)

    var formattedTime: String {
        let hours = timeRemaining / 3600
        let minutes = (timeRemaining % 3600) / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
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
                        .foregroundColor(Color(hex: "#5B8A6B"))
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
                    colors: [Color(hex: "#5B8A6B"), Color(hex: "#3D6B4F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .padding(.horizontal, 20)
    }
}

// MARK: - Zone E: Clusters Teaser

struct ClustersTeaser: View {
    let zipCode: String

    let clusters = [
        ClusterItem(category: "Internet", providerCount: 4, avgPrice: "$71"),
        ClusterItem(category: "Electricity", providerCount: 2, avgPrice: "$102"),
        ClusterItem(category: "Phone", providerCount: 6, avgPrice: "$65"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Provider Clusters in \(zipCode)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
                Spacer()
                Button {
                    // View all
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(clusters, id: \.category) { cluster in
                    ClusterRow(cluster: cluster)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ClusterItem {
    let category: String
    let providerCount: Int
    let avgPrice: String
}

struct ClusterRow: View {
    let cluster: ClusterItem

    var icon: String {
        switch cluster.category {
        case "Internet": return "wifi"
        case "Electricity": return "bolt.fill"
        case "Phone": return "iphone"
        default: return "doc.fill"
        }
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#5B8A6B"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#5B8A6B").opacity(0.12))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cluster.category)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2F23"))
                    Text("\(cluster.providerCount) Providers · Avg \(cluster.avgPrice)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone F: Daily Bill Brief

struct DailyBillBrief: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#3498DB"))
                Text("Daily Bill Brief")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.sun.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#E74C3C"))
                    Text("Heatwave Incoming")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2F23"))
                }

                Text("Expect electric bills to rise ~$12 this week. Pre-cool your home in the morning to save on peak rates.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineSpacing(4)

                Button {
                    // Read more
                } label: {
                    Text("Read Full Tip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#3498DB"))
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(hex: "#EBF5FB"))
            .cornerRadius(14)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Zone G: Community Poll

struct CommunityPollZone: View {
    let percentAgree = 73
    let userPays = "$110"
    let avgPays = "$120"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#9B59B6"))
                Text("Community Poll")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Is $120 for car insurance too high?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#1A2F23"))

                // Poll bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#E8E8E8"))
                            .frame(height: 28)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#9B59B6"))
                            .frame(width: geo.size.width * CGFloat(percentAgree) / 100, height: 28)

                        HStack {
                            Text("\(percentAgree)% say YES")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.leading, 12)
                            Spacer()
                        }
                    }
                }
                .frame(height: 28)

                HStack(spacing: 4) {
                    Text("You pay \(userPays)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#27AE60"))
                    Text("(Better than average)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(16)
            .background(Color(hex: "#F5EEF8"))
            .cornerRadius(14)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Zone H: Bill Snapshot

struct BillSnapshotZone: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#E67E22"))
                Text("Bill Snapshot")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
                Spacer()
                Button {
                    // View all bills
                } label: {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }

            VStack(spacing: 12) {
                // Next bill due
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#E74C3C"))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "#FDEDEC"))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Due: Verizon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#1A2F23"))
                        Text("$82.10 · Due in 5 days")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }

                    Spacer()

                    Button {
                        // Pay now
                    } label: {
                        Text("Pay")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#5B8A6B"))
                            .cornerRadius(8)
                    }
                }

                Divider()

                // Monthly total
                HStack {
                    Text("Total Monthly")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7280"))
                    Spacer()
                    Text("$1,247")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1A2F23"))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Zone I: Learn to Lower

struct LearnToLowerZone: View {
    let playbooks = [
        Playbook(icon: "phone.fill", title: "Negotiate Internet", duration: "15 min", color: Color(hex: "#3498DB")),
        Playbook(icon: "xmark.circle.fill", title: "Cancel Gym", duration: "10 min", color: Color(hex: "#E74C3C")),
        Playbook(icon: "car.fill", title: "Lower Insurance", duration: "20 min", color: Color(hex: "#9B59B6")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#27AE60"))
                Text("Learn to Lower")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A2F23"))
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(playbooks, id: \.title) { playbook in
                        PlaybookCard(playbook: playbook)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct Playbook {
    let icon: String
    let title: String
    let duration: String
    let color: Color
}

struct PlaybookCard: View {
    let playbook: Playbook

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
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
                        .foregroundColor(Color(hex: "#1A2F23"))
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(playbook.duration)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(14)
            .frame(width: 140)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Zone J: Invite & Earn

struct InviteEarnBanner: View {
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#9B59B6"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Give $5, Get $5")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1A2F23"))
                    Text("Invite friends to verify their bills")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#9B59B6"))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#F5EEF8"), Color(hex: "#EDE7F6")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#9B59B6").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .padding(.horizontal, 20)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
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
