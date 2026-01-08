//
//  FairValue.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Fair value enum for property pricing badges
//

import SwiftUI

enum FairValue {
    case greatDeal      // <-10% below median
    case fairPrice      // Within ±10%
    case aboveAverage   // >+10% above median

    var label: String {
        switch self {
        case .greatDeal: return "Great Deal"
        case .fairPrice: return "Fair Price"
        case .aboveAverage: return "Above Average"
        }
    }

    var color: Color {
        switch self {
        case .greatDeal: return .billixMoneyGreen
        case .fairPrice: return .billixDarkTeal
        case .aboveAverage: return .orange
        }
    }

    var icon: String {
        switch self {
        case .greatDeal: return "arrow.down.circle.fill"
        case .fairPrice: return "equal.circle.fill"
        case .aboveAverage: return "arrow.up.circle.fill"
        }
    }
}
