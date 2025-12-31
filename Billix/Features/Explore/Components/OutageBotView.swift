//
//  OutageBotView.swift
//  Billix
//
//  Outage Bot - Automatic Credit Recovery for Service Outages
//  Redesigned with Credits Dashboard and Guided Claims Flow
//

import SwiftUI

// MARK: - Outage Bot View

struct OutageBotView: View {
    @StateObject private var viewModel = OutageBotViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Credits Dashboard Header
            creditsDashboard

            // Active Outage Alerts (if any)
            if viewModel.hasActiveOutages {
                outageAlertsBanner
            }

            // Connected Providers
            if viewModel.hasConnections {
                connectedProvidersList
            } else {
                emptyState
            }

            // Recent Claims
            if !viewModel.claims.isEmpty {
                recentClaimsSection
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(MarketplaceTheme.Colors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl))
        .shadow(
            color: MarketplaceTheme.Shadows.medium.color,
            radius: MarketplaceTheme.Shadows.medium.radius,
            x: 0,
            y: MarketplaceTheme.Shadows.medium.y
        )
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
        // Sheets
        .sheet(isPresented: $viewModel.showAddProvider) {
            AddProviderSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $viewModel.showReportOutage) {
            ReportOutageSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
        .sheet(isPresented: $viewModel.showOutageConfirmation) {
            if let detected = viewModel.currentDetectedOutage {
                OutageConfirmationSheet(
                    viewModel: viewModel,
                    detectedOutage: detected
                )
                .presentationDetents([.medium])
                .presentationBackground(Color(hex: "#F5F7F6"))
            }
        }
        // TODO: Add EligibilityResultView when available
        // .sheet(isPresented: $viewModel.showEligibilityResult) {
        //     EligibilityResultView(viewModel: viewModel)
        //         .presentationDetents([.medium, .large])
        //         .presentationBackground(Color(hex: "#F5F7F6"))
        // }
        // TODO: Add GuidedClaimView when available
        // .sheet(isPresented: $viewModel.showGuidedClaim) {
        //     GuidedClaimView(viewModel: viewModel)
        //         .presentationDetents([.large])
        //         .presentationBackground(Color(hex: "#F5F7F6"))
        // }
        .sheet(isPresented: $viewModel.showClaimHistory) {
            ClaimHistorySheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: "#F5F7F6"))
        }
    }

    // MARK: - Credits Dashboard

    private var creditsDashboard: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#8B5CF6"))

                        Text("Outage Bot")
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    }

                    Text("Recover credits when services go down")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Check for outages button
                if viewModel.hasConnections {
                    Button {
                        Task {
                            await viewModel.checkForOutages()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "#8B5CF6"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(hex: "#8B5CF6").opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Stats Cards
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Total Recovered
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#22C55E"))

                        Text("Recovered")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }

                    Text(viewModel.formattedTotalRecovered)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "#22C55E"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(Color(hex: "#22C55E").opacity(0.1))
                )

                // Claims Stats
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#8B5CF6"))

                        Text("Claims")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }

                    Text("\(viewModel.approvedClaimsCount)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    +
                    Text(" approved")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
            }

            // Pending amount (if any)
            if viewModel.pendingClaimsCount > 0 {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#F59E0B"))

                    Text("\(viewModel.pendingClaimsCount) pending")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(Color(hex: "#F59E0B"))

                    Text("(\(viewModel.formattedPendingAmount))")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                    Spacer()

                    Button {
                        viewModel.showClaimHistory = true
                    } label: {
                        Text("View All")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                            .foregroundStyle(Color(hex: "#8B5CF6"))
                    }
                }
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(Color(hex: "#F59E0B").opacity(0.1))
                )
            }
        }
    }

    // MARK: - Outage Alerts Banner

    private var outageAlertsBanner: some View {
        VStack(spacing: MarketplaceTheme.Spacing.xs) {
            ForEach(viewModel.detectedOutages) { detected in
                Button {
                    viewModel.currentDetectedOutage = detected
                    viewModel.showOutageConfirmation = true
                } label: {
                    HStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#EF4444"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Outage detected")
                                .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                            Text("\(detected.connection.providerName) - \(detected.crowdMessage)")
                                .font(.system(size: MarketplaceTheme.Typography.micro))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                    .padding(MarketplaceTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(Color(hex: "#EF4444").opacity(0.1))
                            .stroke(Color(hex: "#EF4444").opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("No providers connected")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Text("Connect your providers to detect outages and recover credits automatically.")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.showAddProvider = true
            } label: {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))

                    Text("Connect Provider")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, MarketplaceTheme.Spacing.lg)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(Color(hex: "#8B5CF6"))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, MarketplaceTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MarketplaceTheme.Spacing.xl)
    }

    // MARK: - Connected Providers

    private var connectedProvidersList: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("Connected Providers")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Button {
                    viewModel.showAddProvider = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }

            ForEach(viewModel.connections) { connection in
                OutageProviderCard(
                    connection: connection,
                    onReportOutage: {
                        viewModel.startReportOutage(for: connection)
                    },
                    onToggle: {
                        Task {
                            await viewModel.toggleMonitoring(for: connection)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Recent Claims

    private var recentClaimsSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("Recent Claims")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Button {
                    viewModel.showClaimHistory = true
                } label: {
                    Text("See All")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }

            ForEach(viewModel.recentClaims) { claim in
                OutageClaimRow(claim: claim) {
                    viewModel.selectClaim(claim)
                }
            }
        }
    }
}

// MARK: - Provider Card

struct OutageProviderCard: View {
    let connection: OutageConnection
    let onReportOutage: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Header row
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Provider icon
                ZStack {
                    Circle()
                        .fill(connection.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: connection.category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(connection.category.color)
                }

                // Provider info
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(connection.category.rawValue)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("•")
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("ZIP \(connection.zipCode)")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Monitoring toggle
                Toggle("", isOn: Binding(
                    get: { connection.isMonitoring },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(Color(hex: "#8B5CF6"))
            }

            // Stats row
            HStack(spacing: MarketplaceTheme.Spacing.md) {
                statItem(
                    label: "Claims",
                    value: "\(connection.claimsCount)",
                    icon: "checkmark.circle"
                )

                statItem(
                    label: "Recovered",
                    value: connection.formattedTotalClaimed,
                    icon: "dollarsign.circle"
                )

                Spacer()

                // Report outage button
                Button {
                    onReportOutage()
                } label: {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 12))

                        Text("Report")
                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                    .padding(.vertical, MarketplaceTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                            .fill(Color(hex: "#8B5CF6").opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )

            // Status indicator
            if connection.isMonitoring {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Circle()
                        .fill(Color(hex: "#22C55E"))
                        .frame(width: 6, height: 6)

                    Text("Monitoring active")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(Color(hex: "#22C55E"))
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .stroke(
                    connection.isMonitoring ? Color(hex: "#8B5CF6").opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .opacity(connection.isMonitoring ? 1.0 : 0.7)
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Claim Row

struct OutageClaimRow: View {
    let claim: OutageClaim
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(claim.status.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: claim.status.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(claim.status.color)
                }

                // Claim info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(claim.providerName)")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(claim.formattedOutageDate)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text("•")
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                        Text(claim.formattedDuration)
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Amount and status
                VStack(alignment: .trailing, spacing: 2) {
                    Text(claim.displayCredit)
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(claim.status == .approved ? Color(hex: "#22C55E") : MarketplaceTheme.Colors.textPrimary)

                    Text(claim.status.displayName)
                        .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                        .foregroundStyle(claim.status.color)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Provider Sheet

struct AddProviderSheet: View {
    @ObservedObject var viewModel: OutageBotViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.lg) {
                    // Category selection
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Service Type")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        HStack(spacing: MarketplaceTheme.Spacing.xs) {
                            ForEach(OutageBillType.allCases, id: \.self) { category in
                                Button {
                                    viewModel.selectedCategory = category
                                    viewModel.selectedProvider = nil
                                } label: {
                                    VStack(spacing: MarketplaceTheme.Spacing.xs) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 20))

                                        Text(category.rawValue)
                                            .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                                    }
                                    .foregroundStyle(viewModel.selectedCategory == category ? .white : MarketplaceTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MarketplaceTheme.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                            .fill(viewModel.selectedCategory == category ? category.color : MarketplaceTheme.Colors.backgroundSecondary)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Provider selection
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Provider")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        let providers = ProviderOption.providers(for: viewModel.selectedCategory)

                        ForEach(providers) { provider in
                            Button {
                                viewModel.selectedProvider = provider
                            } label: {
                                HStack {
                                    Image(systemName: provider.logo)
                                        .font(.system(size: 16))
                                        .foregroundStyle(viewModel.selectedCategory.color)
                                        .frame(width: 24)

                                    Text(provider.name)
                                        .font(.system(size: MarketplaceTheme.Typography.callout))
                                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                                    Spacer()

                                    if viewModel.selectedProvider?.id == provider.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: "#8B5CF6"))
                                    }
                                }
                                .padding(MarketplaceTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(viewModel.selectedProvider?.id == provider.id ? Color(hex: "#8B5CF6").opacity(0.1) : MarketplaceTheme.Colors.backgroundSecondary)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // ZIP code
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Your ZIP Code")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        TextField("Enter ZIP code", text: $viewModel.enteredZipCode)
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .padding(MarketplaceTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
                            )
                            .keyboardType(.numberPad)
                    }

                    // Info box
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
                        HStack(spacing: MarketplaceTheme.Spacing.xs) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#8B5CF6"))

                            Text("How it works")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        }

                        Text("We'll detect outages in your area and help you claim credits with pre-filled scripts and provider contact info.")
                            .font(.system(size: MarketplaceTheme.Typography.caption))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    }
                    .padding(MarketplaceTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(Color(hex: "#8B5CF6").opacity(0.1))
                    )
                }
                .padding(MarketplaceTheme.Spacing.md)
            }
            .navigationTitle("Add Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await viewModel.addConnection()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.selectedProvider == nil || viewModel.enteredZipCode.count < 5)
                }
            }
        }
    }
}

// MARK: - Report Outage Sheet

struct ReportOutageSheet: View {
    @ObservedObject var viewModel: OutageBotViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MarketplaceTheme.Spacing.lg) {
                if let connection = viewModel.selectedConnection {
                    // Provider info
                    HStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: connection.category.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(connection.category.color)

                        VStack(alignment: .leading) {
                            Text(connection.providerName)
                                .font(.system(size: MarketplaceTheme.Typography.headline, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                            Text(connection.category.rawValue)
                                .font(.system(size: MarketplaceTheme.Typography.caption))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                    )

                    // Time pickers
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
                        Text("When did the outage occur?")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        DatePicker(
                            "Started",
                            selection: $viewModel.reportStartTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)

                        Toggle("Outage is still ongoing", isOn: $viewModel.isOutageOngoing)
                            .tint(Color(hex: "#8B5CF6"))

                        if !viewModel.isOutageOngoing {
                            DatePicker(
                                "Ended",
                                selection: $viewModel.reportEndTime,
                                in: viewModel.reportStartTime...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }

                Spacer()

                // Submit button
                Button {
                    Task {
                        await viewModel.submitOutageReport()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Check Eligibility")
                                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(Color(hex: "#8B5CF6"))
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(MarketplaceTheme.Spacing.md)
            .navigationTitle("Report Outage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Outage Confirmation Sheet

struct OutageConfirmationSheet: View {
    @ObservedObject var viewModel: OutageBotViewModel
    let detectedOutage: DetectedOutage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            // Alert header
            VStack(spacing: MarketplaceTheme.Spacing.sm) {
                Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "#EF4444"))

                Text("Outage Detected")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }

            // Details
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                detailRow(label: "Provider", value: detectedOutage.connection.providerName)
                detailRow(label: "Service", value: detectedOutage.connection.category.rawValue)
                detailRow(label: "Started", value: detectedOutage.event.formattedStartTime)
                detailRow(label: "Duration", value: detectedOutage.event.formattedDuration)

                // Crowd signal
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#8B5CF6"))

                    Text(detectedOutage.crowdMessage)
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
                .padding(MarketplaceTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(Color(hex: "#8B5CF6").opacity(0.1))
                )
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )

            Text("Did this outage affect you?")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            // Action buttons
            HStack(spacing: MarketplaceTheme.Spacing.md) {
                Button {
                    viewModel.dismissOutage(detectedOutage)
                    dismiss()
                } label: {
                    Text("No")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await viewModel.confirmOutage(detectedOutage)
                    }
                    dismiss()
                } label: {
                    Text("Yes, check eligibility")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MarketplaceTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                .fill(Color(hex: "#8B5CF6"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MarketplaceTheme.Spacing.lg)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Spacer()

            Text(value)
                .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
    }
}

// MARK: - Claim History Sheet

struct ClaimHistorySheet: View {
    @ObservedObject var viewModel: OutageBotViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: ClaimFilter = .all

    enum ClaimFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case denied = "Denied"
    }

    var filteredClaims: [OutageClaim] {
        switch selectedFilter {
        case .all:
            return viewModel.claims
        case .pending:
            return viewModel.claims.filter { $0.status == .submitted || $0.status.isActionable }
        case .approved:
            return viewModel.claims.filter { $0.status == .approved }
        case .denied:
            return viewModel.claims.filter { $0.status == .denied }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                HStack(spacing: MarketplaceTheme.Spacing.lg) {
                    summaryItem(
                        label: "Total Claims",
                        value: "\(viewModel.totalClaimsCount)"
                    )

                    summaryItem(
                        label: "Recovered",
                        value: viewModel.formattedTotalRecovered
                    )

                    summaryItem(
                        label: "Pending",
                        value: viewModel.formattedPendingAmount
                    )
                }
                .padding(MarketplaceTheme.Spacing.md)
                .background(MarketplaceTheme.Colors.backgroundSecondary)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        ForEach(ClaimFilter.allCases, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                    .foregroundStyle(selectedFilter == filter ? .white : MarketplaceTheme.Colors.textSecondary)
                                    .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                                    .padding(.vertical, MarketplaceTheme.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == filter ? Color(hex: "#8B5CF6") : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    .padding(.vertical, MarketplaceTheme.Spacing.sm)
                }

                // Claims list
                ScrollView {
                    LazyVStack(spacing: MarketplaceTheme.Spacing.sm) {
                        ForEach(filteredClaims) { claim in
                            OutageClaimRow(claim: claim) {
                                viewModel.selectClaim(claim)
                                dismiss()
                            }
                        }
                    }
                    .padding(MarketplaceTheme.Spacing.md)
                }
            }
            .navigationTitle("Claim History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Preview

struct OutageBotView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            OutageBotView()
                .padding()
        }
        .background(MarketplaceTheme.Colors.backgroundPrimary)
    }
}
