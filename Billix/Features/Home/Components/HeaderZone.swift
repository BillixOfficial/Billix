//
//  HeaderZone.swift
//  Billix
//

import SwiftUI

// MARK: - Header Zone

struct HeaderZone: View {
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
                        .foregroundColor(HomeTheme.primaryText)

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
                        .foregroundColor(HomeTheme.accent)
                    }
                }

                Spacer()

                Button {
                    haptic()
                    showNotifications = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(HomeTheme.cardBackground)
                            .frame(width: 40, height: 40)
                            .shadow(color: HomeTheme.shadowColor, radius: 4)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(HomeTheme.accent)

                        if notificationCount > 0 {
                            Text("\(notificationCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(HomeTheme.danger)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(HomeTheme.accent)
                        Text("\(score)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(HomeTheme.primaryText)
                        Text("· \(scoreLabel)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HomeTheme.secondaryText)
                    }

                    Text("Top 18% in \(zipCode)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(HomeTheme.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(HomeTheme.cardBackground)
                .cornerRadius(14)
                .shadow(color: HomeTheme.shadowColor, radius: 4)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: HomeTheme.iconSmall))
                    Text("\(streak) Day Streak")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(HomeTheme.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(HomeTheme.warning.opacity(0.15))
                .cornerRadius(20)

                Spacer()
            }
        }
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
    }
}

// MARK: - Notifications Sheet

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let notifications = [
        NotificationItem(
            icon: "bolt.fill",
            iconColor: HomeTheme.warning,
            title: "Electric bill is due soon",
            subtitle: "DTE Energy · Due in 3 days",
            time: "2h ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "arrow.down.circle.fill",
            iconColor: HomeTheme.success,
            title: "You saved $23 this month!",
            subtitle: "Your negotiation with Xfinity worked",
            time: "1d ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "person.2.fill",
            iconColor: HomeTheme.purple,
            title: "New swap partner available",
            subtitle: "Sarah M. wants to swap bills",
            time: "2d ago",
            isUnread: true
        ),
        NotificationItem(
            icon: "star.fill",
            iconColor: HomeTheme.info,
            title: "Achievement unlocked!",
            subtitle: "You earned the 'Budget Master' badge",
            time: "3d ago",
            isUnread: false
        ),
        NotificationItem(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: HomeTheme.accent,
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
                .cornerRadius(HomeTheme.cornerRadius)
                .padding()
            }
            .background(HomeTheme.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Mark all read") { haptic() }
                        .font(.system(size: 14))
                        .foregroundColor(HomeTheme.accent)
                }
            }
        }
    }
}

// MARK: - Notification Item

struct NotificationItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    let isUnread: Bool
}

// MARK: - Notification Row

struct NotificationRow: View {
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
                        .foregroundColor(HomeTheme.primaryText)

                    Spacer()

                    if notification.isUnread {
                        Circle()
                            .fill(HomeTheme.accent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(HomeTheme.secondaryText)

                Text(notification.time)
                    .font(.system(size: 12))
                    .foregroundColor(HomeTheme.secondaryText.opacity(0.7))
            }
        }
        .padding(.horizontal, HomeTheme.cardPadding)
        .padding(.vertical, 14)
        .background(notification.isUnread ? HomeTheme.accent.opacity(0.03) : Color.clear)
    }
}
