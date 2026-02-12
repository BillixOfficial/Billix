//
//  RateLimitIndicator.swift
//  Billix
//
//  Created by Claude Code on 1/18/26.
//  UI component showing remaining API points with tooltip education
//

import SwiftUI

/// Compact pill showing "X/10 points" with color-coded status and info tooltip
struct RateLimitIndicator: View {
    @ObservedObject var rateLimitService: RateLimitService
    @State private var showingTooltip = false

    var body: some View {
        Button {
            showingTooltip = true
        } label: {
            HStack(spacing: 6) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))

                // Text - show X/10 points format
                Text(statusText)
                    .font(.system(size: 13, weight: .semibold))

                // Info icon
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(textColor.opacity(0.7))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingTooltip) {
            PointsTooltipView()
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Computed Properties

    private var statusText: String {
        let used = rateLimitService.currentUsage
        let limit = rateLimitService.weeklyLimit
        return "\(used)/\(limit) points"
    }

    private var iconName: String {
        switch rateLimitService.statusColor {
        case .normal:
            return "chart.bar.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }

    private var textColor: Color {
        switch rateLimitService.statusColor {
        case .normal:
            return .billixDarkTeal
        case .warning:
            return .billixGoldenAmber
        case .critical:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch rateLimitService.statusColor {
        case .normal:
            return .billixDarkTeal.opacity(0.1)
        case .warning:
            return .billixGoldenAmber.opacity(0.1)
        case .critical:
            return .red.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch rateLimitService.statusColor {
        case .normal:
            return .billixDarkTeal.opacity(0.2)
        case .warning:
            return .billixGoldenAmber.opacity(0.3)
        case .critical:
            return .red.opacity(0.3)
        }
    }
}

// MARK: - Points Tooltip View

/// Tooltip showing breakdown of point costs
struct PointsTooltipView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("How Points Work")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // Point costs
            VStack(alignment: .leading, spacing: 8) {
                PointCostRow(
                    icon: "magnifyingglass",
                    action: "New address search",
                    points: RateLimitConfig.newSearchCost
                )

                PointCostRow(
                    icon: "slider.horizontal.3",
                    action: "Change beds/baths",
                    points: RateLimitConfig.filterChangeCost
                )

                PointCostRow(
                    icon: "checkmark.circle",
                    action: "Other filters",
                    points: 0,
                    isFree: true
                )

                PointCostRow(
                    icon: "arrow.clockwise",
                    action: "Cached search",
                    points: 0,
                    isFree: true
                )
            }

            Divider()

            // Reset info
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text("Resets every Monday")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 220)
    }
}

/// Row showing a single point cost item
struct PointCostRow: View {
    let icon: String
    let action: String
    let points: Int
    var isFree: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.billixDarkTeal)
                .frame(width: 20)

            Text(action)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            if isFree {
                Text("Free")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.billixMoneyGreen)
            } else {
                Text("\(points) pt\(points == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.billixDarkTeal)
            }
        }
    }
}

// MARK: - Preview

struct RateLimitIndicator_Normal_State_Previews: PreviewProvider {
    static var previews: some View {
        RateLimitIndicator(rateLimitService: RateLimitService.shared)
        .padding()
    }
}

struct RateLimitIndicator_Tooltip_Previews: PreviewProvider {
    static var previews: some View {
        PointsTooltipView()
        .padding()
    }
}
