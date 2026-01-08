//
//  PropertyMapView.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Interactive MapKit view with tappable property markers
//

import SwiftUI
import MapKit

struct PropertyMapView: View {
    let searchedProperty: PropertyMarker?
    let comparables: [PropertyMarker]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPropertyId: String?
    var onPinTap: (String) -> Void

    @State private var position: MapCameraPosition

    init(
        searchedProperty: PropertyMarker? = nil,
        comparables: [PropertyMarker],
        region: Binding<MKCoordinateRegion>,
        selectedPropertyId: Binding<String?>,
        onPinTap: @escaping (String) -> Void
    ) {
        self.searchedProperty = searchedProperty
        self.comparables = comparables
        self._region = region
        self._selectedPropertyId = selectedPropertyId
        self.onPinTap = onPinTap
        self._position = State(initialValue: .region(region.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Locations")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            Map(position: $position) {
                // Main searched property (blue pin) - optional
                if let searched = searchedProperty {
                    Annotation("", coordinate: searched.coordinate) {
                        PropertyPin(
                            isSelected: searched.id == selectedPropertyId,
                            isMain: true
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                onPinTap(searched.id)
                            }
                        }
                    }
                }

                // Comparable properties (green pins) - tappable
                ForEach(comparables) { comp in
                    Annotation("", coordinate: comp.coordinate) {
                        PropertyPin(
                            isSelected: comp.id == selectedPropertyId,
                            isMain: false
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                onPinTap(comp.id)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            // Legend
            HStack(spacing: 20) {
                if searchedProperty != nil {
                    LegendItem(color: .blue, label: "Selected")
                }
                LegendItem(color: .billixMoneyGreen, label: "Properties")
            }
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

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Property Map View") {
    PropertyMapView(
        searchedProperty: PropertyMarker(
            id: "searched",
            coordinate: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
            isSearchedProperty: true
        ),
        comparables: [
            PropertyMarker(
                id: "comp1",
                coordinate: CLLocationCoordinate2D(latitude: 42.3354, longitude: -83.0498),
                isSearchedProperty: false
            ),
            PropertyMarker(
                id: "comp2",
                coordinate: CLLocationCoordinate2D(latitude: 42.3274, longitude: -83.0418),
                isSearchedProperty: false
            ),
            PropertyMarker(
                id: "comp3",
                coordinate: CLLocationCoordinate2D(latitude: 42.3344, longitude: -83.0428),
                isSearchedProperty: false
            )
        ],
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )),
        selectedPropertyId: .constant(nil),
        onPinTap: { _ in }
    )
    .padding()
    .background(Color.billixCreamBeige)
}
