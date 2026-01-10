//
//  MarketTrendsModels.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Data models for Market Trends tab
//

import Foundation
import SwiftUI

// MARK: - Market Trends Data

struct MarketTrendsData: Identifiable {
    let id: String = UUID().uuidString
    let location: String
    let averageRent: Double           // $1,407
    let rentChange12Month: Double     // 0.5 (percentage)
    let lowRent: Double               // $560
    let highRent: Double              // $3,400
    let bedroomStats: [BedroomStats]
    let lastUpdated: Date
}

// MARK: - Bedroom Statistics

struct BedroomStats: Identifiable {
    let id: String = UUID().uuidString
    let bedroomCount: Int             // 0 = Studio, 1-5 = bedrooms
    let averageRent: Double
    let rentChange: Double            // Percentage change
    let sampleSize: Int

    var bedroomLabel: String {
        switch bedroomCount {
        case 0: return "Studio"
        case 1: return "1 BD"
        case 2: return "2 BD"
        case 3: return "3 BD"
        case 4: return "4 BD"
        case 5: return "5 BD"
        default: return "\(bedroomCount) BD"
        }
    }

    var changeColor: Color {
        rentChange >= 0 ? .billixMoneyGreen : .billixStreakOrange
    }

    var changePrefix: String {
        rentChange >= 0 ? "+" : ""
    }

    var formattedRent: String {
        "$\(Int(averageRent))/mo"
    }

    var formattedChange: String {
        "\(changePrefix)\(String(format: "%.1f", rentChange))%"
    }
}

// MARK: - Rent History Point

struct RentHistoryPoint: Identifiable {
    let id: String = UUID().uuidString
    let date: Date
    let bedroomType: BedroomType
    let rent: Double
}

// MARK: - Bedroom Type Enum

enum BedroomType: String, CaseIterable, Identifiable {
    case average = "Average"
    case studio = "Studio"
    case oneBed = "1 BD"
    case twoBed = "2 BD"
    case threeBed = "3 BD"
    case fourBed = "4 BD"
    case fiveBed = "5 BD"

    var id: String { rawValue }

    var bedroomCount: Int {
        switch self {
        case .studio: return 0
        case .oneBed: return 1
        case .twoBed: return 2
        case .threeBed: return 3
        case .fourBed: return 4
        case .fiveBed: return 5
        case .average: return -1
        }
    }

    var chartColor: Color {
        switch self {
        case .average: return .billixDarkTeal
        case .studio: return Color(hex: "5d4db1")  // Purple
        case .oneBed: return Color(hex: "52b8df")  // Blue
        case .twoBed: return .billixMoneyGreen
        case .threeBed: return .billixGoldenAmber
        case .fourBed: return .billixStreakOrange
        case .fiveBed: return Color(hex: "dc6b62")  // Pink
        }
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable, Identifiable {
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var monthsBack: Int {
        switch self {
        case .sixMonths: return 6
        case .oneYear: return 12
        case .allTime: return 24  // 2 years for mock data
        }
    }
}
