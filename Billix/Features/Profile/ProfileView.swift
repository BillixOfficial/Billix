//
//  ProfileView.swift
//  Billix
//
//  Created by Billix Team
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.billixLightGreen
                    .ignoresSafeArea()

                // Main content
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Profile Header
                        if let profile = viewModel.userProfile {
                            ProfileHeaderView(
                                profile: profile,
                                onEditTap: {
                                    viewModel.showEditProfile = true
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }

                        // MARK: - Billix Credits & Rewards
                        if let credits = viewModel.credits {
                            creditsSection(credits)
                        }

                        // MARK: - Bill Health Snapshot
                        if let billHealth = viewModel.billHealth {
                            billHealthSection(billHealth)
                        }

                        // MARK: - Goals & Focus Areas
                        goalsSection()

                        // MARK: - Data Sources & Connections
                        dataConnectionsSection()

                        // MARK: - Marketplace & Privacy
                        marketplaceSection()

                        // MARK: - Notification Preferences
                        notificationsSection()

                        // MARK: - Security & Account
                        securitySection()

                        // MARK: - Help & About
                        helpSection()

                        // Bottom padding for tab bar
                        Spacer().frame(height: 97)
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await viewModel.refresh()
                }

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.billixMoneyGreen)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    // MARK: - Credits Section
    @ViewBuilder
    private func creditsSection(_ credits: BillixCredits) -> some View {
        ProfileSectionCard {
            ProfileSectionHeader("Billix Credits & Rewards", icon: "star.fill")

            VStack(alignment: .leading, spacing: 16) {
                // Balance
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Balance")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        Text("\(credits.balance)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color.billixGoldenAmber)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.showCreditsDetail = true
                    }) {
                        Text("View All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }
                .padding(.horizontal, 16)

                // Recent transactions
                if !credits.recentTransactions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(credits.recentTransactions.prefix(3))) { transaction in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)

                                    Text(transaction.formattedDate)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Text(transaction.amountString)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(
                                        transaction.amount >= 0 ? .billixMoneyGreen : .red
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                            if transaction.id != credits.recentTransactions.prefix(3).last?.id {
                                ProfileDivider()
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Bill Health Section
    @ViewBuilder
    private func billHealthSection(_ billHealth: BillHealthSnapshot) -> some View {
        ProfileSectionCard {
            ProfileSectionHeader("Bill Health", icon: "heart.text.square.fill")

            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // Grade badge
                    ZStack {
                        Circle()
                            .fill(gradeColor(billHealth.overallGrade))
                            .frame(width: 70, height: 70)

                        Text(billHealth.overallGrade)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly Bills:")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Spacer()

                            Text(billHealth.monthlyBillsString)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        HStack {
                            Text("Est. Savings:")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Spacer()

                            Text(billHealth.estimatedSavingsString)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Category coverage
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Coverage")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        ForEach(billHealth.categoriesCovered) { category in
                            VStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.billixMoneyGreen)

                                Text(category.name.split(separator: " ").first ?? "")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Goals Section
    @ViewBuilder
    private func goalsSection() -> some View {
        ProfileSectionCard {
            ProfileSectionHeader("Goals & Focus Areas", icon: "target")

            VStack(spacing: 0) {
                // Savings goal
                if let goal = viewModel.savingsGoal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly Savings Goal")
                                .font(.system(size: 14, weight: .medium))

                            Spacer()

                            Text(goal.targetString + "/mo")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }

                        // Progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.billixMoneyGreen)
                                .frame(width: CGFloat(goal.progress) * (UIScreen.main.bounds.width - 64), height: 8)
                        }

                        Text("\(goal.progressPercentage)% of goal (\(goal.currentString) saved)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    ProfileDivider()
                }

                // Focus areas
                ForEach(viewModel.focusAreas) { area in
                    SettingsToggleRow(
                        title: area.title,
                        icon: area.icon,
                        iconColor: .billixPurple,
                        isOn: Binding(
                            get: { area.isEnabled },
                            set: { _ in
                                Task {
                                    await viewModel.toggleFocusArea(area)
                                }
                            }
                        )
                    )

                    if area.id != viewModel.focusAreas.last?.id {
                        ProfileDivider()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Data Connections Section
    @ViewBuilder
    private func dataConnectionsSection() -> some View {
        ProfileSectionCard {
            ProfileSectionHeader("Data Sources & Connections", icon: "link")

            VStack(spacing: 0) {
                // Email ingestion
                if let ingestion = viewModel.dataConnection?.ingestionChannels {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Bills To:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)

                            Text(ingestion.emailAddress)
                                .font(.system(size: 14))
                                .foregroundColor(.billixMoneyGreen)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.copyToClipboard(
                                ingestion.emailAddress,
                                message: "Email address copied!"
                            )
                        }) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    ProfileDivider()

                    // SMS ingestion
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text Bills To:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)

                            Text(ingestion.smsNumber)
                                .font(.system(size: 14))
                                .foregroundColor(.billixMoneyGreen)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.copyToClipboard(
                                ingestion.smsNumber,
                                message: "Phone number copied!"
                            )
                        }) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.billixMoneyGreen)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    ProfileDivider()

                    // Uploads
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.billixMoneyGreen)
                            .frame(width: 28)

                        Text(ingestion.uploadsText)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Marketplace Section
    @ViewBuilder
    private func marketplaceSection() -> some View {
        if let settings = viewModel.marketplaceSettings {
            ProfileSectionCard {
                ProfileSectionHeader("Marketplace & Privacy", icon: "chart.bar.xaxis")

                VStack(spacing: 0) {
                    SettingsToggleRow(
                        title: "Marketplace Participation",
                        subtitle: "Help others see what real people pay in your area",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .billixPurple,
                        isOn: Binding(
                            get: { settings.isMarketplaceEnabled },
                            set: { newValue in
                                var updated = settings
                                updated.isMarketplaceEnabled = newValue
                                Task {
                                    await viewModel.updateMarketplaceSettings(updated)
                                }
                            }
                        )
                    )

                    if settings.isMarketplaceEnabled {
                        ProfileDivider()

                        HStack {
                            Text("You appear as:")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Spacer()

                            Text(settings.anonymityDescription)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.billixMoneyGreen)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Notifications Section
    @ViewBuilder
    private func notificationsSection() -> some View {
        ProfileSectionCard {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Notification Preferences",
                    subtitle: "Manage alerts and updates",
                    icon: "bell.fill",
                    iconColor: .billixGoldenAmber,
                    action: {
                        viewModel.showNotificationSettings = true
                    }
                )
            }
        }
    }

    // MARK: - Security Section
    @ViewBuilder
    private func securitySection() -> some View {
        ProfileSectionCard {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Security & Account",
                    subtitle: "Password, 2FA, and devices",
                    icon: "lock.fill",
                    iconColor: .red,
                    action: {
                        viewModel.showSecuritySettings = true
                    }
                )
            }
        }
    }

    // MARK: - Help Section
    @ViewBuilder
    private func helpSection() -> some View {
        ProfileSectionCard {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Help Center",
                    subtitle: "Get help and support",
                    icon: "questionmark.circle.fill",
                    action: {
                        // Open help center
                    }
                )

                ProfileDivider()

                SettingsRow(
                    title: "Terms of Service",
                    icon: "doc.text.fill",
                    action: {
                        // Open terms
                    }
                )

                ProfileDivider()

                SettingsRow(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    action: {
                        // Open privacy policy
                    }
                )

                ProfileDivider()

                HStack {
                    Text("App Version")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Spacer()

                    Text("1.0.0")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        case "D": return .orange
        case "F": return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
