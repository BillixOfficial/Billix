//
//  PropertyFiltersPanel.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Property features filter panel with dropdowns
//

import SwiftUI

struct PropertyFiltersPanel: View {
    @Binding var propertyType: PropertyType
    @Binding var bedrooms: Int?
    @Binding var bathrooms: Double?
    @Binding var squareFeet: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property features:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                // Property Type Menu
                PropertyTypeMenu(selectedType: $propertyType)

                // Bedrooms Menu
                BedroomsMenu(selectedBedrooms: $bedrooms)
            }

            HStack(spacing: 10) {
                // Bathrooms Menu
                BathroomsMenu(selectedBathrooms: $bathrooms)

                // Square Feet Input
                SquareFeetField(squareFeet: $squareFeet)
            }
        }
    }
}

// MARK: - Property Type Menu

struct PropertyTypeMenu: View {
    @Binding var selectedType: PropertyType

    var body: some View {
        Menu {
            ForEach(PropertyType.allCases) { type in
                Button {
                    selectedType = type
                } label: {
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedType.icon)
                    .font(.system(size: 14))
                Text(selectedType.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.billixDarkTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4)
            )
        }
        .accessibilityLabel("Property type: \(selectedType.rawValue)")
    }
}

// MARK: - Bedrooms Menu

struct BedroomsMenu: View {
    @Binding var selectedBedrooms: Int?

    private let bedroomOptions = [1, 2, 3, 4, 5]

    var body: some View {
        Menu {
            Button("Any") {
                selectedBedrooms = nil
            }

            ForEach(bedroomOptions, id: \.self) { count in
                Button("\(count) Bed") {
                    selectedBedrooms = count
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                Text(selectedBedrooms.map { "\($0) Bed" } ?? "Beds")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.billixDarkTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4)
            )
        }
        .accessibilityLabel("Bedrooms: \(selectedBedrooms.map { "\($0)" } ?? "Any")")
    }
}

// MARK: - Bathrooms Menu

struct BathroomsMenu: View {
    @Binding var selectedBathrooms: Double?

    private let bathroomOptions: [Double] = [1.0, 1.5, 2.0, 2.5, 3.0]

    var body: some View {
        Menu {
            Button("Any") {
                selectedBathrooms = nil
            }

            ForEach(bathroomOptions, id: \.self) { count in
                Button(formatBathrooms(count)) {
                    selectedBathrooms = count
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shower.fill")
                    .font(.system(size: 14))
                Text(selectedBathrooms.map { formatBathrooms($0) } ?? "Baths")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.billixDarkTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4)
            )
        }
        .accessibilityLabel("Bathrooms: \(selectedBathrooms.map { formatBathrooms($0) } ?? "Any")")
    }

    private func formatBathrooms(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value)) Bath"
        } else {
            return "\(value) Bath"
        }
    }
}

// MARK: - Square Feet Field

struct SquareFeetField: View {
    @Binding var squareFeet: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.fill")
                .font(.system(size: 14))
                .foregroundColor(.billixDarkTeal)

            TextField("Sq. Ft.", text: $squareFeet)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixDarkTeal)
                .keyboardType(.numberPad)
                .accessibilityLabel("Square feet")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4)
        )
    }
}

// MARK: - Preview

struct PropertyFiltersPanel_Property_Filters_Panel_Previews: PreviewProvider {
    static var previews: some View {
        PropertyFiltersPanel(
        propertyType: .constant(.singleFamily),
        bedrooms: .constant(2),
        bathrooms: .constant(1.5),
        squareFeet: .constant("950")
        )
        .padding()
        .background(Color.billixCreamBeige)
    }
}
