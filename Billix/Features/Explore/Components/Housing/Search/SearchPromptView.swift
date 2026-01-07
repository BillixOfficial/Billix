//
//  SearchPromptView.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Empty state composing all search components
//

import SwiftUI

struct SearchPromptView: View {
    @ObservedObject var viewModel: HousingSearchViewModel
    let onSearch: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Properties")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Look up rent estimates, comparable listings and market trends for any property in your area")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Search Bar
                PropertySearchBar(address: $viewModel.searchAddress)

                // Property Filters
                PropertyFiltersPanel(
                    propertyType: $viewModel.selectedPropertyType,
                    bedrooms: $viewModel.selectedBedrooms,
                    bathrooms: $viewModel.selectedBathrooms,
                    squareFeet: $viewModel.squareFeet
                )

                // Search Settings
                SearchSettingsPanel(
                    searchRadius: $viewModel.searchRadius,
                    lookbackDays: $viewModel.lookbackDays
                )

                // Search Button
                SearchButton(
                    action: onSearch,
                    isEnabled: viewModel.canSearch,
                    isLoading: viewModel.isLoading
                )

                // Clear Search Link
                if viewModel.hasSearched {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Text("Clear Search")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.billixDarkTeal)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Clear search and reset filters")
                }

                // Extra bottom padding for tab bar
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 0)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("Search Prompt View - Empty") {
    SearchPromptView(
        viewModel: HousingSearchViewModel(),
        onSearch: {}
    )
}

#Preview("Search Prompt View - With Values") {
    let vm = HousingSearchViewModel()
    vm.searchAddress = "48067"
    vm.selectedPropertyType = .singleFamily
    vm.selectedBedrooms = 2
    vm.selectedBathrooms = 1.5
    vm.squareFeet = "950"

    return SearchPromptView(
        viewModel: vm,
        onSearch: {}
    )
}
