//
//  AnalysisSaveMoneyTab.swift
//  Billix
//
//  Created by Claude Code on 12/1/25.
//  Save Money tab with assistance programs and savings recommendations
//

import SwiftUI

// MARK: - Main Tab Container

struct AnalysisSaveMoneyTab: View {
    let analysis: BillAnalysis

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section 1: Get Help Paying (if programs exist)
                if let programs = analysis.assistancePrograms, !programs.isEmpty {
                    GetHelpPayingSection(
                        programs: programs,
                        zipPrefix: analysis.marketplaceComparison?.zipPrefix
                    )
                }

                // Section 2: Ways to Save Money (reuse existing)
                if let actionItems = analysis.savingsOpportunities, !actionItems.isEmpty {
                    WaysToSaveSection(actionItems: actionItems)
                }

                // Legal disclaimer at bottom
                LegalDisclaimerView()

                // Extra padding for done button
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Get Help Paying Section

struct GetHelpPayingSection: View {
    let programs: [BillAnalysis.AssistanceProgram]
    let zipPrefix: String?
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixVotePink)

                Text("Get Help Paying")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.billixDarkGreen)

                Spacer()

                // ZIP prefix badge
                if let zipPrefix = zipPrefix {
                    Text("\(zipPrefix) area")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.billixChartBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.billixChartBlue.opacity(0.12))
                        )
                }
            }

            Text("Programs and resources available in your area")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.billixMediumGreen)

            // Program cards
            VStack(spacing: 12) {
                ForEach(programs) { program in
                    AssistanceProgramCard(program: program)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.billixChartBlue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixChartBlue.opacity(0.2), lineWidth: 1.5)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Assistance Program Card

struct AssistanceProgramCard: View {
    let program: BillAnalysis.AssistanceProgram
    @State private var isDescriptionExpanded = false
    @State private var isEligibilityExpanded = false

    private var programTypeColor: Color {
        switch program.programType {
        case .government: return .billixChartBlue
        case .utility: return .billixMoneyGreen
        case .local: return .purple
        case .nonprofit: return .billixMoneyGreen
        }
    }

    private var programTypeIcon: String {
        switch program.programType {
        case .government: return "building.columns.fill"
        case .utility: return "bolt.fill"
        case .local: return "mappin.circle.fill"
        case .nonprofit: return "heart.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Program type badge + title
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: programTypeIcon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(programTypeColor)

                    Text(program.programType.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(programTypeColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(programTypeColor.opacity(0.12))
                )

                // Title
                Text(program.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.billixDarkGreen)
                    .fixedSize(horizontal: false, vertical: true)

                // Provider
                Text(program.provider)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
            }

            // Estimated Benefit - Prominent
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixMoneyGreen)

                Text(program.estimatedBenefit)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.billixMoneyGreen.opacity(0.1))
            )

            // Description - Expandable
            VStack(alignment: .leading, spacing: 6) {
                Text(program.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(isDescriptionExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if program.description.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDescriptionExpanded.toggle()
                        }
                    }) {
                        Text(isDescriptionExpanded ? "Show less" : "Read more")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixChartBlue)
                    }
                }
            }

            // Eligibility - Expandable
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEligibilityExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.billixChartBlue)

                        Text("Eligibility Requirements")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)

                        Spacer()

                        Image(systemName: isEligibilityExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.billixMediumGreen)
                    }
                }

                if isEligibilityExpanded {
                    Text(program.eligibility)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                        .padding(.leading, 18)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.billixChartBlue.opacity(0.05))
            )

            // Action Buttons
            HStack(spacing: 10) {
                // Apply Online button
                if let applicationUrl = program.applicationUrl,
                   let url = URL(string: applicationUrl) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 14))
                            Text("Apply Online")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.billixChartBlue, Color.billixChartBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }

                // Call Now button
                if let phoneNumber = program.phoneNumber,
                   let url = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: ""))") {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                            Text("Call Now")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.billixChartBlue)
                        .frame(maxWidth: program.applicationUrl == nil ? .infinity : nil)
                        .frame(height: 44)
                        .padding(.horizontal, program.applicationUrl == nil ? 0 : 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.billixChartBlue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.billixChartBlue, lineWidth: 1.5)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.billixChartBlue.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Legal Disclaimer View

struct LegalDisclaimerView: View {
    @State private var isExpanded = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixMediumGreen)

                    Text("About Savings Estimates")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            if isExpanded {
                Text("Savings estimates are based on available data, industry averages, and typical usage patterns. Actual savings may vary based on your specific circumstances, usage habits, location, and other factors. These are estimates only and not guarantees. For assistance programs, eligibility requirements are determined by the program administrators.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.billixMediumGreen)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.billixMediumGreen.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.billixMediumGreen.opacity(0.15), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                appeared = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Save Money Tab - With Programs") {
    let mockPrograms = [
        BillAnalysis.AssistanceProgram(
            title: "Low Income Home Energy Assistance Program (LIHEAP)",
            description: "Federal program helping with heating and cooling costs for eligible households across the United States.",
            programType: .government,
            eligibility: "Household income at or below 150% of federal poverty level",
            applicationUrl: "https://www.acf.hhs.gov/ocs/liheap",
            phoneNumber: "800-677-1116",
            estimatedBenefit: "$100-$500/year",
            provider: "U.S. Department of Health and Human Services"
        ),
        BillAnalysis.AssistanceProgram(
            title: "DTE Energy Assistance Fund",
            description: "Emergency assistance for DTE customers facing financial hardship",
            programType: .utility,
            eligibility: "DTE customers with past-due balance or demonstrated financial need",
            applicationUrl: "https://www.dteenergy.com/assistance",
            phoneNumber: "800-477-4747",
            estimatedBenefit: "Up to $200/year",
            provider: "DTE Energy"
        ),
        BillAnalysis.AssistanceProgram(
            title: "United Way 211 - Utility Assistance",
            description: "Connects you to local charities and nonprofits offering utility bill help in your area",
            programType: .local,
            eligibility: "Varies by organization, typically income-based",
            applicationUrl: nil,
            phoneNumber: "211",
            estimatedBenefit: "Varies by program",
            provider: "United Way"
        )
    ]

    let mockAnalysis = BillAnalysis(
        provider: "DTE Energy",
        amount: 142.50,
        billDate: "2024-11-01",
        dueDate: "2024-11-15",
        accountNumber: "1234567890",
        category: "Electric",
        zipCode: "48127",
        keyFacts: nil,
        lineItems: [],
        costBreakdown: nil,
        insights: nil,
        marketplaceComparison: BillAnalysis.MarketplaceComparison(
            areaAverage: 120.0,
            percentDiff: 18.75,
            zipPrefix: "481",
            position: .above,
            state: "MI",
            sampleSize: 42
        ),
        plainEnglishSummary: nil,
        redFlags: nil,
        controllableCosts: nil,
        savingsOpportunities: [
            BillAnalysis.ActionItem(
                action: "Switch to time-of-use electricity plan",
                explanation: "Save during off-peak hours",
                potentialSavings: 25,
                difficulty: "easy",
                category: "provider-option"
            )
        ],
        jargonGlossary: nil,
        assistancePrograms: mockPrograms
    )

    return AnalysisSaveMoneyTab(analysis: mockAnalysis)
}
