//
//  SignalCard.swift
//  Billix
//
//  Signal/prediction card components for Marketplace
//

import SwiftUI

// MARK: - Signal Card

struct SignalCard: View {
    let signal: MarketplaceSignal
    let userVote: String?
    let onVoteYes: () -> Void
    let onVoteNo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: signal.categoryIcon)
                        .font(.system(size: 10))
                    Text(signal.category)
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                }
                .foregroundStyle(MarketplaceTheme.Colors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                )

                if let provider = signal.providerName {
                    Text("• \(provider)")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Activity indicator
                PulseDotsView(activityLevel: signal.activityLevel)
            }

            // Question
            Text(signal.question)
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                .lineLimit(3)

            // Voting bar
            VotingPercentageBar(yesPercentage: signal.yesPercentage)

            // Vote buttons
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                voteButton(vote: "yes", label: "Yes", percentage: signal.yesPercentage, color: MarketplaceTheme.Colors.success)
                voteButton(vote: "no", label: "No", percentage: 100 - signal.yesPercentage, color: MarketplaceTheme.Colors.danger)
            }

            // Footer
            HStack {
                if let expires = signal.expiresDisplay {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(expires)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(signal.totalVotes) votes")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                }
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .shadow(
                    color: MarketplaceTheme.Shadows.low.color,
                    radius: MarketplaceTheme.Shadows.low.radius,
                    x: 0,
                    y: 2
                )
        )
    }

    private func voteButton(vote: String, label: String, percentage: Double, color: Color) -> some View {
        let hasVoted = userVote != nil
        let isThisVote = userVote == vote

        return Button {
            if vote == "yes" {
                onVoteYes()
            } else {
                onVoteNo()
            }
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .bold))
                Text("\(percentage, specifier: "%.0f")%")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
            }
            .foregroundStyle(isThisVote ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(isThisVote ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .stroke(color.opacity(isThisVote ? 0 : 0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(hasVoted && !isThisVote)
        .opacity(hasVoted && !isThisVote ? 0.5 : 1)
    }
}

// MARK: - Signal Card Compact

struct SignalCardCompact: View {
    let signal: MarketplaceSignal
    let userVote: String

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Vote indicator
            ZStack {
                Circle()
                    .fill((userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: userVote == "yes" ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(signal.question)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("You voted \(userVote.capitalized)")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(userVote == "yes" ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.danger)

                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("\(userVote == "yes" ? signal.yesPercentage : 100 - signal.yesPercentage, specifier: "%.0f")% agree")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, MarketplaceTheme.Spacing.xs)
    }
}

// MARK: - Voting Percentage Bar

struct VotingPercentageBar: View {
    let yesPercentage: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background (No)
                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.danger.opacity(0.3))

                // Yes portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(MarketplaceTheme.Colors.success)
                    .frame(width: geo.size.width * (yesPercentage / 100))
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Pulse Dots View (Activity Indicator)

struct PulseDotsView: View {
    let activityLevel: SignalActivityLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        switch activityLevel {
        case .high:
            return MarketplaceTheme.Colors.success
        case .medium:
            return index < 2 ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.textTertiary.opacity(0.3)
        case .low:
            return index < 1 ? MarketplaceTheme.Colors.textTertiary : MarketplaceTheme.Colors.textTertiary.opacity(0.3)
        }
    }
}

// MARK: - Market Pulse Card

struct MarketPulseCard: View {
    let sentiments: [CategorySentiment]

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 16))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)

                Text("Market Pulse")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("Community Sentiment")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            // Sentiment items
            VStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(sentiments) { sentiment in
                    sentimentRow(sentiment)
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .stroke(MarketplaceTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func sentimentRow(_ sentiment: CategorySentiment) -> some View {
        HStack {
            Text(sentiment.category)
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                .frame(width: 80, alignment: .leading)

            // Sentiment bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(sentimentColor(sentiment.score))
                        .frame(width: geo.size.width * abs(sentiment.score))
                }
            }
            .frame(height: 6)

            // Score
            Text(sentimentLabel(sentiment.score))
                .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                .foregroundStyle(sentimentColor(sentiment.score))
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func sentimentColor(_ score: Double) -> Color {
        if score > 0.3 {
            return MarketplaceTheme.Colors.success
        } else if score < -0.3 {
            return MarketplaceTheme.Colors.danger
        } else {
            return MarketplaceTheme.Colors.warning
        }
    }

    private func sentimentLabel(_ score: Double) -> String {
        if score > 0.3 {
            return "Bullish"
        } else if score < -0.3 {
            return "Bearish"
        } else {
            return "Neutral"
        }
    }
}
