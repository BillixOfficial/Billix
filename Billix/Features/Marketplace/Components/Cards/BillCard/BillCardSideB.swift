//
//  BillCardSideB.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Side B: Analyst View - Deep dive analytics
/// Shows performance charts, radar, peer comparison, success trend
struct BillCardSideB: View {
    let listing: BillListing
    @Binding var isVsMe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle (persists from Side A)
            header
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .padding(.top, MarketplaceTheme.Spacing.md)
                .padding(.bottom, MarketplaceTheme.Spacing.sm)

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.1))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
                    // Performance Chart Section
                    performanceSection

                    // Radar + Peers Row
                    HStack(alignment: .top, spacing: MarketplaceTheme.Spacing.md) {
                        radarSection
                        peersSection
                    }

                    // Success Trend
                    successTrendSection

                    // Data Freshness
                    freshnessSection
                }
                .padding(.horizontal, MarketplaceTheme.Spacing.md)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
            }

            // Swipe hint (reversed)
            swipeHint
        }
    }

    private var header: some View {
        HStack {
            // Provider info (condensed)
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                Image(systemName: listing.providerLogoName)
                    .font(.system(size: 16))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)

                Text(listing.providerName)
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }

            Spacer()

            VSMeToggle(isVsMe: $isVsMe)
        }
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            sectionTitle("PERFORMANCE")

            // Price position bar
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                            .frame(height: 8)

                        // Position indicator
                        let position = calculatePricePosition()
                        Circle()
                            .fill(MarketplaceTheme.Colors.success)
                            .frame(width: 12, height: 12)
                            .offset(x: geo.size.width * position - 6)
                    }
                }
                .frame(height: 12)

                Text("\(Int((1 - calculatePricePosition()) * 100))% below typical for \(listing.zipCode)")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
    }

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            sectionTitle("RADAR")

            // Simplified radar visualization
            ZStack {
                // Background circles
                ForEach(1...3, id: \.self) { ring in
                    Circle()
                        .stroke(MarketplaceTheme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
                        .frame(width: CGFloat(ring * 30), height: CGFloat(ring * 30))
                }

                // Radar shape (simplified)
                radarShape
            }
            .frame(width: 100, height: 100)

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                radarLabel(title: "Price", value: 0.9, color: .green)
                radarLabel(title: "Risk", value: 0.3, color: .green)
                radarLabel(title: "Speed", value: 0.7, color: .yellow)
                radarLabel(title: "Difficulty", value: frictionValue, color: frictionColor)
            }
            .font(.system(size: MarketplaceTheme.Typography.micro))
        }
        .frame(maxWidth: .infinity)
    }

    private var radarShape: some View {
        Path { path in
            let center = CGPoint(x: 50, y: 50)
            let points = [
                CGPoint(x: center.x, y: center.y - 40 * 0.9), // Price (top)
                CGPoint(x: center.x + 40 * 0.7, y: center.y), // Speed (right)
                CGPoint(x: center.x, y: center.y + 40 * frictionValue), // Difficulty (bottom)
                CGPoint(x: center.x - 40 * 0.3, y: center.y)  // Risk (left)
            ]
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        .fill(MarketplaceTheme.Colors.primary.opacity(0.3))
        .overlay(
            Path { path in
                let center = CGPoint(x: 50, y: 50)
                let points = [
                    CGPoint(x: center.x, y: center.y - 40 * 0.9),
                    CGPoint(x: center.x + 40 * 0.7, y: center.y),
                    CGPoint(x: center.x, y: center.y + 40 * frictionValue),
                    CGPoint(x: center.x - 40 * 0.3, y: center.y)
                ]
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
            .stroke(MarketplaceTheme.Colors.primary, lineWidth: 2)
        )
    }

    private var peersSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            sectionTitle("PEERS")

            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
                Text("Better than")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Text("94%")
                    .font(.system(size: MarketplaceTheme.Typography.title, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)

                Text("of \(listing.zipCode) residents")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Divider()

                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text("422 pay more")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var successTrendSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            sectionTitle("SUCCESS TREND")

            HStack(spacing: 2) {
                // Mini bar chart
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index > 4 ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.success.opacity(0.3 + Double(index) * 0.1))
                        .frame(width: 12, height: CGFloat(8 + index * 5))
                }

                Spacer()

                // Hot indicator
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(MarketplaceTheme.Colors.danger)
                    Text("Hot: working right now")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.danger)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
    }

    private var freshnessSection: some View {
        HStack(spacing: MarketplaceTheme.Spacing.xs) {
            Text("DATA FRESHNESS:")
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Circle()
                .fill(MarketplaceTheme.Colors.success)
                .frame(width: 8, height: 8)

            Text("\(daysSincePosted) days ago")
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    private var swipeHint: some View {
        HStack {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                Text("Swipe for deal")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            Spacer()
        }
        .background(MarketplaceTheme.Colors.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            .tracking(1)
    }

    private func radarLabel(title: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color == .green ? MarketplaceTheme.Colors.success : (color == .yellow ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.danger))
                .frame(width: 6, height: 6)
            Text(title)
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    private func calculatePricePosition() -> Double {
        // Position from 0 (cheapest) to 1 (most expensive)
        guard listing.marketAvgPrice > 0 else { return 0.5 }
        let ratio = listing.askPrice / listing.marketAvgPrice
        return min(max(ratio, 0), 1)
    }

    private var frictionValue: Double {
        switch listing.frictionLevel {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }

    private var frictionColor: Color {
        switch listing.frictionLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    private var daysSincePosted: Int {
        let interval = Date().timeIntervalSince(listing.postedDate)
        return max(Int(interval / 86400), 0)
    }
}

struct BillCardSideB_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
        @State private var isVsMe = false
        
        var body: some View {
        BillCardSideB(
        listing: MockMarketplaceData.billListings[0],
        isVsMe: $isVsMe
        )
        .frame(width: 360, height: 520)
        .marketplaceCard(elevation: .high)
        }
        }
        
        return PreviewWrapper()
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
