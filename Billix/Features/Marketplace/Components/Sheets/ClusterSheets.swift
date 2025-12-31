//
//  ClusterSheets.swift
//  Billix
//
//  Sheet components for Cluster operations
//

import SwiftUI

// MARK: - Create Cluster Sheet

struct CreateClusterSheet: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var clusterName = ""
    @State private var selectedCategory = "Internet"
    @State private var goalDescription = ""
    @State private var maxMembers = 50

    private let categories = ["Internet", "Mobile", "Energy", "Insurance", "Streaming"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)

                        Text("Start a Cluster")
                            .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Rally others to negotiate better rates together")
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MarketplaceTheme.Spacing.lg)

                    // Form
                    VStack(spacing: MarketplaceTheme.Spacing.md) {
                        // Cluster Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cluster Name")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("e.g., NYC Internet Savers", text: $clusterName)
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

                        // Goal Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("What are you trying to achieve?", text: $goalDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...5)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }

                        // Max Members
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Max Members")
                                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                Spacer()

                                Text("\(maxMembers)")
                                    .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                                    .foregroundStyle(MarketplaceTheme.Colors.primary)
                            }

                            Slider(value: Binding(
                                get: { Double(maxMembers) },
                                set: { maxMembers = Int($0) }
                            ), in: 10...500, step: 10)
                            .tint(MarketplaceTheme.Colors.primary)
                        }
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    Spacer(minLength: MarketplaceTheme.Spacing.xl)

                    // Create Button
                    Button {
                        // TODO: Create cluster
                        dismiss()
                    } label: {
                        Text("Create Cluster")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(MarketplaceTheme.Colors.primary)
                            )
                    }
                    .disabled(clusterName.isEmpty || goalDescription.isEmpty)
                    .opacity(clusterName.isEmpty || goalDescription.isEmpty ? 0.5 : 1)
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

// MARK: - Join Cluster Sheet

struct JoinClusterSheet: View {
    let cluster: MarketplaceCluster
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isJoining = false

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            // Cluster Info
            VStack(spacing: MarketplaceTheme.Spacing.sm) {
                Image(systemName: cluster.categoryIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
                    .padding()
                    .background(
                        Circle()
                            .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                    )

                Text(cluster.title)
                    .font(.system(size: MarketplaceTheme.Typography.title3, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Text(cluster.goalDescription)
                    .font(.system(size: MarketplaceTheme.Typography.body))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, MarketplaceTheme.Spacing.lg)

            // Stats
            HStack(spacing: MarketplaceTheme.Spacing.xl) {
                VStack {
                    Text("\(cluster.memberCount)")
                        .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                    Text("Members")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                VStack {
                    Text("\(cluster.maxMembers)")
                        .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    Text("Goal")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                VStack {
                    Text(cluster.timeRemainingDisplay)
                        .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                        .foregroundStyle(cluster.isUrgent ? MarketplaceTheme.Colors.warning : MarketplaceTheme.Colors.textPrimary)
                    Text("Remaining")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }
            .padding(.vertical, MarketplaceTheme.Spacing.md)

            Spacer()

            // Join Button
            Button {
                isJoining = true
                // TODO: Join cluster logic
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } label: {
                HStack {
                    if isJoining {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join Cluster")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MarketplaceTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                        .fill(MarketplaceTheme.Colors.success)
                )
            }
            .disabled(isJoining)
            .padding(.horizontal, MarketplaceTheme.Spacing.md)
            .padding(.bottom, MarketplaceTheme.Spacing.md)
        }
        .background(MarketplaceTheme.Colors.background)
    }
}

// MARK: - Share Deal Sheet

struct ShareDealSheet: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var providerName = ""
    @State private var selectedCategory = "Internet"
    @State private var monthlyPrice = ""
    @State private var dealDetails = ""

    private let categories = ["Internet", "Mobile", "Energy", "Insurance", "Streaming"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(MarketplaceTheme.Colors.accent)

                        Text("Share Your Deal")
                            .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Help others find great rates by sharing what you're paying")
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MarketplaceTheme.Spacing.lg)

                    // Form
                    VStack(spacing: MarketplaceTheme.Spacing.md) {
                        // Provider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Provider")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("e.g., Verizon, Xfinity", text: $providerName)
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

                        // Monthly Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Price")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            HStack {
                                Text("$")
                                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                                TextField("0.00", text: $monthlyPrice)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
                            )
                        }

                        // Deal Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deal Details (Optional)")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("Speed, data cap, contract terms...", text: $dealDetails, axis: .vertical)
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

                    // Share Button
                    Button {
                        // TODO: Share deal
                        dismiss()
                    } label: {
                        Text("Share Deal")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(MarketplaceTheme.Colors.accent)
                            )
                    }
                    .disabled(providerName.isEmpty || monthlyPrice.isEmpty)
                    .opacity(providerName.isEmpty || monthlyPrice.isEmpty ? 0.5 : 1)
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
