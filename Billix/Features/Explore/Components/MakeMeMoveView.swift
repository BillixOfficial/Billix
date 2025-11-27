//
//  MakeMeMoveView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI

/// Make Me Move - Strike Price Alerts for Bills
struct MakeMeMoveView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var showCreateSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.md) {
            // Header
            header

            // Active orders
            if viewModel.strikePriceOrders.isEmpty {
                emptyState
            } else {
                activeOrdersList
            }

            // Recent matches
            if !viewModel.strikePriceMatches.isEmpty {
                matchesSection
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
        .sheet(isPresented: $showCreateSheet) {
            CreateStrikePriceSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxxs) {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.system(size: 18))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)

                    Text("Make Me Move")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }

                Text("Set your strike price. We'll alert you when deals hit your target.")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            Spacer()

            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "bell.badge")
                .font(.system(size: 40))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

            Text("No strike prices set")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .medium))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

            Text("Create your first alert to get notified when deals match your target price.")
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showCreateSheet = true
            } label: {
                Text("Set Strike Price")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, MarketplaceTheme.Spacing.lg)
                    .padding(.vertical, MarketplaceTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                            .fill(MarketplaceTheme.Colors.primary)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, MarketplaceTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MarketplaceTheme.Spacing.xl)
    }

    // MARK: - Active Orders

    private var activeOrdersList: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            ForEach(viewModel.strikePriceOrders) { order in
                StrikePriceOrderCard(
                    order: order,
                    onToggle: { viewModel.toggleStrikePriceActive(order) },
                    onEdit: { viewModel.editingStrikePrice = order },
                    onDelete: { viewModel.deleteStrikePriceOrder(order) }
                )
            }
        }
    }

    // MARK: - Matches Section

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MarketplaceTheme.Colors.success)

                Text("Recent Matches")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("\(viewModel.strikePriceMatches.count) new")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
                    .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(MarketplaceTheme.Colors.success.opacity(0.15))
                    )
            }

            ForEach(viewModel.strikePriceMatches) { match in
                MatchCard(match: match)
            }
        }
    }
}

// MARK: - Strike Price Order Card

