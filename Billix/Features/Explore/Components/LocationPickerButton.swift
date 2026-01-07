//
//  LocationPickerButton.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Pill-shaped location picker button for Explore header
//

import SwiftUI

/// Pill-shaped button that opens location picker sheet
struct LocationPickerButton: View {

    // MARK: - Properties

    @ObservedObject var locationManager: LocationManager
    @State private var showingLocationPicker = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            showingLocationPicker = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .medium))

                Text(locationManager.selectedLocation.displayName)
                    .font(.system(size: 15, weight: .semibold))

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.billixDarkTeal)
            )
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerSheet(locationManager: locationManager, isPresented: $showingLocationPicker)
        }
    }
}

// MARK: - Location Picker Sheet

struct LocationPickerSheet: View {

    // MARK: - Properties

    @ObservedObject var locationManager: LocationManager
    @Binding var isPresented: Bool

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                ForEach(locationManager.availableLocations, id: \.self) { location in
                    LocationPickerRow(
                        location: location,
                        isSelected: location == locationManager.selectedLocation
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        locationManager.selectLocation(location)
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.billixDarkTeal)
                }
            }
        }
    }
}

// MARK: - Location Picker Row

struct LocationPickerRow: View {

    // MARK: - Properties

    let location: Location
    let isSelected: Bool

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.metro)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(location.fullName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.billixMoneyGreen)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Location Picker Button") {
    VStack {
        LocationPickerButton(locationManager: .preview())
    }
    .padding()
    .background(Color.billixCreamBeige)
}

#Preview("Location Picker Sheet") {
    LocationPickerSheet(
        locationManager: .preview(),
        isPresented: .constant(true)
    )
}

#Preview("Location Picker Row - Selected") {
    LocationPickerRow(
        location: Location.defaultLocation,
        isSelected: true
    )
}

#Preview("Location Picker Row - Unselected") {
    LocationPickerRow(
        location: Location.mockLocations[1],
        isSelected: false
    )
}
