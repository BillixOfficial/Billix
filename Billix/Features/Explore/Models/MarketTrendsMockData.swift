//
//  MarketTrendsMockData.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Mock data generators for Market Trends
//

import Foundation

struct MarketTrendsMockData {

    // MARK: - Market Data Generation

    static func generateMarketData(location: String) -> MarketTrendsData {
        // Base rent varies by location
        let baseRent = locationBaseRent(location)

        let bedroomStats = [
            BedroomStats(
                bedroomCount: 0,
                averageRent: baseRent * 0.587,
                rentChange: -2.9,
                sampleSize: 45
            ),
            BedroomStats(
                bedroomCount: 1,
                averageRent: baseRent * 0.563,
                rentChange: 21.6,
                sampleSize: 67
            ),
            BedroomStats(
                bedroomCount: 2,
                averageRent: baseRent * 0.894,
                rentChange: 8.9,
                sampleSize: 89
            ),
            BedroomStats(
                bedroomCount: 3,
                averageRent: baseRent * 0.959,
                rentChange: -8.9,
                sampleSize: 54
            ),
            BedroomStats(
                bedroomCount: 4,
                averageRent: baseRent * 1.351,
                rentChange: 29.8,
                sampleSize: 32
            ),
            BedroomStats(
                bedroomCount: 5,
                averageRent: baseRent * 1.647,
                rentChange: -17.3,
                sampleSize: 18
            )
        ]

        return MarketTrendsData(
            location: location,
            averageRent: baseRent,
            rentChange12Month: 0.5,
            lowRent: baseRent * 0.398,
            highRent: baseRent * 2.417,
            bedroomStats: bedroomStats,
            lastUpdated: Date()
        )
    }

    // MARK: - History Data Generation

    static func generateHistoryData(location: String, monthsBack: Int) -> [RentHistoryPoint] {
        var points: [RentHistoryPoint] = []
        let baseRent = locationBaseRent(location)
        let calendar = Calendar.current

        // Generate data for each bedroom type
        for bedroomType in BedroomType.allCases {
            let typeBaseRent = bedroomTypeMultiplier(bedroomType) * baseRent

            // Generate monthly data points (going backwards from now)
            for monthOffset in 0..<monthsBack {
                guard let date = calendar.date(
                    byAdding: .month,
                    value: -monthOffset,
                    to: Date()
                ) else { continue }

                // Add upward trend and variation
                let monthsFromStart = Double(monthsBack - monthOffset)
                let trendFactor = 1.0 + (monthsFromStart * 0.002)  // Gradual increase
                let variation = Double.random(in: -0.05...0.05)     // ±5% random variation
                let rent = typeBaseRent * trendFactor * (1.0 + variation)

                points.append(RentHistoryPoint(
                    date: date,
                    bedroomType: bedroomType,
                    rent: rent
                ))
            }
        }

        return points.sorted { $0.date < $1.date }
    }

    // MARK: - Helper Methods

    private static func locationBaseRent(_ location: String) -> Double {
        let locationLower = location.lowercased()

        if locationLower.contains("new york") || locationLower.contains("nyc") || locationLower.contains("10001") {
            return 1407.0
        } else if locationLower.contains("san francisco") || locationLower.contains("94102") {
            return 2200.0
        } else if locationLower.contains("detroit") || locationLower.contains("48") {
            return 950.0
        } else if locationLower.contains("royal oak") {
            return 1050.0
        } else if locationLower.contains("austin") || locationLower.contains("78") {
            return 1550.0
        } else if locationLower.contains("chicago") || locationLower.contains("60") {
            return 1350.0
        } else if locationLower.contains("los angeles") || locationLower.contains("90") {
            return 1950.0
        } else if locationLower.contains("miami") || locationLower.contains("33") {
            return 1650.0
        } else {
            return 1200.0  // Default
        }
    }

    private static func bedroomTypeMultiplier(_ type: BedroomType) -> Double {
        switch type {
        case .average:    return 1.0
        case .studio:     return 0.587
        case .oneBed:     return 0.563
        case .twoBed:     return 0.894
        case .threeBed:   return 0.959
        case .fourBed:    return 1.351
        case .fiveBed:    return 1.647
        }
    }
}
