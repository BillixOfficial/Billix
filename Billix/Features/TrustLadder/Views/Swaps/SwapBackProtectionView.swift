//
//  SwapBackProtectionView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for managing Swap-Back Protection feature
//

import SwiftUI

struct SwapBackProtectionView: View {
    @StateObject private var protectionService = SwapBackProtectionService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var showActivateSheet = false
    @State private var showClaimSheet = false
    @State private var showUpgradePaywall = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current status card
                statusCard

                // Protection tiers
                if !protectionService.hasActiveProtection {
                    protectionTiersSection
                }

                // Active plan details
                if protectionService.hasActiveProtection, let plan = protectionService.currentPlan {
                    activePlanCard(plan)
                }

                // Claims section
                if protectionService.hasActiveProtection {
                    claimsSection
                }

                // How it works
                howItWorksSection

                // Legal disclaimer
                disclaimerSection
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("Swap-Back Protection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showActivateSheet) {
            ActivateProtectionSheet()
        }
        .sheet(isPresented: $showClaimSheet) {
            FileClaimSheet()
        }
        .sheet(isPresented: $showUpgradePaywall) {
            PaywallView(context: .featureGate(.swapBackProtection))
        }
        .refreshable {
            await protectionService.loadProtectionStatus()
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 16) {
            // Status indicator
            HStack {
                Image(systemName: protectionService.hasActiveProtection ? "shield.checkered" : "shield.slash")
                    .font(.system(size: 32))
                    .foregroundColor(protectionService.hasActiveProtection ? accent : secondaryText)

                VStack(alignment: .leading, spacing: 4) {
                    Text(protectionService.hasActiveProtection ? "Protected" : "Not Protected")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primaryText)

                    if let plan = protectionService.currentPlan {
                        Text("\(plan.daysRemaining) days remaining")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText)
                    } else {
                        Text("Activate protection for peace of mind")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()
            }

            // Action button
            if protectionService.hasActiveProtection {
                Button {
                    showClaimSheet = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("File a Claim")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(10)
                }
            } else if protectionService.currentTier != nil {
                Button {
                    showActivateSheet = true
                } label: {
                    HStack {
                        Image(systemName: "shield.checkered")
                        Text("Activate Protection")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(10)
                }
            } else {
                Button {
                    showUpgradePaywall = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle")
                        Text("Upgrade to Enable")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(protectionService.hasActiveProtection ? accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Protection Tiers Section

    private var protectionTiersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protection Plans")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 10) {
                ForEach(ProtectionTier.allTiers) { tier in
                    protectionTierCard(tier)
                }
            }
        }
    }

    private func protectionTierCard(_ tier: ProtectionTier) -> some View {
        let isCurrentTier = subscriptionService.currentTier == tier.requiredSubscriptionTier
        let hasAccess = subscriptionService.currentTier.rawValue >= tier.requiredSubscriptionTier.rawValue

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(tier.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryText)

                        if isCurrentTier {
                            Text("YOUR PLAN")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accent)
                                .cornerRadius(4)
                        }
                    }

                    Text("Requires \(tier.requiredSubscriptionTier.displayName)")
                        .font(.system(size: 11))
                        .foregroundColor(tier.requiredSubscriptionTier.color)
                }

                Spacer()

