//
//  FeedFiltersBar.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Horizontal scrolling filter chip container with functional pickers
//

import SwiftUI

struct FeedFiltersBar: View {
    @ObservedObject var viewModel: HousingSearchViewModel

    @State private var showBedroomPicker = false
    @State private var showBathroomPicker = false
    @State private var showMoreFilters = false

    var body: some View {
        filterScrollView
            .confirmationDialog("Bedrooms", isPresented: $showBedroomPicker) {
                bedroomButtons
            }
            .confirmationDialog("Bathrooms", isPresented: $showBathroomPicker) {
                bathroomButtons
            }
            .sheet(isPresented: $showMoreFilters) {
                MoreFiltersSheet(viewModel: viewModel)
            }
    }

    // MARK: - Subviews

    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Bedrooms Filter
                FilterChip(
                    label: viewModel.activeBedrooms == nil ? "Beds" : "\(viewModel.activeBedrooms!)+ beds",
                    icon: "bed.double.fill",
                    isSelected: viewModel.activeBedrooms != nil
                ) {
                    showBedroomPicker = true
                }

                // Bathrooms Filter
                FilterChip(
                    label: viewModel.activeBathrooms == nil ? "Baths" : String(format: "%.1f+ bath", viewModel.activeBathrooms!),
                    icon: "shower.fill",
                    isSelected: viewModel.activeBathrooms != nil
                ) {
                    showBathroomPicker = true
                }

                // "More" Button (consolidates Property Type, Radius, Location)
                Button {
                    showMoreFilters = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))

                        Text("More")
                            .font(.system(size: 14, weight: .medium))

                        if activeFiltersCount > 0 {
                            Text("(\(activeFiltersCount))")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(activeFiltersCount > 0 ? Color.billixDarkTeal.opacity(0.15) : Color.gray.opacity(0.1))
                    .foregroundColor(activeFiltersCount > 0 ? .billixDarkTeal : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .accessibilityLabel("More filters")

                // Reset Filters Button
                if showResetButton {
                    Button {
                        viewModel.resetFilters()
                    } label: {
                        Text("Reset")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.billixDarkTeal)
                    }
                    .accessibilityLabel("Reset all filters")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white.opacity(0.95))
    }

    private var showResetButton: Bool {
        viewModel.activeBedrooms != nil ||
        viewModel.activeBathrooms != nil
    }

    private var activeFiltersCount: Int {
        var count = 0
        if viewModel.activePropertyType != .all { count += 1 }
        if viewModel.activeRadius != 3.0 { count += 1 }
        if !viewModel.activeLocation.isEmpty { count += 1 }
        return count
    }

    @ViewBuilder
    private var bedroomButtons: some View {
        Button("Any") {
            viewModel.activeBedrooms = nil
            Task { await viewModel.applyFilters() }
        }
        ForEach([1, 2, 3, 4, 5], id: \.self) { beds in
            Button("\(beds)+ beds") {
                viewModel.activeBedrooms = beds
                Task { await viewModel.applyFilters() }
            }
        }
    }

    @ViewBuilder
    private var bathroomButtons: some View {
        Button("Any") {
            viewModel.activeBathrooms = nil
            Task { await viewModel.applyFilters() }
        }
        ForEach([1.0, 1.5, 2.0, 2.5, 3.0], id: \.self) { baths in
            Button(String(format: "%.1f+ bath", baths)) {
                viewModel.activeBathrooms = baths
                Task { await viewModel.applyFilters() }
            }
        }
    }
}

struct FeedFiltersBar_Feed_Filters_Bar_Previews: PreviewProvider {
    static var previews: some View {
        FeedFiltersBar(viewModel: HousingSearchViewModel())
        .background(Color.billixCreamBeige)
    }
}
