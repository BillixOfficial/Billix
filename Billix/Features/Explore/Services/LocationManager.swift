//
//  LocationManager.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Location state management for Explore marketplace
//

import Foundation
import Combine

/// Manages location selection and persistence for Explore marketplace
@MainActor
class LocationManager: ObservableObject {

    // MARK: - Published Properties

    /// Currently selected location for marketplace filtering
    @Published var selectedLocation: Location

    // MARK: - Private Properties

    private let userDefaultsKey = "ExploreSelectedLocation"

    // MARK: - Initialization

    init() {
        // Load saved location or use default
        if let savedLocation = Self.loadSavedLocation() {
            self.selectedLocation = savedLocation
        } else {
            self.selectedLocation = Location.defaultLocation
            // Save default on first launch
            saveLocation(Location.defaultLocation)
        }
    }

    // MARK: - Public Methods

    /// Update selected location and persist to UserDefaults
    func selectLocation(_ location: Location) {
        selectedLocation = location
        saveLocation(location)
    }

    /// Reset to default location (Metro Detroit)
    func resetToDefault() {
        selectLocation(Location.defaultLocation)
    }

    // MARK: - Persistence

    /// Save location to UserDefaults
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Load location from UserDefaults
    private static func loadSavedLocation() -> Location? {
        guard let data = UserDefaults.standard.data(forKey: "ExploreSelectedLocation"),
              let location = try? JSONDecoder().decode(Location.self, from: data) else {
            return nil
        }
        return location
    }

    // MARK: - Mock Data Helpers

    /// Get all available locations (for picker UI)
    var availableLocations: [Location] {
        Location.mockLocations
    }

    /// Check if current location is the default
    var isDefaultLocation: Bool {
        selectedLocation == Location.defaultLocation
    }
}

// MARK: - Preview Helper

extension LocationManager {
    /// Create LocationManager with specific location for previews
    static func preview(location: Location = .defaultLocation) -> LocationManager {
        let manager = LocationManager()
        manager.selectedLocation = location
        return manager
    }
}
