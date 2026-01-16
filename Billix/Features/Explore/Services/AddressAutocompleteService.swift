//
//  AddressAutocompleteService.swift
//  Billix
//
//  Created by Claude Code on 1/15/26.
//  Address autocomplete using MapKit's MKLocalSearchCompleter
//

import Foundation
import MapKit
import Combine

@MainActor
class AddressAutocompleteService: NSObject, ObservableObject {
    @Published var suggestions: [AddressSuggestion] = []
    @Published var isSearching: Bool = false

    private let completer = MKLocalSearchCompleter()
    private var currentQuery: String = ""

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address  // Only show addresses, not POIs
    }

    /// Search for address suggestions
    func search(query: String) {
        currentQuery = query

        // Don't search for very short queries
        guard query.count >= 3 else {
            suggestions = []
            isSearching = false
            return
        }

        isSearching = true
        completer.queryFragment = query
    }

    /// Clear suggestions
    func clear() {
        suggestions = []
        isSearching = false
        currentQuery = ""
    }

    /// Get full address from a suggestion
    func getFullAddress(for suggestion: AddressSuggestion) async -> String? {
        let searchRequest = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: searchRequest)

        do {
            let response = try await search.start()
            if let item = response.mapItems.first {
                return formatAddress(from: item.placemark)
            }
        } catch {
            print("❌ Error getting full address: \(error)")
        }

        return nil
    }

    /// Format a placemark into a full address string
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var components: [String] = []

        // Street address
        if let streetNumber = placemark.subThoroughfare,
           let street = placemark.thoroughfare {
            components.append("\(streetNumber) \(street)")
        } else if let street = placemark.thoroughfare {
            components.append(street)
        }

        // City
        if let city = placemark.locality {
            components.append(city)
        }

        // State
        if let state = placemark.administrativeArea {
            components.append(state)
        }

        // Zip code
        if let zip = placemark.postalCode {
            components.append(zip)
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension AddressAutocompleteService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.suggestions = completer.results.prefix(5).map { result in
                AddressSuggestion(
                    title: result.title,
                    subtitle: result.subtitle,
                    completion: result
                )
            }
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Autocomplete error: \(error)")
            self.suggestions = []
            self.isSearching = false
        }
    }
}

// MARK: - Address Suggestion Model

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String      // e.g., "218 W Farnum Ave"
    let subtitle: String   // e.g., "Royal Oak, MI"
    let completion: MKLocalSearchCompletion

    var displayText: String {
        if subtitle.isEmpty {
            return title
        }
        return "\(title), \(subtitle)"
    }
}
