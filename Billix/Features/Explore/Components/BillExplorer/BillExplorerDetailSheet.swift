//
//  BillExplorerDetailSheet.swift
//  Billix
//
//  Detail sheet for bill listings with tabs: Details, Community, Actions
//

import SwiftUI

struct BillExplorerDetailSheet: View {
    let listing: ExploreBillListing
    let userVote: VoteType?
    let isBookmarked: Bool
    let questions: [AnonymousQuestion]

    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onBookmark: () -> Void
    let onAskQuestion: (String) -> Void
    let onGetSimilarRates: () -> Void
    let onNegotiationScript: () -> Void
    let onFindSwapMatch: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .details
    @State private var questionText = ""
    @State private var showAskQuestion = false

    enum DetailTab: String, CaseIterable {
        case details = "Details"
        case community = "Community"
        case actions = "Actions"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                tabPicker
                    .padding(.top, 8)

                // Tab content
                TabView(selection: $selectedTab) {
                    detailsTab
                        .tag(DetailTab.details)

                    communityTab
                        .tag(DetailTab.community)

                    actionsTab
                        .tag(DetailTab.actions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationTitle("\(listing.billType.displayName) Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: onBookmark) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
                        }

                        Text(listing.locationDisplay)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))

                        Rectangle()
                            .fill(selectedTab == tab ? Color(hex: "#5B8A6B") : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Details Tab

    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Bill Amount Card
                billAmountCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Provider & Trend Card
                providerCard
                    .padding(.horizontal, 20)

                // Bill-Type Specific Details Card
                BillTypeDetailsCard(listing: listing)
                    .padding(.horizontal, 20)

                // Usage Comparison Bar (if usage data exists)
                if listing.hasUsageData,
                   let usage = listing.usageAmount,
                   let avg = listing.areaAverageUsage,
                   let min = listing.areaMinUsage,
                   let max = listing.areaMaxUsage,
                   let unit = listing.usageUnit {
                    UsageComparisonBar(
                        userValue: usage,
                        areaAverage: avg,
                        areaMin: min,
                        areaMax: max,
                        unit: unit,
                        valuePrefix: ""
                    )
                    .padding(.horizontal, 20)
                }

                // Household Context Card
                if hasHouseholdContext {
                    householdCard
                        .padding(.horizontal, 20)
                }

                // User Note Card
                if let note = listing.userNote, !note.isEmpty {
                    userNoteCard(note)
                        .padding(.horizontal, 20)
                }

                // Interaction Bar
                BillInteractionBar(
                    voteScore: listing.voteScore,
                    tipCount: listing.tipCount,
                    userVote: userVote,
                    isBookmarked: isBookmarked,
                    onUpvote: onUpvote,
                    onDownvote: onDownvote,
                    onBookmark: onBookmark,
                    onMessage: { selectedTab = .community }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var billAmountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Amount
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$\(Int(listing.amount))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("/mo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            // Percentile comparison
            VStack(alignment: .leading, spacing: 8) {
                // Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#E5E9E7"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(percentileColor(listing.percentile))
                            .frame(width: geometry.size.width * CGFloat(100 - listing.percentile) / 100, height: 8)
                    }
                }
                .frame(height: 8)

                if let description = listing.percentileDescription {
                    Text(description)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(percentileColor(listing.percentile))
                }
            }

            // Historical range
            if let range = listing.historicalRange {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text("Historical range: \(range.displayText)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: listing.billType.color).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: listing.billType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: listing.billType.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(listing.provider)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        if listing.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#4CAF7A"))
                        }
                    }

