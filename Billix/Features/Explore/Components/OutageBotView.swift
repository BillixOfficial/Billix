//
//  OutageBotView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

/// Outage Bot - Automatic Credit Claiming for Service Outages
struct OutageBotView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var showSetupSheet: Bool = false
    @State private var showClaimHistory: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Header with total claimed
            header

            // Connected providers
            if viewModel.outageConnections.isEmpty {
                emptyState
            } else {
                connectedProvidersList
            }

            // Recent claims
            if !viewModel.recentClaims.isEmpty {
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
        .sheet(isPresented: $showSetupSheet) {
            AddProviderSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showClaimHistory) {
            ClaimHistorySheet(claims: viewModel.recentClaims)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header

    private var header: some View {
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

                Text("Auto-claim credits when your services go down.")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            Spacer()

            // Total claimed badge
            if viewModel.totalClaimedAmount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Claimed")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("$\(String(format: "%.2f", viewModel.totalClaimedAmount))")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.success.opacity(0.1))
                )
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

            Text("Connect your utility providers to automatically detect outages and claim credits.")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showSetupSheet = true
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
                    showSetupSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }

            ForEach(viewModel.outageConnections) { connection in
                ProviderConnectionCard(
                    connection: connection,
                    onToggle: { viewModel.toggleOutageMonitoring(for: connection) }
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
                    showClaimHistory = true
                } label: {
                    Text("See All")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }

            ForEach(viewModel.recentClaims.prefix(2)) { claim in
                ClaimRow(claim: claim)
            }
        }
    }
}

// MARK: - Provider Connection Card

struct ProviderConnectionCard: View {
    let connection: OutageConnection
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Header row
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Provider icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: connection.providerLogo)
                        .font(.system(size: 18))
                        .foregroundStyle(categoryColor)
                }

                // Provider info
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text(connection.category)
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
                    label: "Total Claimed",
                    value: "$\(String(format: "%.2f", connection.totalClaimed))",
                    icon: "dollarsign.circle"
                )

                if let lastOutage = connection.lastOutageDate {
                    statItem(
                        label: "Last Outage",
                        value: timeAgo(lastOutage),
                        icon: "clock"
                    )
                }

                Spacer()
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
                        .fill(MarketplaceTheme.Colors.success)
                        .frame(width: 6, height: 6)

                    Text("Monitoring active")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.success)

                    Text("• Will auto-claim on outage")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
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

    private var categoryColor: Color {
        switch connection.category.lowercased() {
        case "internet": return Color(hex: "#3B82F6")
        case "energy": return Color(hex: "#F59E0B")
        case "mobile": return Color(hex: "#10B981")
        default: return Color(hex: "#8B5CF6")
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let days = Int(Date().timeIntervalSince(date) / 86400)
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }
}

// MARK: - Claim Row

struct ClaimRow: View {
    let claim: OutageClaim

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(claim.status.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: statusIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(claim.status.color)
            }

            // Claim info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(claim.providerName) Outage")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Text(formatDate(claim.outageDate))
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("\(String(format: "%.1f", claim.durationHours))h")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Amount and status
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", claim.claimAmount))")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(claim.status == .approved ? MarketplaceTheme.Colors.success : MarketplaceTheme.Colors.textPrimary)

                Text(claim.status.rawValue)
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

    private var statusIcon: String {
        switch claim.status {
        case .pending: return "clock"
        case .submitted: return "paperplane"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Add Provider Sheet

struct AddProviderSheet: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProvider: String = ""
    @State private var selectedCategory: String = "Internet"
    @State private var zipCode: String = ""

    private let providers = [
        ("Internet", ["Comcast", "Verizon Fios", "Optimum", "Spectrum", "AT&T"]),
        ("Energy", ["PSEG", "ConEd", "National Grid", "Duke Energy"]),
        ("Mobile", ["Verizon", "AT&T", "T-Mobile", "Sprint"])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.lg) {
                    // Category selection
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Category")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                                ForEach(["Internet", "Energy", "Mobile"], id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                        selectedProvider = ""
                                    } label: {
                                        Text(category)
                                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                            .foregroundStyle(selectedCategory == category ? .white : MarketplaceTheme.Colors.textSecondary)
                                            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                                            .padding(.vertical, MarketplaceTheme.Spacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(selectedCategory == category ? Color(hex: "#8B5CF6") : MarketplaceTheme.Colors.backgroundSecondary)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Provider selection
                    VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                        Text("Provider")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        let categoryProviders = providers.first { $0.0 == selectedCategory }?.1 ?? []

                        ForEach(categoryProviders, id: \.self) { provider in
                            Button {
                                selectedProvider = provider
                            } label: {
                                HStack {
                                    Text(provider)
                                        .font(.system(size: MarketplaceTheme.Typography.callout))
                                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                                    Spacer()

                                    if selectedProvider == provider {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: "#8B5CF6"))
                                    }
                                }
                                .padding(MarketplaceTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(selectedProvider == provider ? Color(hex: "#8B5CF6").opacity(0.1) : MarketplaceTheme.Colors.backgroundSecondary)
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

                        TextField("Enter ZIP code", text: $zipCode)
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

                        Text("We monitor public outage reports for your provider and ZIP code. When an outage is detected, we automatically submit a credit claim on your behalf.")
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
                        addProvider()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedProvider.isEmpty || zipCode.count < 5)
                }
            }
        }
    }

    private func addProvider() {
        let iconMap: [String: String] = [
            "Internet": "wifi",
            "Energy": "bolt.fill",
            "Mobile": "antenna.radiowaves.left.and.right"
        ]

        let connection = OutageConnection(
            providerName: selectedProvider,
            providerLogo: iconMap[selectedCategory] ?? "questionmark.circle",
            category: selectedCategory,
            zipCode: zipCode
        )

        viewModel.addOutageConnection(connection)
    }
}

// MARK: - Claim History Sheet

struct ClaimHistorySheet: View {
    let claims: [OutageClaim]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.sm) {
                    // Summary
                    HStack(spacing: MarketplaceTheme.Spacing.lg) {
                        summaryItem(
                            label: "Total Claims",
                            value: "\(claims.count)"
                        )

                        summaryItem(
                            label: "Total Credited",
                            value: "$\(String(format: "%.2f", totalCredited))"
                        )

                        summaryItem(
                            label: "Pending",
                            value: "$\(String(format: "%.2f", totalPending))"
                        )
                    }
                    .padding(MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                    )
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    // Claims list
                    ForEach(claims) { claim in
                        ClaimRow(claim: claim)
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    }
                }
                .padding(.vertical, MarketplaceTheme.Spacing.md)
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

    private var totalCredited: Double {
        claims.filter { $0.status == .approved }.reduce(0) { $0 + $1.claimAmount }
    }

    private var totalPending: Double {
        claims.filter { $0.status == .pending || $0.status == .submitted }.reduce(0) { $0 + $1.claimAmount }
    }
}

#Preview {
    ScrollView {
        OutageBotView(viewModel: ExploreViewModel())
            .padding()
    }
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}
