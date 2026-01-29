//
//  USRegion.swift
//  Billix
//
//  US geographic regions for Bill Explorer location filtering
//

import Foundation

enum USRegion: String, CaseIterable, Identifiable {
    case all = "All"
    case northeast = "Northeast"
    case southeast = "Southeast"
    case midwest = "Midwest"
    case southwest = "Southwest"
    case west = "West"

    var id: String { rawValue }

    /// States included in this region (using 2-letter codes)
    var states: [String] {
        switch self {
        case .all:
            return []
        case .northeast:
            return ["CT", "DE", "MA", "MD", "ME", "NH", "NJ", "NY", "PA", "RI", "VT", "DC"]
        case .southeast:
            return ["AL", "AR", "FL", "GA", "KY", "LA", "MS", "NC", "SC", "TN", "VA", "WV"]
        case .midwest:
            return ["IA", "IL", "IN", "KS", "MI", "MN", "MO", "ND", "NE", "OH", "SD", "WI"]
        case .southwest:
            return ["AZ", "NM", "OK", "TX"]
        case .west:
            return ["AK", "CA", "CO", "HI", "ID", "MT", "NV", "OR", "UT", "WA", "WY"]
        }
    }

    /// Full state names for display
    var stateNames: [String: String] {
        [
            "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas",
            "CA": "California", "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware",
            "DC": "Washington DC", "FL": "Florida", "GA": "Georgia", "HI": "Hawaii",
            "ID": "Idaho", "IL": "Illinois", "IN": "Indiana", "IA": "Iowa",
            "KS": "Kansas", "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine",
            "MD": "Maryland", "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota",
            "MS": "Mississippi", "MO": "Missouri", "MT": "Montana", "NE": "Nebraska",
            "NV": "Nevada", "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico",
            "NY": "New York", "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio",
            "OK": "Oklahoma", "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island",
            "SC": "South Carolina", "SD": "South Dakota", "TN": "Tennessee", "TX": "Texas",
            "UT": "Utah", "VT": "Vermont", "VA": "Virginia", "WA": "Washington",
            "WV": "West Virginia", "WI": "Wisconsin", "WY": "Wyoming"
        ]
    }

    /// Get full state name from code
    func stateName(for code: String) -> String {
        stateNames[code] ?? code
    }

    /// Check if a state belongs to this region
    func contains(state: String) -> Bool {
        if self == .all { return true }
        return states.contains(state.uppercased())
    }

    /// Get the region for a given state code
    static func region(for stateCode: String) -> USRegion {
        let code = stateCode.uppercased()
        for region in USRegion.allCases where region != .all {
            if region.states.contains(code) {
                return region
            }
        }
        return .all
    }

    /// Display icon for the region
    var icon: String {
        switch self {
        case .all: return "globe.americas.fill"
        case .northeast: return "building.2.fill"
        case .southeast: return "sun.max.fill"
        case .midwest: return "leaf.fill"
        case .southwest: return "mountain.2.fill"
        case .west: return "water.waves"
        }
    }

    /// Accent color for the region
    var color: String {
        switch self {
        case .all: return "#5B8A6B"
        case .northeast: return "#6366F1"  // Indigo
        case .southeast: return "#F59E0B"  // Amber
        case .midwest: return "#10B981"    // Green
        case .southwest: return "#EF4444"  // Red
        case .west: return "#3B82F6"       // Blue
        }
    }
}
