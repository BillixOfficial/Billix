//
//  ComparablesTable.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Main table container with horizontal scroll for comparable listings
//

import SwiftUI

struct ComparablesTable: View {
    @ObservedObject var viewModel: HousingSearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and description
            VStack(alignment: .leading, spacing: 6) {
                Text("Comparable Listings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if let estimate = viewModel.rentEstimate {
                    Text("Based on \(estimate.comparablesCount) rental\(estimate.comparablesCount == 1 ? "" : "s") within \(viewModel.searchRadius, specifier: "%.1f") mile radius")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            // Scrollable table
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Header row with sort buttons
                    ComparableHeaderRow(
                        sortColumn: viewModel.sortColumn,
                        sortAscending: viewModel.sortAscending,
                        onSort: { column in
                            viewModel.sortComparables(by: column)
                        }
                    )

                    Divider()

                    // Data rows
                    ForEach(Array(viewModel.sortedComparables.enumerated()), id: \.element.id) { index, comp in
                        ComparableRow(
                            comparable: comp,
                            rowNumber: index + 1,
                            isSelected: comp.id == viewModel.selectedPropertyId
                        )

                        if index < viewModel.sortedComparables.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }

            // Scroll hint
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11))
                Text("Scroll horizontally to view all columns")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview

struct ComparablesTable_Comparables_Table_Previews: PreviewProvider {
    static var previews: some View {
        let vm = HousingSearchViewModel()
        
        // Generate mock data
        let params = PropertySearchParams(
        address: "48067",
        propertyType: .all,
        bedrooms: 2,
        bathrooms: 1.5,
        squareFeet: 950,
        searchRadius: 1.0,
        lookbackDays: 30
        )
        
        let estimate = HousingMockData.generateRentEstimate(params: params)
        let comps = HousingMockData.generateComparables(params: params, estimate: estimate)
        
        vm.rentEstimate = estimate
        vm.comparables = comps
        
        return ComparablesTable(viewModel: vm)
        .padding()
        .background(Color.billixCreamBeige)
    }
}
