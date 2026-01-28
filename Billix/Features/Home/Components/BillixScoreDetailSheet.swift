//
//  BillixScoreDetailSheet.swift
//  Billix
//
//  Score breakdown view showing activity components
//

import SwiftUI

struct BillixScoreDetailSheet: View {
    @StateObject private var scoreService = ActivityScoreService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Score Ring
                    scoreRingSection

                    // Score Breakdown
                    if let breakdown = scoreService.breakdown {
                        breakdownSection(breakdown)
                    }

                    // Encouragement & Tips
                    tipsSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Billix Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await scoreService.fetchAndCalculateScore()
            }
        }
    }

    // MARK: - Score Ring Section

    private var scoreRingSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(scoreService.score) / 100)
                    .stroke(
                        scoreService.scoreColor,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: scoreService.score)

                // Score display
                VStack(spacing: 4) {
                    Text("\(scoreService.score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreService.scoreColor)

                    Text(scoreService.scoreLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(scoreService.encouragementText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Breakdown Section

    private func breakdownSection(_ breakdown: ActivityScoreBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ScoreBreakdownRow(
                    icon: "doc.text.fill",
                    title: "Bills Uploaded",
                    points: breakdown.billsPoints,
                    maxPoints: ActivityScoreBreakdown.maxBillsPoints,
                    color: Color.billixDarkTeal
                )

                ScoreBreakdownRow(
                    icon: "arrow.triangle.swap",
                    title: "Swaps Completed",
                    points: breakdown.swapsPoints,
                    maxPoints: ActivityScoreBreakdown.maxSwapsPoints,
                    color: Color.billixMoneyGreen
                )

                ScoreBreakdownRow(
                    icon: "flame.fill",
                    title: "Daily Streak",
                    points: breakdown.streakPoints,
                    maxPoints: ActivityScoreBreakdown.maxStreakPoints,
                    color: Color.billixGoldenAmber
                )

                ScoreBreakdownRow(
                    icon: "person.fill.checkmark",
                    title: "Profile Complete",
                    points: breakdown.profilePoints,
                    maxPoints: ActivityScoreBreakdown.maxProfilePoints,
                    color: Color.billixPurple
                )

                ScoreBreakdownRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "App Activity",
                    points: breakdown.activityPoints,
                    maxPoints: ActivityScoreBreakdown.maxActivityPoints,
                    color: Color.blue
                )
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Improve")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(improvementTips, id: \.title) { tip in
                    ImprovementTipRow(tip: tip)

                    if tip.title != improvementTips.last?.title {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var improvementTips: [ImprovementTip] {
        var tips: [ImprovementTip] = []

        guard let breakdown = scoreService.breakdown else {
            return [
                ImprovementTip(icon: "doc.badge.plus", title: "Upload your first bill", description: "Earn 3 points per bill uploaded")
            ]
        }

        // Add tips for categories that aren't maxed out
        if breakdown.billsPoints < ActivityScoreBreakdown.maxBillsPoints {
            let billsNeeded = (ActivityScoreBreakdown.maxBillsPoints - breakdown.billsPoints) / 3
            tips.append(ImprovementTip(
                icon: "doc.badge.plus",
                title: "Upload \(billsNeeded) more bills",
                description: "Earn 3 points per bill (max 30 pts)"
            ))
        }

        if breakdown.swapsPoints < ActivityScoreBreakdown.maxSwapsPoints {
            let swapsNeeded = (ActivityScoreBreakdown.maxSwapsPoints - breakdown.swapsPoints) / 5
            tips.append(ImprovementTip(
                icon: "arrow.triangle.swap",
                title: "Complete \(swapsNeeded) more swaps",
                description: "Earn 5 points per swap (max 25 pts)"
            ))
        }

        if breakdown.streakPoints < ActivityScoreBreakdown.maxStreakPoints {
            tips.append(ImprovementTip(
                icon: "flame.fill",
                title: "Build your daily streak",
                description: "Earn 2 points per day (max 20 pts)"
            ))
        }

        if breakdown.profilePoints < ActivityScoreBreakdown.maxProfilePoints {
            tips.append(ImprovementTip(
                icon: "person.fill.checkmark",
                title: "Complete your profile",
                description: "Fill in name, city, and zip for 15 pts"
            ))
        }

        if breakdown.activityPoints < ActivityScoreBreakdown.maxActivityPoints {
            tips.append(ImprovementTip(
                icon: "iphone",
                title: "Open the app daily",
                description: "Earn 2 points per visit (max 10 pts)"
            ))
        }

        if tips.isEmpty {
            tips.append(ImprovementTip(
                icon: "star.fill",
                title: "You're a Power User!",
                description: "Keep up the amazing work"
            ))
        }

        return tips
    }
}

// MARK: - Score Breakdown Row

private struct ScoreBreakdownRow: View {
    let icon: String
    let title: String
    let points: Int
    let maxPoints: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(points)/\(maxPoints)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(points) / CGFloat(maxPoints), height: 8)
                            .animation(.easeInOut(duration: 0.6), value: points)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

// MARK: - Improvement Tip Row

private struct ImprovementTip {
    let icon: String
    let title: String
    let description: String
}

private struct ImprovementTipRow: View {
    let tip: ImprovementTip

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.billixDarkTeal)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(tip.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    BillixScoreDetailSheet()
}
