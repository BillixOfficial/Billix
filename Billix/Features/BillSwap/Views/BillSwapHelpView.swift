//
//  BillSwapHelpView.swift
//  Billix
//
//  Comprehensive help view for BillSwap feature
//  Contains 5 sections: Overview, How It Works, Tiers, Safety, FAQ
//

import SwiftUI

struct BillSwapHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection

    init(initialSection: HelpSection = .overview) {
        _selectedSection = State(initialValue: initialSection)
    }

    enum HelpSection: String, CaseIterable {
        case overview = "Overview"
        case howItWorks = "How It Works"
        case tiers = "Tiers"
        case safety = "Safety"
        case faq = "FAQ"

        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .howItWorks: return "arrow.left.arrow.right"
            case .tiers: return "star.fill"
            case .safety: return "shield.checkmark.fill"
            case .faq: return "questionmark.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section picker
                sectionPicker

                // Content
                ScrollView {
                    switch selectedSection {
                    case .overview:
                        overviewSection
                    case .howItWorks:
                        howItWorksSection
                    case .tiers:
                        tiersSection
                    case .safety:
                        safetySection
                    case .faq:
                        faqSection
                    }
                }
            }
            .background(SwapTheme.Colors.background)
            .navigationTitle("BillSwap Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(SwapTheme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HelpSection.allCases, id: \.self) { section in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                if selectedSection == section {
                                    Circle()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(width: 28, height: 28)
                                }
                                Image(systemName: section.icon)
                                    .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                            }
                            Text(section.rawValue)
                                .font(.system(size: 13, weight: selectedSection == section ? .semibold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedSection == section {
                                    LinearGradient(
                                        colors: [SwapTheme.Colors.primary, SwapTheme.Colors.primary.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color(SwapTheme.Colors.secondaryBackground)
                                }
                            }
                        )
                        .foregroundColor(
                            selectedSection == section ? .white : SwapTheme.Colors.primaryText
                        )
                        .cornerRadius(14)
                        .shadow(
                            color: selectedSection == section ? SwapTheme.Colors.primary.opacity(0.3) : Color.clear,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                    }
                }
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)
            .padding(.vertical, 14)
        }
        .background(
            SwapTheme.Colors.background
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.xl) {
            // Hero section with gradient
            VStack(spacing: 20) {
                // Animated icon with gradient glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [SwapTheme.Colors.primary.opacity(0.25), SwapTheme.Colors.primary.opacity(0.05)],
                                center: .center,
                                startRadius: 35,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Inner gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SwapTheme.Colors.primary.opacity(0.2), SwapTheme.Colors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    // Icon
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SwapTheme.Colors.primary, SwapTheme.Colors.primary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: 12) {
                    Text("Welcome to BillSwap")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(SwapTheme.Colors.primaryText)

                    Text("Exchange bills with other users and help each other manage payments. Build trust, earn rewards, and unlock higher limits.")
                        .font(.system(size: 15))
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [SwapTheme.Colors.primary.opacity(0.06), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [SwapTheme.Colors.primary.opacity(0.2), SwapTheme.Colors.primary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )

            // Key benefits with enhanced cards
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(SwapTheme.Colors.gold)
                    Text("KEY BENEFITS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                        .tracking(1)
                }

                VStack(spacing: 10) {
                    benefitRow(icon: "clock.fill", title: "Flexible Timing", description: "Help now, get helped later", color: Color.blue)
                    benefitRow(icon: "shield.fill", title: "Built-in Safety", description: "Verified bills and proof-based checkpoints", color: SwapTheme.Colors.success)
                    benefitRow(icon: "star.fill", title: "Earn Trust", description: "Build reputation for higher limits", color: SwapTheme.Colors.gold)
                    benefitRow(icon: "person.2.fill", title: "Community", description: "Help others while helping yourself", color: Color(hex: "#9B7EB8"))
                }
            }
            .padding(SwapTheme.Spacing.lg)
            .background(SwapTheme.Colors.secondaryBackground)
            .cornerRadius(SwapTheme.CornerRadius.large)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, SwapTheme.Spacing.lg)
        .padding(.top, 10)
    }

    private func benefitRow(icon: String, title: String, description: String, color: Color = SwapTheme.Colors.primary) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SwapTheme.Colors.primaryText)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.xl) {
            // Section header
            Text("Follow these steps to complete a successful swap")
                .font(SwapTheme.Typography.subheadline)
                .foregroundColor(SwapTheme.Colors.secondaryText)
                .padding(.horizontal, SwapTheme.Spacing.lg)
                .padding(.top, SwapTheme.Spacing.lg)

            VStack(spacing: SwapTheme.Spacing.lg) {
                detailedStep(
                    number: 1,
                    title: "Upload Your Bill",
                    description: "Scan or photograph your bill. Our OCR technology extracts and verifies the details automatically.",
                    details: [
                        "Supported: Utilities, insurance, phone, internet, subscriptions",
                        "We extract: Amount, due date, provider, account number",
                        "Verified bills get matched faster"
                    ],
                    icon: "doc.viewfinder"
                )

                detailedStep(
                    number: 2,
                    title: "Get Matched",
                    description: "We find someone with a similar bill amount in the same category.",
                    details: [
                        "Bills are matched within 10% of your amount",
                        "Same bill category required (e.g., electric with electric)",
                        "Both amounts must be within each user's tier limit"
                    ],
                    icon: "person.2.fill"
                )

                detailedStep(
                    number: 3,
                    title: "Review & Agree",
                    description: "Review your match and agree to the swap terms before proceeding.",
                    details: [
                        "Check your partner's trust score and history",
                        "Review the bill amounts and due dates",
                        "Both parties must accept to proceed"
                    ],
                    icon: "checkmark.shield"
                )

                detailedStep(
                    number: 4,
                    title: "Commit to Swap",
                    description: "Lock in the swap by confirming your commitment.",
                    details: [
                        "Commitment creates accountability",
                        "Backing out affects your trust score",
                        "Clear timelines are established"
                    ],
                    icon: "lock.fill"
                )

                detailedStep(
                    number: 5,
                    title: "Pay Each Other's Bills",
                    description: "Use the guest pay link to pay your partner's bill, then upload proof.",
                    details: [
                        "Use the provided guest pay link",
                        "Take a screenshot of your payment confirmation",
                        "Upload proof to verify completion"
                    ],
                    icon: "creditcard.fill"
                )

                detailedStep(
                    number: 6,
                    title: "Verify & Earn",
                    description: "Both parties confirm receipt, and you earn trust score and tier progress.",
                    details: [
                        "Confirm when your bill is paid",
                        "+2 Billix Score per successful swap",
                        "Progress toward next tier"
                    ],
                    icon: "star.fill"
                )
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)

            Spacer(minLength: 40)
        }
    }

    private func detailedStep(number: Int, title: String, description: String, details: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.md) {
            // Header
            HStack(spacing: SwapTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(SwapTheme.Colors.primary)
                        .frame(width: 32, height: 32)

                    Text("\(number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(SwapTheme.Colors.primary)

                Text(title)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)
            }

            // Description
            Text(description)
                .font(SwapTheme.Typography.subheadline)
                .foregroundColor(SwapTheme.Colors.secondaryText)
                .padding(.leading, 44)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                ForEach(details, id: \.self) { detail in
                    HStack(alignment: .top, spacing: SwapTheme.Spacing.sm) {
                        Circle()
                            .fill(SwapTheme.Colors.success)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(detail)
                            .font(SwapTheme.Typography.caption)
                            .foregroundColor(SwapTheme.Colors.secondaryText)
                    }
                }
            }
            .padding(.leading, 44)
        }
        .padding(SwapTheme.Spacing.lg)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    // MARK: - Tiers Section

    private var tiersSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.xl) {
            // Introduction
            VStack(alignment: .leading, spacing: SwapTheme.Spacing.sm) {
                Text("Your swap limit grows with trust")
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text("Complete successful swaps to unlock higher limits and prove your reliability.")
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)
            .padding(.top, SwapTheme.Spacing.lg)

            // Tier cards
            VStack(spacing: SwapTheme.Spacing.md) {
                ForEach(1...4, id: \.self) { tier in
                    tierDetailCard(tier: tier)
                }
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)

            // Tips section
            VStack(alignment: .leading, spacing: SwapTheme.Spacing.md) {
                Text("TIPS FOR FASTER PROGRESSION")
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
                    .tracking(1)

                tipRow(icon: "clock.fill", tip: "Complete swaps promptly - delays hurt your score")
                tipRow(icon: "camera.fill", tip: "Always upload clear proof screenshots")
                tipRow(icon: "checkmark.seal.fill", tip: "Verify your bills with OCR for faster matching")
                tipRow(icon: "star.fill", tip: "Consistent activity builds trust faster")
            }
            .padding(SwapTheme.Spacing.lg)
            .background(SwapTheme.Colors.gold.opacity(0.1))
            .cornerRadius(SwapTheme.CornerRadius.large)
            .padding(.horizontal, SwapTheme.Spacing.lg)

            Spacer(minLength: 40)
        }
    }

    private func tierDetailCard(tier: Int) -> some View {
        let tierColor = SwapTheme.Tiers.tierColor(tier)
        let limit = SwapTheme.Tiers.maxAmount(for: tier)
        let required = SwapTheme.Tiers.requiredSwaps(for: tier)

        return VStack(alignment: .leading, spacing: SwapTheme.Spacing.md) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: SwapTheme.Tiers.tierIcon(tier))
                        .font(.system(size: 20))
                        .foregroundColor(tierColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Tier \(tier)")
                            .font(SwapTheme.Typography.headline)
                            .foregroundColor(SwapTheme.Colors.primaryText)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(SwapTheme.Tiers.tierName(tier))
                            .font(SwapTheme.Typography.subheadline)
                            .foregroundColor(tierColor)
                    }

                    Text(required == 0 ? "Starting tier" : "\(required) successful swaps required")
                        .font(SwapTheme.Typography.caption)
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                }

                Spacer()

                // Limit badge
                Text("$\(limit)")
                    .font(SwapTheme.Typography.amountSmall)
                    .foregroundColor(tierColor)
            }

            // Description
            Text(SwapTheme.Tiers.tierDescription(tier))
                .font(SwapTheme.Typography.caption)
                .foregroundColor(SwapTheme.Colors.secondaryText)

            // Tier tip
            if tier > 1 {
                HStack(alignment: .top, spacing: SwapTheme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SwapTheme.Colors.gold)

                    Text(SwapTheme.Tiers.tierTip(tier))
                        .font(SwapTheme.Typography.caption)
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                }
                .padding(SwapTheme.Spacing.sm)
                .background(SwapTheme.Colors.gold.opacity(0.1))
                .cornerRadius(SwapTheme.CornerRadius.small)
            }
        }
        .padding(SwapTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [tierColor.opacity(0.08), SwapTheme.Colors.secondaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(SwapTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: SwapTheme.CornerRadius.medium)
                .stroke(tierColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func tipRow(icon: String, tip: String) -> some View {
        HStack(alignment: .top, spacing: SwapTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SwapTheme.Colors.gold)
                .frame(width: 20)

            Text(tip)
                .font(SwapTheme.Typography.caption)
                .foregroundColor(SwapTheme.Colors.primaryText)
        }
    }

    // MARK: - Safety Section

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.xl) {
            // Header
            VStack(alignment: .leading, spacing: SwapTheme.Spacing.sm) {
                HStack(spacing: SwapTheme.Spacing.sm) {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SwapTheme.Colors.success)

                    Text("Built for Safety")
                        .font(SwapTheme.Typography.title3)
                        .foregroundColor(SwapTheme.Colors.primaryText)
                }

                Text("Multiple layers of protection keep you safe in every swap.")
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)
            .padding(.top, SwapTheme.Spacing.lg)

            // Safety features
            VStack(spacing: SwapTheme.Spacing.md) {
                safetyFeatureCard(
                    icon: "checkmark.seal.fill",
                    title: "Verified Bills",
                    description: "OCR technology scans and verifies bill authenticity before matching."
                )

                safetyFeatureCard(
                    icon: "doc.text.image.fill",
                    title: "Proof-Based Checkpoints",
                    description: "Payment screenshots are required to verify each step was completed."
                )

                safetyFeatureCard(
                    icon: "clock.badge.checkmark.fill",
                    title: "Time-Bound Progress",
                    description: "Clear deadlines keep swaps moving and protect both parties."
                )

                safetyFeatureCard(
                    icon: "star.fill",
                    title: "Trust Scores",
                    description: "Visible reputation helps you choose reliable swap partners."
                )

                safetyFeatureCard(
                    icon: "lock.shield.fill",
                    title: "Secure Payment Info",
                    description: "Guest pay links let partners pay without accessing your account."
                )
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)

            // Accountability section
            VStack(alignment: .leading, spacing: SwapTheme.Spacing.md) {
                Text("ACCOUNTABILITY")
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
                    .tracking(1)

                consequenceRow(
                    icon: "arrow.down.circle.fill",
                    title: "Missed Deadline",
                    consequence: "Trust tier downgrade",
                    color: SwapTheme.Colors.warning
                )

                consequenceRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Dispute Filed",
                    consequence: "7-day eligibility lock",
                    color: .orange
                )

                consequenceRow(
                    icon: "xmark.circle.fill",
                    title: "Repeated Issues",
                    consequence: "Permanent swap restriction",
                    color: SwapTheme.Colors.danger
                )
            }
            .padding(SwapTheme.Spacing.lg)
            .background(SwapTheme.Colors.secondaryBackground)
            .cornerRadius(SwapTheme.CornerRadius.large)
            .padding(.horizontal, SwapTheme.Spacing.lg)

            Spacer(minLength: 40)
        }
    }

    private func safetyFeatureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: SwapTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(SwapTheme.Colors.success.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(SwapTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(description)
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(SwapTheme.Spacing.md)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.medium)
    }

    private func consequenceRow(icon: String, title: String, consequence: String, color: Color) -> some View {
        HStack(spacing: SwapTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SwapTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(consequence)
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(color)
            }

            Spacer()
        }
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: SwapTheme.Spacing.lg) {
            // FAQ Header with visual design
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: "questionmark.bubble.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Common Questions")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(SwapTheme.Colors.primaryText)
                        Text("Tap any question to see the answer")
                            .font(.system(size: 13))
                            .foregroundColor(SwapTheme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)
            .padding(.top, SwapTheme.Spacing.lg)

            VStack(spacing: 0) {
                FAQItem(
                    question: "What happens if my swap partner doesn't pay my bill?",
                    answer: "If your partner misses the deadline, you can file a dispute. Their trust score will be affected, and our support team will help resolve the situation. Their eligibility for future swaps may be restricted."
                )

                FAQItem(
                    question: "How long do I have to complete a swap?",
                    answer: "Timelines are agreed upon when you accept a match, typically 3-7 days. You'll see clear deadlines in your active swap details. Extensions can be requested in some cases."
                )

                FAQItem(
                    question: "Can I cancel a swap after starting?",
                    answer: "You can cancel before both parties commit, but canceling after commitment affects your trust score. Communicate with your partner if you're having issues - many problems can be resolved together."
                )

                FAQItem(
                    question: "Why is my bill limit lower than my friend's?",
                    answer: "Limits are based on your trust tier, which increases as you complete successful swaps. New users start at Tier 1 ($25 limit) and can reach Tier 4 ($150 limit) through consistent, reliable swapping."
                )

                FAQItem(
                    question: "What bills can I swap?",
                    answer: "You can swap utility bills (electric, gas, water), insurance payments, phone/internet bills, and streaming subscriptions. Bills must be verifiable and within your tier limit."
                )

                FAQItem(
                    question: "Is my payment information secure?",
                    answer: "Yes. We use guest pay links that let your partner pay your bill without accessing your account credentials. Your login information is never shared."
                )

                FAQItem(
                    question: "How do I report a problem?",
                    answer: "Use the dispute button in your active swap details, or contact our support team through the app. We review all disputes within 24 hours."
                )

                FAQItem(
                    question: "What is a Billix Score?",
                    answer: "Your Billix Score is a trust rating (0-100) that reflects your swap history. Successful swaps increase it (+2 per swap), while issues decrease it. Higher scores make you more attractive to potential partners."
                )

                FAQItem(
                    question: "Can I swap bills with anyone?",
                    answer: "You can swap with anyone whose bill matches your criteria and whose amount is within both users' tier limits. Geographic location doesn't matter for most bills."
                )

                FAQItem(
                    question: "What if I upload a fake bill?",
                    answer: "Our OCR verification helps detect fraudulent bills. Attempting to swap fake bills will result in immediate account suspension and potential legal action."
                )
            }
            .padding(.horizontal, SwapTheme.Spacing.lg)

            Spacer(minLength: 40)
        }
    }
}

