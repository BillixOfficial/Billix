//
//  TotalSurvivalBadge.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Dynamic ticker showing estimated monthly survival cost (rent + utilities)
//

import SwiftUI

/// Badge displaying total monthly survival cost with count-up animation
struct TotalSurvivalBadge: View {

    // MARK: - Properties

    @ObservedObject var locationManager: LocationManager
    @State private var displayedAmount: Double = 0
    @State private var isLoading = false

    // MARK: - Computed Properties

    private var targetAmount: Double {
        MockSurvivalCostData.getSurvivalCost(for: locationManager.selectedLocation)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixGoldenAmber)

            if isLoading {
                Text("Calculating...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("Est. Monthly Basic:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("$\(Int(displayedAmount))/mo")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixDarkTeal)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .onChange(of: locationManager.selectedLocation) { oldLocation, newLocation in
            animateCountUp(to: targetAmount)
        }
        .onAppear {
            animateCountUp(to: targetAmount)
        }
    }

    // MARK: - Animation

    private func animateCountUp(to target: Double) {
        isLoading = true

        // Simulate brief loading state
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
            displayedAmount = 0

            // Count up animation over 1 second
            withAnimation(.linear(duration: 1.0)) {
                displayedAmount = target
            }
        }
    }
}

// MARK: - Mock Survival Cost Data

/// Mock data provider for total survival costs by location
struct MockSurvivalCostData {

    /// Get estimated monthly survival cost (rent + utilities) for a location
    static func getSurvivalCost(for location: Location) -> Double {
        // Mock data: rent avg + utilities avg
        switch location.metro {
        case "Metro Detroit":
            return 2450 // $1,650 rent + $800 utilities

        case "San Francisco Bay Area":
            return 4200 // $3,200 rent + $1,000 utilities

        case "Greater Chicago":
            return 2800 // $1,900 rent + $900 utilities

        case "Metro Atlanta":
            return 2600 // $1,750 rent + $850 utilities

        case "Greater Seattle":
            return 3500 // $2,500 rent + $1,000 utilities

        case "Metro Phoenix":
            return 2400 // $1,600 rent + $800 utilities

        case "Greater Boston":
            return 3900 // $2,900 rent + $1,000 utilities

        case "Metro Denver":
            return 3100 // $2,200 rent + $900 utilities

        default:
            return 2450 // Default to Detroit
        }
    }

    /// Get breakdown of costs (for future detail views)
    static func getBreakdown(for location: Location) -> (rent: Double, utilities: Double) {
        let total = getSurvivalCost(for: location)

        switch location.metro {
        case "Metro Detroit":
            return (1650, 800)
        case "San Francisco Bay Area":
            return (3200, 1000)
        case "Greater Chicago":
            return (1900, 900)
        case "Metro Atlanta":
            return (1750, 850)
        case "Greater Seattle":
            return (2500, 1000)
        case "Metro Phoenix":
            return (1600, 800)
        case "Greater Boston":
            return (2900, 1000)
        case "Metro Denver":
            return (2200, 900)
        default:
            return (1650, 800)
        }
    }
}

// MARK: - Previews

struct TotalSurvivalBadge_Total_Survival_Badge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        TotalSurvivalBadge(locationManager: .preview())
        
        TotalSurvivalBadge(
        locationManager: .preview(location: Location.mockLocations[1])
        )
        
        TotalSurvivalBadge(
        locationManager: .preview(location: Location.mockLocations[2])
        )
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
