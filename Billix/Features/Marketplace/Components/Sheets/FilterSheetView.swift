//
//  FilterSheetView.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Filter sheet for Marketplace listings
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MarketplaceViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.lg) {
                    // Categories
                    categorySection

                    Divider()

                    // Price range
                    priceSection

                    Divider()

                    // Match score
                    matchScoreSection

                    Divider()

                    // Verified only
                    verifiedSection

                    Divider()

                    // ZIP code
                    zipCodeSection
                }
                .padding(MarketplaceTheme.Spacing.md)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.danger)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("Categories")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(MarketplaceBillType.allCases, id: \.self) { category in
                    categoryChip(category)
                }
            }
        }
    }

    private func categoryChip(_ category: MarketplaceBillType) -> some View {
        let isSelected = viewModel.selectedCategories.contains(category)

        return Button {
            if isSelected {
                viewModel.selectedCategories.remove(category)
            } else {
                viewModel.selectedCategories.insert(category)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.rawValue)
                    .font(.system(size: MarketplaceTheme.Typography.caption))
            }
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(isSelected ? MarketplaceTheme.Colors.primary : MarketplaceTheme.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("Price Range")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("$\(Int(viewModel.priceRange.lowerBound)) - $\(Int(viewModel.priceRange.upperBound))")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            VStack(spacing: MarketplaceTheme.Spacing.xs) {
                HStack {
                    Text("Min")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Slider(value: Binding(
                        get: { viewModel.priceRange.lowerBound },
                        set: { viewModel.priceRange = $0...viewModel.priceRange.upperBound }
                    ), in: 0...200, step: 5)
                    .tint(MarketplaceTheme.Colors.primary)
                }

                HStack {
                    Text("Max")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Slider(value: Binding(
                        get: { viewModel.priceRange.upperBound },
                        set: { viewModel.priceRange = viewModel.priceRange.lowerBound...$0 }
                    ), in: 0...200, step: 5)
                    .tint(MarketplaceTheme.Colors.primary)
                }
            }
        }
    }

    private var matchScoreSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            HStack {
                Text("Minimum Match Score")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                Spacer()

                Text("\(Int(viewModel.minMatchScore))%")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.matchScoreColor(for: Int(viewModel.minMatchScore)))
            }

            Slider(value: $viewModel.minMatchScore, in: 0...100, step: 5)
                .tint(MarketplaceTheme.Colors.matchScoreColor(for: Int(viewModel.minMatchScore)))
        }
    }

    private var verifiedSection: some View {
        Toggle(isOn: $viewModel.showVerifiedOnly) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(MarketplaceTheme.Colors.info)
                Text("Verified Deals Only")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }
        }
        .tint(MarketplaceTheme.Colors.primary)
    }

    private var zipCodeSection: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            Text("ZIP Code")
                .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            TextField("Enter ZIP code", text: $viewModel.filterZipCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct FilterSheetView_Previews: PreviewProvider {
    static var previews: some View {
        FilterSheetView(viewModel: MarketplaceViewModel())
    }
}
