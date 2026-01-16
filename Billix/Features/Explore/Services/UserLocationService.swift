//
//  UserLocationService.swift
//  Billix
//
//  Created by Claude Code on 1/15/26.
//  Core Location service for getting user's GPS location
//

import Foundation
import CoreLocation

@MainActor
class UserLocationService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userZipCode: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request location permission from user
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current location (requests permission if needed)
    func getCurrentLocation() {
        isLoading = true
        errorMessage = nil

        print("📍 getCurrentLocation called, status: \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .notDetermined:
            print("📍 Requesting permission...")
            requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Permission granted, requesting location...")
            locationManager.requestLocation()
        case .denied, .restricted:
            print("📍 Permission denied")
            isLoading = false
            errorMessage = "Location access denied. Please enable in Settings."
        @unknown default:
            print("📍 Unknown status")
            isLoading = false
            errorMessage = "Unknown location status"
        }
    }

    /// Check if we have location permission
    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Check if permission was denied
    var permissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Private Methods

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    self.errorMessage = "Could not determine your area"
                    self.isLoading = false
                    return
                }

                if let placemark = placemarks?.first {
                    self.userZipCode = placemark.postalCode
                    print("📍 User location: \(placemark.locality ?? "Unknown"), \(placemark.postalCode ?? "No ZIP")")
                }

                self.isLoading = false
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension UserLocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.userLocation = location.coordinate
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            self.errorMessage = "Could not get your location"
            self.isLoading = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            print("📍 Authorization changed to: \(manager.authorizationStatus.rawValue)")

            // If user just granted permission, get location
            if self.hasPermission && self.isLoading {
                print("📍 Permission granted, now requesting location...")
                manager.requestLocation()
            }
        }
    }
}
