//
//  BillixScoreView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  Main view displaying user's Billix Score and badge
//

import SwiftUI

struct BillixScoreView: View {
    @StateObject private var scoreService = BillixScoreService.shared
    @State private var showBreakdown = false
    @State private var showHistory = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main Score Card
                scoreCard

                // Component Scores
                componentScoresCard

                // Recent Activity
                recentActivityCard

                // How to Improve
                improvementTipsCard
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Billix Score")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBreakdown) {
            ScoreBreakdownView()
        }
        .sheet(isPresented: $showHistory) {
            ScoreHistoryView()
        }
        .refreshable {
            await scoreService.loadScore()
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 20) {
            // Badge and Score
            HStack(spacing: 24) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(scoreService.badgeLevel.gradient)
                        .frame(width: 80, height: 80)

                    Image(systemName: scoreService.badgeLevel.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(scoreService.badgeLevel.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryText)

                    Text(scoreService.badgeLevel.description)
                        .font(.system(size: 13))
                        .foregroundColor(secondaryText)

                    // Score number
                    HStack(spacing: 4) {
                        Text("\(scoreService.overallScore)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(scoreService.badgeLevel.gradient)

                        Text("/ 1000")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()
            }

            // Progress to next level
            if scoreService.badgeLevel != .elite {
                progressSection
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showBreakdown = true
                } label: {
                    Label("Breakdown", systemImage: "chart.pie")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(cardBg)
                        .cornerRadius(8)
                }

                Button {
                    showHistory = true
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(cardBg)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scoreService.badgeLevel.gradient, lineWidth: 1)
                )
        )
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress to \(nextBadgeLevel.displayName)")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                Spacer()

                if let points = scoreService.badgeLevel.pointsToNextLevel(currentScore: scoreService.overallScore) {
                    Text("\(points) points to go")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(nextBadgeLevel.color)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreService.badgeLevel.gradient)
                        .frame(width: geo.size.width * progressToNext, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var nextBadgeLevel: BillixBadgeLevel {
        switch scoreService.badgeLevel {
        case .newcomer: return .trusted
        case .trusted: return .verified
        case .verified: return .elite
        case .elite: return .elite
        }
    }

    private var progressToNext: Double {
        guard let score = scoreService.currentScore else { return 0 }
        return score.progressToNextLevel
    }

    // MARK: - Component Scores

    private var componentScoresCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Components")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            ForEach(ScoreComponent.allCases) { component in
                componentRow(component)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func componentRow(_ component: ScoreComponent) -> some View {
        let score = scoreService.currentScore?.score(for: component) ?? 0

        return VStack(spacing: 8) {
            HStack {
                Image(systemName: component.icon)
                    .font(.system(size: 14))
                    .foregroundColor(component.color)

                Text(component.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(primaryText)

                Spacer()

                Text("\(score)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)

                Text("/ 100")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(component.color)
                        .frame(width: geo.size.width * (Double(score) / 100.0), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Recent Activity

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Button {
                    showHistory = true
                } label: {
                    Text("See All")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }

            if scoreService.recentHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(secondaryText)
                        Text("No recent activity")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(scoreService.recentHistory.prefix(5)) { entry in
                    historyRow(entry)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func historyRow(_ entry: ScoreHistoryEntry) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: entry.scoreComponent?.icon ?? "star")
                .font(.system(size: 14))
                .foregroundColor(entry.pointChange >= 0 ? .green : .red)
                .frame(width: 28, height: 28)
                .background((entry.pointChange >= 0 ? Color.green : Color.red).opacity(0.15))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.description ?? entry.event?.displayName ?? "Score Update")
                    .font(.system(size: 13))
                    .foregroundColor(primaryText)

                Text(entry.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Text(entry.formattedChange)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(entry.pointChange >= 0 ? .green : .red)
        }
    }

    // MARK: - Improvement Tips

    private var improvementTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Improve")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            tipRow(icon: "checkmark.circle", text: "Complete more swaps successfully", points: "+10")
            tipRow(icon: "camera.viewfinder", text: "Submit clear payment screenshots", points: "+5")
            tipRow(icon: "star.fill", text: "Get high ratings from partners", points: "+5")
            tipRow(icon: "clock.fill", text: "Complete swaps on time", points: "+5")
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func tipRow(icon: String, text: String, points: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(primaryText)

            Spacer()

            Text(points)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
        }
    }
}

// MARK: - Score Breakdown View

struct ScoreBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scoreService = BillixScoreService.shared

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Score formula explanation
                    formulaCard

                    // Component details
                    ForEach(ScoreComponent.allCases) { component in
                        componentDetailCard(component)
                    }

                    // Badge levels
                    badgeLevelsCard
                }
                .padding()
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Score Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Your Score is Calculated")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Your Billix Score is a weighted combination of four components, scaled to 0-1000:")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)

            VStack(alignment: .leading, spacing: 8) {
                formulaRow("Completion", weight: "35%", color: ScoreComponent.completion.color)
                formulaRow("Verification", weight: "25%", color: ScoreComponent.verification.color)
                formulaRow("Community", weight: "25%", color: ScoreComponent.community.color)
                formulaRow("Reliability", weight: "15%", color: ScoreComponent.reliability.color)
            }
            .padding()
            .background(background)
            .cornerRadius(8)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func formulaRow(_ name: String, weight: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(.system(size: 13))
                .foregroundColor(primaryText)

            Spacer()

            Text(weight)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private func componentDetailCard(_ component: ScoreComponent) -> some View {
        let score = scoreService.currentScore?.score(for: component) ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: component.icon)
                    .font(.system(size: 18))
                    .foregroundColor(component.color)

                Text(component.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Text("\(score)/100")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(component.color)
            }

            Text(component.description)
                .font(.system(size: 13))
                .foregroundColor(secondaryText)

            Divider().background(secondaryText.opacity(0.3))

            // How it's calculated
            VStack(alignment: .leading, spacing: 6) {
                Text("How it changes:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)

                ForEach(eventsForComponent(component), id: \.self) { event in
                    HStack {
                        Text(event.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(primaryText)

                        Spacer()

                        Text(event.basePointChange >= 0 ? "+\(event.basePointChange)" : "\(event.basePointChange)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(event.isPositive ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func eventsForComponent(_ component: ScoreComponent) -> [ScoreEventType] {
        ScoreEventType.allCases.filter { $0.affectedComponent == component }
    }

    private var badgeLevelsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badge Levels")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            ForEach(BillixBadgeLevel.allCases) { level in
                let isCurrent = level == scoreService.badgeLevel

                HStack(spacing: 12) {
                    Image(systemName: level.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(level.gradient)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(level.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryText)

                            if isCurrent {
                                Text("Current")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    .cornerRadius(4)
                            }
                        }

                        Text("\(level.scoreRange.lowerBound) - \(level.scoreRange.upperBound) points")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }

                    Spacer()
                }
                .padding()
                .background(isCurrent ? level.color.opacity(0.1) : background)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCurrent ? level.color : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }
}

// MARK: - Score History View

struct ScoreHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scoreService = BillixScoreService.shared

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                if scoreService.recentHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundColor(secondaryText)

                        Text("No score history yet")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryText)

                        Text("Complete swaps to start building your score!")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(scoreService.recentHistory) { entry in
                            historyDetailRow(entry)
                                .listRowBackground(cardBg)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Score History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func historyDetailRow(_ entry: ScoreHistoryEntry) -> some View {
        HStack(spacing: 12) {
            // Component icon
            Image(systemName: entry.scoreComponent?.icon ?? "star")
                .font(.system(size: 16))
                .foregroundColor(entry.scoreComponent?.color ?? .gray)
                .frame(width: 36, height: 36)
                .background((entry.scoreComponent?.color ?? .gray).opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.description ?? entry.event?.displayName ?? "Score Update")
                    .font(.system(size: 14))
                    .foregroundColor(primaryText)

                HStack(spacing: 8) {
                    if let component = entry.scoreComponent {
                        Text(component.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(component.color)
                    }

                    Text(entry.createdAt, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedChange)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(entry.pointChange >= 0 ? .green : .red)

                Text("→ \(entry.newScore)")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ScoreEventType Extension

extension ScoreEventType: CaseIterable {
    static var allCases: [ScoreEventType] {
        [.swapCompleted, .swapFailed, .ghostIncident, .screenshotVerified,
         .screenshotRejected, .ratingReceived, .onTimeCompletion, .lateCompletion,
         .accountAgeMilestone, .consistencyStreak]
    }
}

// MARK: - Preview

struct BillixScoreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        BillixScoreView()
        }
        .preferredColorScheme(.dark)
    }
}