                    Text(listing.billType.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: listing.trend.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: listing.trend.color))

                    Text(listing.trend.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: listing.trend.color))
                }
            }

            Divider()

            HStack {
                Label(listing.locationDisplay, systemImage: "mappin.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Spacer()

                Text("Posted \(listing.timeAgoDisplay)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var hasHouseholdContext: Bool {
        listing.housingType != nil || listing.occupants != nil || listing.squareFootage != nil
    }

    private var householdCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Household Context")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))

            HStack(spacing: 16) {
                if let housing = listing.housingType {
                    contextItem(icon: "house.fill", label: "Type", value: housing.rawValue)
                }

                if let occupants = listing.occupants {
                    contextItem(icon: "person.2.fill", label: "Occupants", value: occupants.rawValue)
                }

                if let sqft = listing.squareFootage {
                    contextItem(icon: "square.dashed", label: "Size", value: sqft.rawValue)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func contextItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#5B8A6B"))

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#8B9A94"))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
        }
        .frame(maxWidth: .infinity)
    }

    private func userNoteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("From \(listing.anonymousId)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            Text(note)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#2D3B35"))
                .italic()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Community Tab

    private var communityTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Ask a question button
                Button {
                    showAskQuestion = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))

                        Text("Ask a Question")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#5B8A6B"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Questions list
                if questions.isEmpty {
                    emptyQuestionsView
                        .padding(.top, 40)
                } else {
                    ForEach(questions) { question in
                        questionCard(question)
                            .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .sheet(isPresented: $showAskQuestion) {
            askQuestionSheet
        }
    }

    private var emptyQuestionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#8B9A94"))

            Text("No questions yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))

            Text("Be the first to ask \(listing.anonymousId) about this bill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8B9A94"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func questionCard(_ question: AnonymousQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#5BA4D4"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(question.askerAnonymousId)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#8B9A94"))

                    Text(question.question)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
            }

            // Answer (if exists)
            if let answer = question.answer {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#4CAF7A"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.anonymousId)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))

                        Text(answer)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }
                }
                .padding(.leading, 16)
            } else {
                Text("Awaiting response...")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .italic()
                    .padding(.leading, 24)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var askQuestionSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Ask \(listing.anonymousId)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                TextEditor(text: $questionText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(hex: "#F7F9F8"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E5E9E7"), lineWidth: 1)
                    )

                Text("Your question will be anonymous")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#8B9A94"))

                Button {
                    if !questionText.isEmpty {
                        onAskQuestion(questionText)
                        questionText = ""
                        showAskQuestion = false
                    }
                } label: {
                    Text("Submit Question")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(questionText.isEmpty ? Color.gray.opacity(0.4) : Color(hex: "#5B8A6B"))
                        .cornerRadius(12)
                }
                .disabled(questionText.isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Ask a Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showAskQuestion = false
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions Tab

    private var actionsTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Get similar rates
                actionButton(
                    icon: "tag.fill",
                    title: "Get Similar Rates",
                    subtitle: "View providers in your area with comparable prices",
                    color: "#5B8A6B",
                    action: onGetSimilarRates
                )

                // Negotiation script
                actionButton(
                    icon: "text.bubble.fill",
                    title: "Negotiation Script",
                    subtitle: "Get a call script for \(listing.provider)",
                    color: "#5BA4D4",
                    action: onNegotiationScript
                )

                // Find BillSwap match
                actionButton(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Find BillSwap Match",
                    subtitle: "Split costs with others in your area",
                    color: "#9B7EB8",
                    action: onFindSwapMatch
                )

                // Report option
                actionButton(
                    icon: "flag.fill",
                    title: "Report Listing",
                    subtitle: "Report inaccurate or inappropriate content",
                    color: "#8B9A94",
                    action: {}
                )
            }
            .padding(20)
        }
    }

    private func actionButton(icon: String, title: String, subtitle: String, color: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func percentileColor(_ percentile: Int) -> Color {
        if percentile <= 30 {
            return Color(hex: "#4CAF7A")
        } else if percentile >= 70 {
            return Color(hex: "#E07A6B")
        } else {
            return Color(hex: "#F5A623")
        }
    }
}

// MARK: - Preview

#Preview {
    BillExplorerDetailSheet(
        listing: ExploreBillListing.mockListings[0],
        userVote: .up,
        isBookmarked: true,
        questions: [
            AnonymousQuestion(
                listingId: UUID(),
                askerAnonymousId: "User #8821",
                question: "How did you get such a low rate?"
            )
        ],
        onUpvote: {},
        onDownvote: {},
        onBookmark: {},
        onAskQuestion: { _ in },
        onGetSimilarRates: {},
        onNegotiationScript: {},
        onFindSwapMatch: {}
    )
}
