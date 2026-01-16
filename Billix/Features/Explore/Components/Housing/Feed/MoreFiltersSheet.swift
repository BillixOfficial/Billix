//
//  MoreFiltersSheet.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Industry-standard real estate filters following Zillow/Redfin patterns
//

import SwiftUI

struct MoreFiltersSheet: View {
    @ObservedObject var viewModel: HousingSearchViewModel
    @Environment(\.dismiss) var dismiss

    // Local state for range sliders
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 10000
    @State private var minSqft: Double = 0
    @State private var maxSqft: Double = 5000
    @State private var minLotSize: Double = 0
    @State private var maxLotSize: Double = 50000
    @State private var minYearBuilt: Int = 1900
    @State private var maxYearBuilt: Int = 2024
    @State private var maxDaysOld: Int = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Mode Selector (Rent/Buy)
                    VStack(alignment: .leading, spacing: 12) {
                        // Mode toggle buttons
                        HStack(spacing: 0) {
                            ForEach(SearchMode.allCases) { mode in
                                Button {
                                    if mode.isAvailable {
                                        viewModel.activeSearchMode = mode
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 15, weight: .medium))

                                        Text(mode.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(
                                        mode.isAvailable
                                            ? (viewModel.activeSearchMode == mode ? .white : .billixDarkTeal)
                                            : .gray.opacity(0.4)
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                viewModel.activeSearchMode == mode && mode.isAvailable
                                                    ? Color.billixDarkTeal
                                                    : Color.clear
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .overlay(
                                        // "Coming Soon" badge overlay for disabled modes
                                        Group {
                                            if !mode.isAvailable {
                                                Text("Soon")
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.orange)
                                                    )
                                                    .offset(x: 8, y: -8)
                                            }
                                        },
                                        alignment: .topTrailing
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!mode.isAvailable)
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.12))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Divider()

                    // Price Range Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(viewModel.activeSearchMode == .rent ? "Monthly Rent Range" : "Purchase Price Range")

                        VStack(spacing: 12) {
                            HStack {
                                Text(viewModel.activeSearchMode == .rent ? "$\(Int(minPrice))/mo" : "$\(Int(minPrice))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()

                                Spacer()

                                Text(viewModel.activeSearchMode == .rent ? "$\(Int(maxPrice))/mo" : "$\(Int(maxPrice))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()
                            }

                            // Dual slider for min/max
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text("Min")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $minPrice, in: 0...10000, step: 100)
                                        .tint(.billixDarkTeal)
                                }

                                HStack(spacing: 12) {
                                    Text("Max")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $maxPrice, in: 0...10000, step: 100)
                                        .tint(.billixDarkTeal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Bedrooms & Bathrooms Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Bedrooms & Bathrooms")

                        VStack(spacing: 20) {
                            // Bedrooms
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bedrooms")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        BedroomBathroomButton(
                                            label: "Any",
                                            isSelected: viewModel.activeBedrooms == nil,
                                            onTap: { viewModel.activeBedrooms = nil }
                                        )

                                        ForEach([1, 2, 3, 4, 5], id: \.self) { count in
                                            BedroomBathroomButton(
                                                label: "\(count)+",
                                                isSelected: viewModel.activeBedrooms == count,
                                                onTap: { viewModel.activeBedrooms = count }
                                            )
                                        }
                                    }
                                }
                            }

