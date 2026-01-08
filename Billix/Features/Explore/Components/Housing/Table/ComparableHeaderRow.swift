//
//  ComparableHeaderRow.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Column headers with sort indicators for comparables table
//

import SwiftUI

struct ComparableHeaderRow: View {
    let sortColumn: ComparableColumn
    let sortAscending: Bool
    let onSort: (ComparableColumn) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Column 1: Row Number (#)
            Text("#")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .frame(width: 30, alignment: .center)
                .padding(.vertical, 12)

            // Column 2: Address
            HeaderButton(
                column: .address,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 3: Listed Rent
            HeaderButton(
                column: .rent,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 4: Last Seen
            HeaderButton(
                column: .lastSeen,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 5: Similarity %
            HeaderButton(
                column: .similarity,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 6: Distance
            HeaderButton(
                column: .distance,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 7: Beds
            HeaderButton(
                column: .beds,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 8: Baths
            HeaderButton(
                column: .baths,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 9: Sq.Ft.
            HeaderButton(
                column: .sqft,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )

            // Column 10: Type
            HeaderButton(
                column: .type,
                currentSort: sortColumn,
                sortAscending: sortAscending,
                onSort: onSort
            )
        }
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Header Button

struct HeaderButton: View {
    let column: ComparableColumn
    let currentSort: ComparableColumn
    let sortAscending: Bool
    let onSort: (ComparableColumn) -> Void

    private var isActive: Bool {
        column == currentSort
    }

    private var sortIcon: String {
        guard isActive else { return "" }
        return sortAscending ? "chevron.up" : "chevron.down"
    }

    var body: some View {
        Button {
            onSort(column)
        } label: {
            HStack(spacing: 4) {
                Text(column.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? .billixDarkTeal : .secondary)
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .multilineTextAlignment(column.alignment == .center ? .center : .leading)

                if isActive {
                    Image(systemName: sortIcon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .frame(width: column.width, alignment: column.alignment == .center ? .center : .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .accessibilityLabel("Sort by \(column.rawValue)")
    }
}

// MARK: - Preview

#Preview("Header Row") {
    ScrollView(.horizontal) {
        VStack(spacing: 0) {
            ComparableHeaderRow(
                sortColumn: .similarity,
                sortAscending: false,
                onSort: { _ in }
            )

            Divider()

            ComparableHeaderRow(
                sortColumn: .rent,
                sortAscending: true,
                onSort: { _ in }
            )
        }
    }
    .background(Color.white)
}
