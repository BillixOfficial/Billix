//
//  RateLimitExceededView.swift
//  Billix
//
//  Created by Claude Code on 1/18/26.
//  Full-screen view shown when user has exceeded their weekly API limit
//

import SwiftUI

/// View displayed when user has reached their weekly search limit
struct RateLimitExceededView: View {
    @ObservedObject var rateLimitService: RateLimitService
    var onUpgrade: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            // Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.8))
            }

            // Title
            Text("Weekly Limit Reached")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            // Description
            VStack(spacing: 8) {
                Text("You've used all \(rateLimitService.weeklyLimit) points this week.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                Text("Your limit resets every Monday.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .multilineTextAlignment(.center)

            // Usage Stats Card
            VStack(spacing: 12) {
                HStack {
                    Text("This Week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(rateLimitService.currentUsage) / \(rateLimitService.weeklyLimit)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: geo.size.width, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text("Resets \(nextResetText)")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 16)

            // Upgrade CTA (for future premium tier)
            VStack(spacing: 12) {
                Button {
                    onUpgrade?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                        Text("Upgrade to Premium")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Text("Get 50 points/week with Premium")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "F8F9FA"),
                    Color(hex: "E9ECEF")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Computed Properties

    private var nextResetText: String {
        let calendar = Calendar.current
        let today = Date()

        // Find next Monday
        var components = DateComponents()
        components.weekday = 2 // Monday
        guard let nextMonday = calendar.nextDate(after: today, matching: components, matchingPolicy: .nextTime) else {
            return "Monday"
        }

        let days = calendar.dateComponents([.day], from: today, to: nextMonday).day ?? 0

        if days == 0 {
            return "today"
        } else if days == 1 {
            return "tomorrow"
        } else {
            return "in \(days) days"
        }
    }
}

// MARK: - Preview

#Preview("Rate Limit Exceeded") {
    RateLimitExceededView(rateLimitService: RateLimitService.shared)
}
