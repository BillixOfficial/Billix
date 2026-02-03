//
//  TierAdvancementSheet.swift
//  Billix
//
//  Celebration modal shown when users advance to a new tier
//  Includes step-by-step walkthrough to teach users how BillSwap works
//

import SwiftUI

/// Result returned when a swap completion triggers a tier advancement
struct TierAdvancementResult {
    let previousTier: Int
    let newTier: Int
    let swapsCompleted: Int
    let newBillixScore: Int
}

/// Full celebration modal with walkthrough for tier advancement
struct TierAdvancementSheet: View {

    let result: TierAdvancementResult
    @Environment(\.dismiss) private var dismiss
    @State private var currentWalkthroughPage = 0
    @State private var showConfetti = true

    private var tierLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        let limit = SwapTheme.Tiers.maxAmount(for: result.newTier)
        return formatter.string(from: limit as NSDecimalNumber) ?? "$\(limit)"
    }

    private var swapsToNextTier: Int {
        SwapTheme.Tiers.swapsToNextTier(currentTier: result.newTier, completedSwaps: result.swapsCompleted)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    SwapTheme.Tiers.tierColor(result.newTier).opacity(0.15),
                    SwapTheme.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with celebration
                celebrationHeader
                    .padding(.top, SwapTheme.Spacing.lg)

                // Swipeable walkthrough pages
                walkthroughSection
                    .padding(.top, SwapTheme.Spacing.lg)

                // Tier-specific tip card
                tierTipCard
                    .padding(.horizontal, SwapTheme.Spacing.lg)
                    .padding(.top, SwapTheme.Spacing.md)

                Spacer()

                // Continue button
                Button(action: { dismiss() }) {
                    Text("Got It!")
                        .font(SwapTheme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SwapTheme.Spacing.md)
                        .background(SwapTheme.Tiers.tierColor(result.newTier))
                        .cornerRadius(SwapTheme.CornerRadius.medium)
                }
                .padding(.horizontal, SwapTheme.Spacing.lg)
                .padding(.bottom, SwapTheme.Spacing.xxl)
            }

            // Confetti overlay (simplified particles)
            if showConfetti {
                TierConfettiView(color: SwapTheme.Tiers.tierColor(result.newTier))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        // Hide confetti after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                        }
                    }
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: SwapTheme.Spacing.md) {
            // "Level Up!" text
            Text("Level Up!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SwapTheme.Tiers.tierColor(result.newTier))
                .textCase(.uppercase)
                .tracking(2)

            // New tier badge (large)
            ZStack {
                Circle()
                    .fill(SwapTheme.Tiers.tierColor(result.newTier).opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: SwapTheme.Tiers.tierIcon(result.newTier))
                    .font(.system(size: 50))
                    .foregroundColor(SwapTheme.Tiers.tierColor(result.newTier))
            }

            // Tier name
            Text("Tier \(result.newTier): \(SwapTheme.Tiers.tierName(result.newTier))")
                .font(SwapTheme.Typography.title2)
                .foregroundColor(SwapTheme.Colors.primaryText)

            // New limit highlight
            HStack(spacing: SwapTheme.Spacing.sm) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(SwapTheme.Colors.success)
                Text("You can now swap bills up to \(tierLimit)")
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)
            }

            // Billix Score update
            HStack(spacing: SwapTheme.Spacing.sm) {
                Image(systemName: "star.fill")
                    .foregroundColor(SwapTheme.Colors.gold)
                    .font(.system(size: 14))
                Text("Billix Score: \(result.newBillixScore)/100")
                    .font(SwapTheme.Typography.caption)
                    .foregroundColor(SwapTheme.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Walkthrough Section

    private var walkthroughSection: some View {
        VStack(spacing: SwapTheme.Spacing.sm) {
            Text("How BillSwap Works")
                .font(SwapTheme.Typography.headline)
                .foregroundColor(SwapTheme.Colors.primaryText)

            TabView(selection: $currentWalkthroughPage) {
                walkthroughPage(
                    step: 1,
                    icon: "doc.viewfinder",
                    title: "Upload Your Bill",
                    description: "Scan or upload a bill. We verify it with OCR to ensure authenticity."
                ).tag(0)

                walkthroughPage(
                    step: 2,
                    icon: "person.2.fill",
                    title: "Get Matched",
                    description: "We find someone with a similar bill. Both must be within your \(tierLimit) limit."
                ).tag(1)

                walkthroughPage(
                    step: 3,
                    icon: "checkmark.shield",
                    title: "Review & Commit",
                    description: "Review the match and agree to terms. A commitment fee locks in the swap."
                ).tag(2)

                walkthroughPage(
                    step: 4,
                    icon: "arrow.left.arrow.right",
                    title: "Pay Each Other's Bills",
                    description: "You pay their bill, they pay yours. Upload proof screenshots as you go."
                ).tag(3)

                walkthroughPage(
                    step: 5,
                    icon: "star.fill",
                    title: "Complete & Earn",
                    description: "Both confirm payment. You earn +2 Billix Score and progress toward the next tier!"
                ).tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 180)
        }
    }

    private func walkthroughPage(step: Int, icon: String, title: String, description: String) -> some View {
        VStack(spacing: SwapTheme.Spacing.md) {
            // Step number with icon
            HStack(spacing: SwapTheme.Spacing.sm) {
                Text("\(step)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(SwapTheme.Colors.primary)
                    .clipShape(Circle())

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(SwapTheme.Colors.primary)
            }

            // Title
            Text(title)
                .font(SwapTheme.Typography.headline)
                .foregroundColor(SwapTheme.Colors.primaryText)

            // Description
            Text(description)
                .font(SwapTheme.Typography.subheadline)
                .foregroundColor(SwapTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SwapTheme.Spacing.xl)
        }
        .padding(SwapTheme.Spacing.lg)
        .background(SwapTheme.Colors.secondaryBackground)
        .cornerRadius(SwapTheme.CornerRadius.large)
        .padding(.horizontal, SwapTheme.Spacing.lg)
    }

    // MARK: - Tier Tip Card

    private var tierTipCard: some View {
        HStack(alignment: .top, spacing: SwapTheme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(SwapTheme.Colors.gold)

            VStack(alignment: .leading, spacing: SwapTheme.Spacing.xs) {
                Text("Tier \(result.newTier) Tip")
                    .font(SwapTheme.Typography.headline)
                    .foregroundColor(SwapTheme.Colors.primaryText)

                Text(SwapTheme.Tiers.tierTip(result.newTier))
                    .font(SwapTheme.Typography.subheadline)
                    .foregroundColor(SwapTheme.Colors.secondaryText)

                if result.newTier < 4 {
                    Text("\(swapsToNextTier) swaps until Tier \(result.newTier + 1)")
                        .font(SwapTheme.Typography.caption)
                        .foregroundColor(SwapTheme.Colors.tertiaryText)
                        .padding(.top, SwapTheme.Spacing.xs)
                }
            }
        }
        .padding(SwapTheme.Spacing.lg)
        .background(SwapTheme.Colors.gold.opacity(0.1))
        .cornerRadius(SwapTheme.CornerRadius.large)
    }
}

// MARK: - Tier Confetti View (Simplified)

private struct TierConfettiView: View {
    let color: Color
    @State private var particles: [TierConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [color, color.opacity(0.7), .white, SwapTheme.Colors.gold]
        particles = (0..<30).map { _ in
            TierConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? color,
                speed: CGFloat.random(in: 2...5),
                opacity: 1.0,
                targetY: size.height + 50
            )
        }
    }

    private func animateParticles() {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: duration)) {
                    if i < particles.count {
                        particles[i].position.y = particles[i].targetY
                        particles[i].position.x += CGFloat.random(in: -50...50)
                        particles[i].opacity = 0
                    }
                }
            }
        }
    }
}

private struct TierConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let speed: CGFloat
    var opacity: Double
    let targetY: CGFloat
}

// MARK: - Preview

#Preview("Tier 2 Advancement") {
    TierAdvancementSheet(result: TierAdvancementResult(
        previousTier: 1,
        newTier: 2,
        swapsCompleted: 5,
        newBillixScore: 10
    ))
}

#Preview("Tier 4 Advancement") {
    TierAdvancementSheet(result: TierAdvancementResult(
        previousTier: 3,
        newTier: 4,
        swapsCompleted: 35,
        newBillixScore: 70
    ))
}
