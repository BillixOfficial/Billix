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
                            // Bedrooms (exact values)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bedrooms")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        BedroomBathroomButton(
                                            label: "Any",
                                            isSelected: viewModel.activeBedrooms == nil,
                                            onTap: {
                                                viewModel.activeBedrooms = nil
                                                print("🔍 [FILTER UI] Bedrooms: Any")
                                            }
                                        )

                                        // Studio = 0 bedrooms
                                        BedroomBathroomButton(
                                            label: "Studio",
                                            isSelected: viewModel.activeBedrooms == 0,
                                            onTap: {
                                                viewModel.activeBedrooms = 0
                                                print("🔍 [FILTER UI] Bedrooms: Studio (0)")
                                            }
                                        )

                                        // Exact bedroom counts: 1, 2, 3, 4, 5+
                                        ForEach([1, 2, 3, 4], id: \.self) { count in
                                            BedroomBathroomButton(
                                                label: "\(count)",
                                                isSelected: viewModel.activeBedrooms == count,
                                                onTap: {
                                                    viewModel.activeBedrooms = count
                                                    print("🔍 [FILTER UI] Bedrooms: \(count)")
                                                }
                                            )
                                        }

                                        // 5+ (treated as 5)
                                        BedroomBathroomButton(
                                            label: "5+",
                                            isSelected: viewModel.activeBedrooms == 5,
                                            onTap: {
                                                viewModel.activeBedrooms = 5
                                                print("🔍 [FILTER UI] Bedrooms: 5+")
                                            }
                                        )
                                    }
                                }
                            }

                            // Bathrooms (simplified exact values)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Bathrooms")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        BedroomBathroomButton(
                                            label: "Any",
                                            isSelected: viewModel.activeBathrooms == nil,
                                            onTap: {
                                                viewModel.activeBathrooms = nil
                                                print("🔍 [FILTER UI] Bathrooms: Any")
                                            }
                                        )

                                        // Exact bathroom counts: 1, 2, 3+
                                        ForEach([1.0, 2.0], id: \.self) { count in
                                            BedroomBathroomButton(
                                                label: "\(Int(count))",
                                                isSelected: viewModel.activeBathrooms == count,
                                                onTap: {
                                                    viewModel.activeBathrooms = count
                                                    print("🔍 [FILTER UI] Bathrooms: \(Int(count))")
                                                }
                                            )
                                        }

                                        // 3+ (treated as 3)
                                        BedroomBathroomButton(
                                            label: "3+",
                                            isSelected: viewModel.activeBathrooms == 3.0,
                                            onTap: {
                                                viewModel.activeBathrooms = 3.0
                                                print("🔍 [FILTER UI] Bathrooms: 3+")
                                            }
                                        )
                                    }
                                }
                            }
                        }
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
    }

    private func applyFiltersAndDismiss() {
        // Save local state to ViewModel
        if minPrice > 0 || maxPrice < 10000 {
            viewModel.activePriceRange = minPrice...maxPrice
        } else {
            viewModel.activePriceRange = nil
        }

        print("🔍 [FILTERS] Applying filters:")
        print("   💵 Price: \(viewModel.activePriceRange != nil ? "$\(Int(minPrice))-$\(Int(maxPrice))" : "Any")")
        print("   🛏️ Beds: \(viewModel.activeBedrooms != nil ? "\(viewModel.activeBedrooms!)" : "Any")")
        print("   🛁 Baths: \(viewModel.activeBathrooms != nil ? "\(viewModel.activeBathrooms!)" : "Any")")
        print("   🏠 Types: \(viewModel.activePropertyTypes.isEmpty ? "Any" : viewModel.activePropertyTypes.map { $0.rawValue }.joined(separator: ", "))")
        print("   📊 Status: \(viewModel.activeListingStatus.rawValue)")

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

        print("🔍 [FILTERS] All filters reset")
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

struct MoreFiltersSheet_More_Filters_Sheet_Previews: PreviewProvider {
    static var previews: some View {
        MoreFiltersSheet(viewModel: HousingSearchViewModel())
    }
}