                if hasAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accent)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(secondaryText)
                }
            }

            // Tier features
            HStack(spacing: 16) {
                tierFeature(value: "\(tier.monthlySwapsCovered)", label: "Swaps/mo")
                tierFeature(value: tier.formattedMaxCoverage, label: "Max Coverage")
                tierFeature(value: "\(tier.claimsPerYear)", label: "Claims/yr")
            }
        }
        .padding()
        .background(isCurrentTier ? accent.opacity(0.1) : background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentTier ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    private func tierFeature(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(primaryText)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Active Plan Card

    private func activePlanCard(_ plan: ProtectionPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Coverage")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            // Coverage progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Coverage Used")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                    Spacer()
                    Text("\(plan.formattedRemainingCoverage) remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryText)
                }

                ProgressView(value: Double(truncating: plan.usedCoverageAmount as NSDecimalNumber),
                             total: Double(truncating: plan.maxCoverageAmount as NSDecimalNumber))
                    .tint(accent)
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                planStatCard(
                    icon: "calendar",
                    value: "\(plan.daysRemaining)",
                    label: "Days Left",
                    color: .blue
                )

                planStatCard(
                    icon: "doc.text",
                    value: "\(plan.remainingClaims)",
                    label: "Claims Left",
                    color: .purple
                )

                planStatCard(
                    icon: "arrow.left.arrow.right",
                    value: "\(plan.swapsCovered)",
                    label: "Swaps Covered",
                    color: .orange
                )

                planStatCard(
                    icon: "dollarsign.circle",
                    value: plan.formattedMaxCoverage,
                    label: "Max Coverage",
                    color: accent
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func planStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(primaryText)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(background)
        .cornerRadius(10)
    }

    // MARK: - Claims Section

    private var claimsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Claims")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()

                let stats = protectionService.getClaimStatistics()
                HStack(spacing: 8) {
                    claimStat("\(stats.approved)", color: .green)
                    claimStat("\(stats.pending)", color: .orange)
                    claimStat("\(stats.denied)", color: .red)
                }
            }

            if protectionService.claims.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 24))
                            .foregroundColor(secondaryText)
                        Text("No claims yet")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(protectionService.claims.prefix(5)) { claim in
                        claimRow(claim)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func claimStat(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }

    private func claimRow(_ claim: ProtectionClaim) -> some View {
        HStack(spacing: 12) {
            Image(systemName: claim.hardshipReason?.icon ?? "doc")
                .font(.system(size: 14))
                .foregroundColor(claim.claimStatus?.color ?? .gray)
                .frame(width: 28, height: 28)
                .background((claim.claimStatus?.color ?? .gray).opacity(0.15))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(claim.hardshipReason?.displayName ?? "Claim")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)

                Text(claim.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(claim.formattedClaimAmount)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryText)

                Text(claim.claimStatus?.displayName ?? "")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(claim.claimStatus?.color ?? .gray)
            }
        }
        .padding()
        .background(background)
        .cornerRadius(10)
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            VStack(spacing: 10) {
                howItWorksStep(
                    number: 1,
                    title: "Activate Protection",
                    description: "Enable protection with your subscription",
                    icon: "shield.checkered"
                )

                howItWorksStep(
                    number: 2,
                    title: "Complete Swaps",
                    description: "All covered swaps are protected",
                    icon: "arrow.left.arrow.right"
                )

                howItWorksStep(
                    number: 3,
                    title: "Face Hardship",
                    description: "If unexpected events occur",
                    icon: "exclamationmark.triangle"
                )

                howItWorksStep(
                    number: 4,
                    title: "File a Claim",
                    description: "Submit documentation for review",
                    icon: "doc.text"
                )

                howItWorksStep(
                    number: 5,
                    title: "Get Support",
                    description: "Receive assistance for your situation",
                    icon: "hand.raised"
                )
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func howItWorksStep(number: Int, title: String, description: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(secondaryText)
        }
        .padding()
        .background(background)
        .cornerRadius(10)
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundColor(secondaryText)
                Text("Important Notice")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryText)
            }

            Text("Swap-Back Protection is a community support program, not insurance. Claims are reviewed on a case-by-case basis. Coverage limits and eligibility requirements apply. Billix reserves the right to approve or deny claims based on verification of circumstances.")
                .font(.system(size: 11))
                .foregroundColor(secondaryText.opacity(0.8))
                .lineSpacing(2)
        }
        .padding()
        .background(cardBg.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Activate Protection Sheet

struct ActivateProtectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var protectionService = SwapBackProtectionService.shared

    @State private var isActivating = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(accent)
                        .padding(.top, 20)

                    // Title
                    VStack(spacing: 8) {
                        Text("Activate Protection")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(primaryText)

                        Text("Get peace of mind with Swap-Back Protection")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    // Tier info
                    if let tier = protectionService.currentTier {
                        VStack(spacing: 12) {
                            Text(tier.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(primaryText)

                            HStack(spacing: 20) {
                                tierBenefit("\(tier.monthlySwapsCovered)", label: "Swaps/mo")
                                tierBenefit(tier.formattedMaxCoverage, label: "Coverage")
                                tierBenefit("\(tier.claimsPerYear)", label: "Claims/yr")
                            }
                        }
                        .padding()
                        .background(cardBg)
                        .cornerRadius(16)
                    }

                    Spacer()

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(10)
                    }

                    // Activate button
                    Button {
                        activate()
                    } label: {
                        HStack {
                            if isActivating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "checkmark.shield")
                                Text("Activate Now")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .cornerRadius(14)
                    }
                    .disabled(isActivating)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
            }
            .alert("Protection Activated!", isPresented: $showSuccess) {
                Button("Great") {
                    dismiss()
                }
            } message: {
                Text("Your swaps are now protected against financial hardship.")
            }
        }
    }

    private func tierBenefit(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(primaryText)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(secondaryText)
        }
    }

    private func activate() {
        isActivating = true
        errorMessage = nil

        Task {
            do {
                _ = try await protectionService.activateProtection()
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isActivating = false
        }
    }
}

