//
//  ActivityFeedRowView.swift
//  Billix
//
//  Activity Feed Row for Social Proof Display
//

import SwiftUI

struct ActivityFeedRowView: View {
    let item: SwapActivityFeedItem

    var body: some View {
        HStack(spacing: 12) {
            // Category icons
            HStack(spacing: -8) {
                CategoryIconCircle(icon: item.category1Icon, isFirst: true)
                CategoryIconCircle(icon: item.category2Icon, isFirst: false)
            }

            // Swap info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Amount range
                    Text(item.amountRangeText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    // Tier badges
                    HStack(spacing: 2) {
                        TierBadgeMini(tierString: item.tierBadge1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        TierBadgeMini(tierString: item.tierBadge2)
                    }
                }
            }

            Spacer()

            // Time
            Text(item.relativeTimeText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
    }
}

// MARK: - Category Icon Circle

struct CategoryIconCircle: View {
    let icon: String
    let isFirst: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.billixDarkTeal)
        }
        .zIndex(isFirst ? 1 : 0)
    }
}

// MARK: - Tier Badge Mini

struct TierBadgeMini: View {
    let tierString: String

    private var tier: SwapTrustTier {
        SwapTrustTier(rawValue: tierString) ?? .T1_PROVISIONAL
    }

    var body: some View {
        Image(systemName: tier.icon)
            .font(.system(size: 10))
            .foregroundColor(Color(hex: tier.color))
    }
}

// MARK: - Activity Feed Header

struct ActivityFeedHeader: View {
    let stats: ActivityFeedStats?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.billixGoldenAmber)
                Text("Live Swaps")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2D3B35"))

                Spacer()

                if let stats = stats {
                    Text(stats.formattedTodayCount)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "5B8A6B"))
                }
            }

            if let stats = stats, let matchTime = stats.formattedMatchTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(matchTime)
                        .font(.system(size: 11))
                }
                .foregroundColor(.billixMoneyGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.billixDarkTeal.opacity(0.15),
                    Color.billixMoneyGreen.opacity(0.10)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Activity Feed List

struct ActivityFeedList: View {
    let items: [SwapActivityFeedItem]
    let stats: ActivityFeedStats?

    var body: some View {
        VStack(spacing: 0) {
            ActivityFeedHeader(stats: stats)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "8B9A94"))
                    Text("No recent swaps")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8B9A94"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(hex: "F7F9F8"))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        ActivityFeedRowView(item: item)
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ActivityFeedList(
            items: SwapActivityFeedItem.mockItems,
            stats: ActivityFeedStats(
                totalSwapsToday: 12,
                totalSwapsThisWeek: 87,
                averageMatchTime: 1800,
                mostActiveCategory: "electric"
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