struct StrikePriceOrderCard: View {
    let order: StrikePriceOrder
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header row
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(order.category)
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    if let provider = order.providerName {
                        Text("Currently: \(provider)")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Active toggle
                Toggle("", isOn: Binding(
                    get: { order.isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(MarketplaceTheme.Colors.primary)
            }

            // Price comparison
            HStack(spacing: MarketplaceTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("$\(Int(order.currentPrice))")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Strike Price")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("$\(Int(order.strikePrice))")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }

                Spacer()

                // Savings target
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target Savings")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("-$\(Int(order.savingsTarget))/mo")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.success)
                }
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )

            // Constraints chips
            if !order.constraints.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        ForEach(order.constraints) { constraint in
                            constraintChip(constraint)
                        }
                    }
                }
            }

            // Match count and actions
            HStack {
                if order.matchCount > 0 {
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(MarketplaceTheme.Colors.success)

                        Text("\(order.matchCount) match\(order.matchCount == 1 ? "" : "es") found")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.success)
                    }
                } else {
                    Text("Watching...")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }

                Spacer()

                // Edit button
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }

                // Delete button
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(MarketplaceTheme.Colors.danger)
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .stroke(
                    order.isActive ? MarketplaceTheme.Colors.primary.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .opacity(order.isActive ? 1.0 : 0.6)
        .confirmationDialog("Delete Strike Price?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func constraintChip(_ constraint: StrikePriceConstraint) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Image(systemName: constraintIcon(for: constraint.type))
                .font(.system(size: 10))

            Text(constraintLabel(for: constraint))
                .font(.system(size: MarketplaceTheme.Typography.micro))
        }
        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        .padding(.horizontal, MarketplaceTheme.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    private func constraintIcon(for type: StrikePriceConstraint.ConstraintType) -> String {
        switch type {
        case .minSpeed: return "speedometer"
        case .maxContract: return "calendar"
        case .provider: return "building.2"
        case .noDataCap: return "infinity"
        }
    }

    private func constraintLabel(for constraint: StrikePriceConstraint) -> String {
        switch constraint.type {
        case .minSpeed: return "Min \(constraint.value)"
        case .maxContract: return "Max \(constraint.value) contract"
        case .provider: return constraint.value
        case .noDataCap: return "No data cap"
        }
    }

    private var categoryColor: Color {
        switch order.category.lowercased() {
        case "internet": return Color(hex: "#3B82F6")
        case "energy": return Color(hex: "#F59E0B")
        case "mobile": return Color(hex: "#10B981")
        case "rent": return Color(hex: "#8B5CF6")
        default: return MarketplaceTheme.Colors.primary
        }
    }

    private var categoryIcon: String {
        switch order.category.lowercased() {
        case "internet": return "wifi"
        case "energy": return "bolt.fill"
        case "mobile": return "iphone"
        case "rent": return "house.fill"
        default: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: StrikePriceMatch

    var body: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Match indicator
            ZStack {
                Circle()
                    .fill(MarketplaceTheme.Colors.success.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
            }

            // Deal info
            VStack(alignment: .leading, spacing: 2) {
                Text(match.dealTitle)
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Text(match.providerName)
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text(timeAgo(match.matchedDate))
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Price and match score
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", match.price))")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)

                Text("\(match.matchScore)% match")
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.success.opacity(0.05))
                .stroke(MarketplaceTheme.Colors.success.opacity(0.2), lineWidth: 1)
        )
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)

        if hours < 1 { return "Just now" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Create Strike Price Sheet

struct CreateStrikePriceSheet: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: String = "Internet"
    @State private var currentPrice: Double = 80
    @State private var strikePrice: Double = 50
    @State private var minSpeed: String = ""
    @State private var noDataCap: Bool = false
    @State private var anyProvider: Bool = true

    private let categories = ["Internet", "Energy", "Mobile", "Insurance", "Streaming"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.lg) {
                    // Category picker
                    categorySection

                    // Current price
                    currentPriceSection

                    // Strike price slider
                    strikePriceSection

                    // Constraints
                    constraintsSection

                    // Summary
                    summarySection
                }
                .padding(MarketplaceTheme.Spacing.md)
            }
            .navigationTitle("Set Strike Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createOrder()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(strikePrice >= currentPrice)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("Category")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category)
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                .foregroundStyle(selectedCategory == category ? .white : MarketplaceTheme.Colors.textSecondary)
                                .padding(.horizontal, MarketplaceTheme.Spacing.sm)
                                .padding(.vertical, MarketplaceTheme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? MarketplaceTheme.Colors.primary : MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var currentPriceSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("What do you currently pay?")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            HStack {
                Text("$")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                TextField("0", value: $currentPrice, format: .number)
                    .font(.system(size: MarketplaceTheme.Typography.hero, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .keyboardType(.decimalPad)

                Text("/mo")
                    .font(.system(size: MarketplaceTheme.Typography.body))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
    }

    private var strikePriceSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("I'd move if I could get this for:")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("$\(Int(strikePrice))/mo")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
            }

            Slider(value: $strikePrice, in: 10...currentPrice, step: 5)
                .tint(MarketplaceTheme.Colors.success)

            HStack {
                Text("$10")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Spacer()

                Text("$\(Int(currentPrice))")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }
        }
    }

    private var constraintsSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("Requirements (Optional)")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            if selectedCategory == "Internet" {
                HStack {
                    Text("Minimum speed")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                    Spacer()

                    TextField("e.g. 500 Mbps", text: $minSpeed)
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )

                Toggle(isOn: $noDataCap) {
                    Text("No data cap required")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
                .tint(MarketplaceTheme.Colors.primary)
                .padding(MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                )
            }

            Toggle(isOn: $anyProvider) {
                Text("Any provider is fine")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }
            .tint(MarketplaceTheme.Colors.primary)
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
    }

    private var summarySection: some View {
        VStack(spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("Potential monthly savings")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Spacer()

                Text("-$\(Int(currentPrice - strikePrice))")
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
            }

            HStack {
                Text("Potential yearly savings")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                Spacer()

                Text("-$\(Int((currentPrice - strikePrice) * 12))")
                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.success.opacity(0.1))
        )
    }

    private func createOrder() {
        var constraints: [StrikePriceConstraint] = []

        if !minSpeed.isEmpty {
            constraints.append(StrikePriceConstraint(type: .minSpeed, value: minSpeed))
        }
        if noDataCap {
            constraints.append(StrikePriceConstraint(type: .noDataCap, value: "true"))
        }

        let order = StrikePriceOrder(
            category: selectedCategory,
            currentPrice: currentPrice,
            strikePrice: strikePrice,
            constraints: constraints
        )

        viewModel.createStrikePriceOrder(order)
    }
}

#Preview {
    ScrollView {
        MakeMeMoveView(viewModel: ExploreViewModel())
            .padding()
    }
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}
