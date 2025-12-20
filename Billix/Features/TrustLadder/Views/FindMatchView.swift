//
//  FindMatchView.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  View for finding Mirror Partners to swap with
//

import SwiftUI

struct FindMatchView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var matchingService = SwapMatchingService.shared
    @StateObject private var portfolioService = BillPortfolioService.shared
    @StateObject private var trustService = TrustLadderService.shared

    @State private var selectedBill: UserBill?
    @State private var showingMatchResults = false
    @State private var showingSwapExecution = false
    @State private var createdSwap: Swap?
    @State private var showingError = false
    @State private var errorMessage = ""

    // Theme
    private let background = Color(hex: "#F7F9F8")
    private let cardBg = Color.white
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let accent = Color(hex: "#5B8A6B")

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        if portfolioService.userBills.isEmpty {
                            emptyBillsState
                        } else {
                            // Bill selection
                            billSelectionSection

                            // Find matches button
                            if selectedBill != nil {
                                findMatchesButton
                            }

                            // Results
                            if showingMatchResults {
                                matchResultsSection
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Find a Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(item: $createdSwap) { swap in
                SwapExecutionView(swap: swap)
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(accent)

            Text("Mirror Partner Matching")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(primaryText)

            Text("Select a bill to find partners with opposite payday schedules")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyBillsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(secondaryText.opacity(0.5))

            Text("No Bills Available")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Add bills to your portfolio first to start matching")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Bill Selection

    private var billSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a Bill to Swap")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 8) {
                ForEach(portfolioService.userBills.filter { $0.isActive }) { bill in
                    billSelectionRow(bill)
                }
            }
        }
    }

    private func billSelectionRow(_ bill: UserBill) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                if selectedBill?.id == bill.id {
                    selectedBill = nil
                    showingMatchResults = false
                    matchingService.clearMatches()
                } else {
                    selectedBill = bill
                    showingMatchResults = false
                    matchingService.clearMatches()
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(selectedBill?.id == bill.id ? accent : secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if selectedBill?.id == bill.id {
                        Circle()
                            .fill(accent)
                            .frame(width: 14, height: 14)
                    }
                }

                // Bill icon
                Circle()
                    .fill(bill.category?.tier.color.opacity(0.2) ?? accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: bill.category?.icon ?? "doc.fill")
                            .font(.system(size: 18))
                            .foregroundColor(bill.category?.tier.color ?? accent)
                    )

                // Bill details
                VStack(alignment: .leading, spacing: 2) {
                    Text(bill.providerName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(primaryText)

                    HStack(spacing: 8) {
                        Text(bill.category?.displayName ?? bill.billCategory)
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)

                        Text("Due: \(ordinalDay(bill.dueDay))")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                // Amount
                Text(String(format: "$%.2f", bill.typicalAmount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryText)
            }
            .padding()
            .background(selectedBill?.id == bill.id ? accent.opacity(0.08) : cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedBill?.id == bill.id ? accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Find Matches Button

    private var findMatchesButton: some View {
        Button {
            Task { await findMatches() }
        } label: {
            HStack {
                if matchingService.isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "magnifyingglass")
                    Text("Find Mirror Partners")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(accent)
            .cornerRadius(12)
        }
        .disabled(matchingService.isSearching)
    }

    // MARK: - Match Results

    private var matchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Partners")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                Text("\(matchingService.availableMatches.count) found")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
            }

            if matchingService.availableMatches.isEmpty {
                noMatchesState
            } else {
                VStack(spacing: 12) {
                    ForEach(matchingService.availableMatches) { match in
                        matchCard(match)
                    }
                }
            }
        }
    }

    private var noMatchesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 32))
                .foregroundColor(secondaryText.opacity(0.5))

            Text("No Matches Found")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(primaryText)

            Text("Try again later or adjust your bill selection")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .cornerRadius(12)
    }

    private func matchCard(_ match: MatchedPartner) -> some View {
        VStack(spacing: 0) {
            // Partner header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(match.partnerInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(match.partnerHandle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryText)

                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", match.partnerRating))
                                .font(.system(size: 12))
                                .foregroundColor(secondaryText)
                        }

                        Text("\(match.partnerSuccessfulSwaps) swaps")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                // Match score
                VStack(spacing: 2) {
                    Text("\(Int(match.matchScore * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accent)
                    Text("match")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryText)
                }
            }
            .padding()

            Divider()

            // Bill details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Their Bill")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text(match.partnerBillProvider ?? "Unknown")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(accent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text(String(format: "$%.2f", match.partnerAmount))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryText)
                }
            }
            .padding()
            .background(background)

            // Execution window
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                Text("Swap window: \(formatDate(match.executionWindowStart))")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Action button
            Button {
                Task { await confirmMatch(match) }
            } label: {
                Text("Start Swap")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(accent)
            }
        }
        .background(cardBg)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helper Methods

    private func loadData() async {
        try? await portfolioService.loadPortfolio()
        try? await trustService.fetchOrInitializeTrustStatus()
    }

    private func findMatches() async {
        guard let bill = selectedBill,
              let payday = portfolioService.paydaySchedule,
              let tier = trustService.userTrustStatus?.tier else {
            errorMessage = "Please complete your profile setup first"
            showingError = true
            return
        }

        do {
            _ = try await matchingService.findMirrorPartners(
                for: bill,
                payday: payday,
                tier: tier
            )
            withAnimation {
                showingMatchResults = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func confirmMatch(_ match: MatchedPartner) async {
        guard let bill = selectedBill else { return }

        do {
            let swap = try await matchingService.confirmMatch(match, myBill: bill)
            createdSwap = swap
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func ordinalDay(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// Note: Swap already conforms to Identifiable in TrustLadderModels.swift

// MARK: - Preview

#Preview {
    FindMatchView()
}
