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
    let requesterPoints: Int
    let supporterPoints: Int
    @ObservedObject var notificationService: NotificationService

    @State private var showNotifications = false
    @State private var showAreaInsights = false
    @State private var showConnectionStatsSheet = false

    // Helper to get tier name from points
    private func tierName(for points: Int) -> String {
        switch points {
        case 0..<100: return "Neighbor"
        case 100..<500: return "Contributor"
        default: return "Pillar"
        }
    }

    // Helper to get tier color from points
    private func tierColor(for points: Int) -> Color {
        switch points {
        case 0..<100: return Color(hex: "#5B8A6B")      // Green - Neighbor
        case 100..<500: return Color(hex: "#9B7B9F")    // Purple - Contributor
        default: return Color(hex: "#E8B54D")           // Gold - Pillar
        }
    }

    // Parse location into city and state
    private var cityName: String {
        let parts = location.split(separator: ",")
        return parts.first.map(String.init) ?? location
    }

    private var stateName: String {
        let parts = location.split(separator: ",")
        return parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
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
                        showAreaInsights = true
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

                        if notificationService.unreadCount > 0 {
                            Text("\(notificationService.unreadCount)")
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

            HStack(spacing: 8) {
                // Requester Points
                Button {
                    haptic()
                    showConnectionStatsSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(tierColor(for: requesterPoints))
                        Text("\(requesterPoints)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(HomeTheme.primaryText)
                        Text("·")
                            .foregroundColor(HomeTheme.secondaryText)
                        Text("Requester")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(tierColor(for: requesterPoints))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(HomeTheme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: HomeTheme.shadowColor, radius: 3)
                }
                .buttonStyle(.plain)

                // Supporter Points
                Button {
                    haptic()
                    showConnectionStatsSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(tierColor(for: supporterPoints))
                        Text("\(supporterPoints)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(HomeTheme.primaryText)
                        Text("·")
                            .foregroundColor(HomeTheme.secondaryText)
                        Text("Supporter")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(tierColor(for: supporterPoints))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(HomeTheme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: HomeTheme.shadowColor, radius: 3)
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: HomeTheme.iconSmall))
                    Text("\(streak)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(HomeTheme.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(HomeTheme.warning.opacity(0.15))
                .cornerRadius(16)

                Spacer()
            }
        }
        .padding(.horizontal, HomeTheme.horizontalPadding)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(notificationService: notificationService)
        }
        .sheet(isPresented: $showAreaInsights) {
            AreaInsightsSheet(city: cityName, state: stateName, zipCode: zipCode)
        }
        .sheet(isPresented: $showConnectionStatsSheet) {
            ConnectionStatsSheet(
                requesterPoints: requesterPoints,
                supporterPoints: supporterPoints
            )
        }
    }
}

// MARK: - Notifications Sheet

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        NavigationView {
            ScrollView {
                if notificationService.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(HomeTheme.secondaryText.opacity(0.5))

                        Text("No notifications yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(HomeTheme.secondaryText)

                        Text("You'll see updates about your swaps, bills, and achievements here.")
                            .font(.system(size: 14))
                            .foregroundColor(HomeTheme.secondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(notificationService.notifications) { notification in
                            NotificationRow(
                                notification: notification,
                                onTap: {
                                    notificationService.markRead(id: notification.id)
                                }
                            )
                            if notification.id != notificationService.notifications.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(HomeTheme.cornerRadius)
                    .padding()
                }
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
                    if !notificationService.notifications.isEmpty && notificationService.unreadCount > 0 {
                        Button("Mark all read") {
                            haptic()
                            notificationService.markAllRead()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(HomeTheme.accent)
                    }
                }
            }
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotificationItem
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            haptic()
            onTap?()
        } label: {
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
                        .lineLimit(2)

                    Text(notification.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(HomeTheme.secondaryText.opacity(0.7))
                }
            }
            .padding(.horizontal, HomeTheme.cardPadding)
            .padding(.vertical, 14)
            .background(notification.isUnread ? HomeTheme.accent.opacity(0.03) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// ConnectionStatsSheet is defined in ConnectionStatsSheet.swift