// MARK: - File Claim Sheet

struct FileClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var protectionService = SwapBackProtectionService.shared

    @State private var selectedReason: HardshipReason = .unexpectedExpense
    @State private var reasonDetails: String = ""
    @State private var claimAmount: String = ""
    @State private var isFiling = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Reason selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reason for Claim")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryText)

                            ForEach(HardshipReason.allCases) { reason in
                                reasonButton(reason)
                            }
                        }

                        // Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Details")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryText)

                            TextEditor(text: $reasonDetails)
                                .frame(minHeight: 100)
                                .padding()
                                .background(cardBg)
                                .cornerRadius(12)
                                .foregroundColor(primaryText)
                        }

                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Claim Amount")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryText)

                            HStack {
                                Text("$")
                                    .foregroundColor(secondaryText)
                                TextField("0.00", text: $claimAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(primaryText)
                            }
                            .padding()
                            .background(cardBg)
                            .cornerRadius(12)

                            if let plan = protectionService.currentPlan {
                                Text("Maximum: \(plan.formattedRemainingCoverage)")
                                    .font(.system(size: 11))
                                    .foregroundColor(secondaryText)
                            }
                        }

                        // Documentation notice
                        if selectedReason.requiresDocumentation {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.orange)
                                Text("Documentation may be required for this claim type")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(10)
                        }

                        // Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(10)
                        }

                        // Submit button
                        Button {
                            fileClaim()
                        } label: {
                            HStack {
                                if isFiling {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Claim")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid ? accent : secondaryText)
                            .cornerRadius(14)
                        }
                        .disabled(!isFormValid || isFiling)
                    }
                    .padding()
                }
            }
            .navigationTitle("File a Claim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
            }
            .alert("Claim Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your claim has been submitted for review. We'll notify you once it's been processed.")
            }
        }
    }

    private var isFormValid: Bool {
        guard let amount = Decimal(string: claimAmount), amount > 0 else { return false }
        return true
    }

    private func reasonButton(_ reason: HardshipReason) -> some View {
        let isSelected = selectedReason == reason

        return Button {
            selectedReason = reason
        } label: {
            HStack(spacing: 12) {
                Image(systemName: reason.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .black : secondaryText)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? accent : cardBg)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)

                    Text(reason.description)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accent)
                }
            }
            .padding()
            .background(isSelected ? accent.opacity(0.1) : cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 1)
            )
        }
    }

    private func fileClaim() {
        guard let plan = protectionService.currentPlan,
              let amount = Decimal(string: claimAmount) else { return }

        isFiling = true
        errorMessage = nil

        Task {
            do {
                let request = ClaimRequest(
                    planId: plan.id,
                    swapId: nil,
                    reason: selectedReason,
                    reasonDetails: reasonDetails.isEmpty ? nil : reasonDetails,
                    claimAmount: amount,
                    documentationUrl: nil
                )

                _ = try await protectionService.fileClaim(request)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isFiling = false
        }
    }
}

// MARK: - Compact Protection Widget

struct CompactProtectionWidget: View {
    @StateObject private var protectionService = SwapBackProtectionService.shared

    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationLink {
            SwapBackProtectionView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: protectionService.hasActiveProtection ? "shield.checkered" : "shield.slash")
                    .font(.system(size: 24))
                    .foregroundColor(protectionService.hasActiveProtection ? accent : secondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Swap-Back Protection")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryText)

                    if protectionService.hasActiveProtection, let plan = protectionService.currentPlan {
                        Text("\(plan.daysRemaining) days remaining")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    } else {
                        Text("Not activated")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwapBackProtectionView()
    }
    .preferredColorScheme(.dark)
}
