//
//  PostBountySheet.swift
//  Billix
//
//  Sheet for posting bill negotiation bounties
//

import SwiftUI

struct PostBountySheet: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bountyTitle = ""
    @State private var selectedCategory = "Internet"
    @State private var providerName = ""
    @State private var currentBill = ""
    @State private var targetSavings = ""
    @State private var bountyAmount = ""
    @State private var additionalDetails = ""
    @State private var expiresInDays = 7

    private let categories = ["Internet", "Mobile", "Energy", "Insurance", "Medical Bills", "Subscriptions"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundStyle(MarketplaceTheme.Colors.accent)

                        Text("Post a Bounty")
                            .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Offer a reward for someone to negotiate your bill")
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MarketplaceTheme.Spacing.lg)

                    // Form
                    VStack(spacing: MarketplaceTheme.Spacing.md) {
                        // Bounty Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bounty Title")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("e.g., Need help lowering my Xfinity bill", text: $bountyTitle)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                                    ForEach(categories, id: \.self) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            Text(category)
                                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                                .foregroundStyle(selectedCategory == category ? .white : MarketplaceTheme.Colors.textPrimary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedCategory == category ? MarketplaceTheme.Colors.primary : MarketplaceTheme.Colors.backgroundSecondary)
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        // Provider Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Provider")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("e.g., Xfinity, Verizon", text: $providerName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }

                        // Bill Details
                        HStack(spacing: MarketplaceTheme.Spacing.md) {
                            // Current Bill
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Bill")
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                HStack {
                                    Text("$")
                                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                                    TextField("0", text: $currentBill)
                                        .keyboardType(.decimalPad)
                                    Text("/mo")
                                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                                        .font(.system(size: MarketplaceTheme.Typography.caption))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                            }

                            // Target Savings
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target Savings")
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                HStack {
                                    Text("$")
                                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                                    TextField("0", text: $targetSavings)
                                        .keyboardType(.decimalPad)
                                    Text("/mo")
                                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                                        .font(.system(size: MarketplaceTheme.Typography.caption))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                            }
                        }

                        // Bounty Amount
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bounty Reward")
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                Spacer()

                                Text("Paid on success")
                                    .font(.system(size: MarketplaceTheme.Typography.micro))
                                    .foregroundStyle(MarketplaceTheme.Colors.success)
                            }

                            HStack {
                                Text("$")
                                    .font(.system(size: MarketplaceTheme.Typography.title3, weight: .bold))
                                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                                TextField("25", text: $bountyAmount)
                                    .font(.system(size: MarketplaceTheme.Typography.title3, weight: .bold))
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                    .fill(MarketplaceTheme.Colors.accent.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                            .stroke(MarketplaceTheme.Colors.accent.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Expires In
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Expires In")
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                Spacer()

                                Text("\(expiresInDays) days")
                                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                                    .foregroundStyle(MarketplaceTheme.Colors.primary)
                            }

                            Slider(value: Binding(
                                get: { Double(expiresInDays) },
                                set: { expiresInDays = Int($0) }
                            ), in: 1...30, step: 1)
                            .tint(MarketplaceTheme.Colors.primary)
                        }

                        // Additional Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Details (Optional)")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("Contract details, preferences, etc.", text: $additionalDetails, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...5)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    Spacer(minLength: MarketplaceTheme.Spacing.xl)

                    // Post Button
                    Button {
                        // TODO: Post bounty
                        dismiss()
                    } label: {
                        Text("Post Bounty")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(MarketplaceTheme.Colors.accent)
                            )
                    }
                    .disabled(bountyTitle.isEmpty || providerName.isEmpty || bountyAmount.isEmpty)
                    .opacity(bountyTitle.isEmpty || providerName.isEmpty || bountyAmount.isEmpty ? 0.5 : 1)
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                }
            }
            .background(MarketplaceTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }
        }
    }
}