// MARK: - FAQ Item

private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Question indicator
                    ZStack {
                        Circle()
                            .fill(isExpanded ? SwapTheme.Colors.primary.opacity(0.12) : Color(.systemGray5))
                            .frame(width: 28, height: 28)

                        Text("Q")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isExpanded ? SwapTheme.Colors.primary : SwapTheme.Colors.secondaryText)
                    }

                    Text(question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SwapTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)

                    Spacer()

                    // Expand indicator
                    ZStack {
                        Circle()
                            .fill(isExpanded ? SwapTheme.Colors.primary : Color(.systemGray5))
                            .frame(width: 24, height: 24)

                        Image(systemName: isExpanded ? "minus" : "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isExpanded ? .white : SwapTheme.Colors.secondaryText)
                    }
                }
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                HStack(alignment: .top, spacing: 12) {
                    // Answer indicator
                    ZStack {
                        Circle()
                            .fill(SwapTheme.Colors.success.opacity(0.12))
                            .frame(width: 28, height: 28)

                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SwapTheme.Colors.success)
                    }

                    Text(answer)
                        .font(.system(size: 13))
                        .foregroundColor(SwapTheme.Colors.secondaryText)
                        .lineSpacing(5)
                }
                .padding(.bottom, 16)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.leading, 40)
        }
        .padding(.horizontal, 4)
        .background(
            isExpanded ?
            RoundedRectangle(cornerRadius: 12)
                .fill(SwapTheme.Colors.primary.opacity(0.03))
                .padding(.horizontal, -8)
                .padding(.vertical, -4)
            : nil
        )
    }
}

// MARK: - Preview

#Preview("Overview") {
    BillSwapHelpView(initialSection: .overview)
}

#Preview("How It Works") {
    BillSwapHelpView(initialSection: .howItWorks)
}

#Preview("Tiers") {
    BillSwapHelpView(initialSection: .tiers)
}

#Preview("Safety") {
    BillSwapHelpView(initialSection: .safety)
}

#Preview("FAQ") {
    BillSwapHelpView(initialSection: .faq)
}