                            // Bathrooms
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bathrooms")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        BedroomBathroomButton(
                                            label: "Any",
                                            isSelected: viewModel.activeBathrooms == nil,
                                            onTap: { viewModel.activeBathrooms = nil }
                                        )

                                        ForEach([1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0], id: \.self) { count in
                                            BedroomBathroomButton(
                                                label: count.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(count))+" : "\(String(format: "%.1f", count))+",
                                                isSelected: viewModel.activeBathrooms == count,
                                                onTap: { viewModel.activeBathrooms = count }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Square Footage Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Square Footage")

                        VStack(spacing: 12) {
                            HStack {
                                Text("\(Int(minSqft)) sq ft")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()

                                Spacer()

                                Text("\(Int(maxSqft)) sq ft")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()
                            }

                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text("Min")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $minSqft, in: 0...5000, step: 100)
                                        .tint(.billixDarkTeal)
                                }

                                HStack(spacing: 12) {
                                    Text("Max")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $maxSqft, in: 0...5000, step: 100)
                                        .tint(.billixDarkTeal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Year Built Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Year Built")

                        HStack(spacing: 16) {
                            // Min Year
                            VStack(alignment: .leading, spacing: 8) {
                                Text("From")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                Picker("Min Year", selection: $minYearBuilt) {
                                    ForEach(Array(stride(from: 1900, through: 2024, by: 10)), id: \.self) { year in
                                        Text("\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Max Year
                            VStack(alignment: .leading, spacing: 8) {
                                Text("To")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                Picker("Max Year", selection: $maxYearBuilt) {
                                    ForEach(Array(stride(from: 1900, through: 2024, by: 10)), id: \.self) { year in
                                        Text("\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Lot Size Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Lot Size")

                        VStack(spacing: 12) {
                            HStack {
                                Text("\(Int(minLotSize)) sq ft")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()

                                Spacer()

                                Text("\(Int(maxLotSize)) sq ft")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.billixDarkTeal)
                                    .monospacedDigit()
                            }

                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text("Min")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $minLotSize, in: 0...50000, step: 1000)
                                        .tint(.billixDarkTeal)
                                }

                                HStack(spacing: 12) {
                                    Text("Max")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)

                                    Slider(value: $maxLotSize, in: 0...50000, step: 1000)
                                        .tint(.billixDarkTeal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Days on Market Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Days on Market")

                        HStack {
                            Text("Show listings from")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)

                            Spacer()

                            Picker("Days", selection: $maxDaysOld) {
                                Text("Any time").tag(0)
                                Text("Last 7 days").tag(7)
                                Text("Last 14 days").tag(14)
                                Text("Last 30 days").tag(30)
                                Text("Last 60 days").tag(60)
                                Text("Last 90 days").tag(90)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // Property Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("Property Details")

                        VStack(spacing: 12) {
                            // Property Type - Multi-select
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Property Type")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach([PropertyType.singleFamily, .apartment, .condo, .townhouse, .manufactured, .multiFamily], id: \.self) { type in
                                        PropertyTypeChip(
                                            type: type,
                                            isSelected: viewModel.activePropertyTypes.contains(type),
                                            onTap: {
                                                if viewModel.activePropertyTypes.contains(type) {
                                                    viewModel.activePropertyTypes.remove(type)
                                                } else {
                                                    viewModel.activePropertyTypes.insert(type)
                                                }
                                            }
                                        )
                                    }
                                }
                            }

                            Divider()

                            // Listing Status
                            HStack {
                                Text("Listing Status")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)

                                Spacer()

                                Picker("Status", selection: $viewModel.activeListingStatus) {
                                    ForEach([ListingStatus.all, .active, .inactive], id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            applyFiltersAndDismiss()
                        } label: {
                            Text("Apply Filters")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.billixDarkTeal)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            resetAllFilters()
                        } label: {
                            Text("Reset All Filters")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixDarkTeal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.billixDarkTeal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("More Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.5)
    }

    // MARK: - Helper Methods

    private func loadCurrentValues() {
        // Load current filter values into local state
        if let priceRange = viewModel.activePriceRange {
            minPrice = priceRange.lowerBound
            maxPrice = priceRange.upperBound
        }

        if let sqftRange = viewModel.activeSqftRange {
            minSqft = sqftRange.lowerBound
            maxSqft = sqftRange.upperBound
        }

        if let lotRange = viewModel.activeLotSizeRange {
            minLotSize = lotRange.lowerBound
            maxLotSize = lotRange.upperBound
        }

        if let yearRange = viewModel.activeYearBuiltRange {
            minYearBuilt = yearRange.lowerBound
            maxYearBuilt = yearRange.upperBound
        }

        if let daysRange = viewModel.activeDaysOldRange {
            maxDaysOld = daysRange.upperBound
        }
    }

    private func applyFiltersAndDismiss() {
        // Save local state to ViewModel
        if minPrice > 0 || maxPrice < 10000 {
            viewModel.activePriceRange = minPrice...maxPrice
        } else {
            viewModel.activePriceRange = nil
        }

        if minSqft > 0 || maxSqft < 5000 {
            viewModel.activeSqftRange = minSqft...maxSqft
        } else {
            viewModel.activeSqftRange = nil
        }

        if minLotSize > 0 || maxLotSize < 50000 {
            viewModel.activeLotSizeRange = minLotSize...maxLotSize
        } else {
            viewModel.activeLotSizeRange = nil
        }

        if minYearBuilt > 1900 || maxYearBuilt < 2024 {
            viewModel.activeYearBuiltRange = minYearBuilt...maxYearBuilt
        } else {
            viewModel.activeYearBuiltRange = nil
        }

        if maxDaysOld > 0 {
            viewModel.activeDaysOldRange = 0...maxDaysOld
        } else {
            viewModel.activeDaysOldRange = nil
        }

        Task {
            await viewModel.applyFilters()
            dismiss()
        }
    }

    private func resetAllFilters() {
        viewModel.resetFilters()

        // Reset local state
        minPrice = 0
        maxPrice = 10000
        minSqft = 0
        maxSqft = 5000
        minLotSize = 0
        maxLotSize = 50000
        minYearBuilt = 1900
        maxYearBuilt = 2024
        maxDaysOld = 0
    }
}

// MARK: - Filter Amenity Chip Component

struct FilterAmenityChip: View {
    let amenity: PropertyAmenity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: amenity.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(amenity.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .billixDarkTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.billixDarkTeal : Color.billixDarkTeal.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bedroom/Bathroom Button Component

struct BedroomBathroomButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .billixDarkTeal)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.billixDarkTeal : Color.billixDarkTeal.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Property Type Chip Component

struct PropertyTypeChip: View {
    let type: PropertyType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(type.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .billixDarkTeal)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.billixDarkTeal : Color.billixDarkTeal.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("More Filters Sheet") {
    MoreFiltersSheet(viewModel: HousingSearchViewModel())
}
