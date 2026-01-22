//
//  ReliefEnums.swift
//  Billix
//
//  Enums for the Relief feature
//

import Foundation
import SwiftUI

// MARK: - Relief Request Status

enum ReliefRequestStatus: String, Codable, CaseIterable {
    case pending
    case underReview = "under_review"
    case approved
    case denied
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .denied: return "Denied"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .underReview: return .blue
        case .approved: return .green
        case .denied: return .red
        case .completed: return .purple
        case .cancelled: return .gray
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .underReview: return "eye.fill"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "minus.circle.fill"
        }
    }
}

// MARK: - Bill Type

enum ReliefBillType: String, Codable, CaseIterable, Identifiable {
    case electric
    case gas
    case water
    case internet
    case phone
    case rent
    case mortgage
    case carPayment = "car_payment"
    case insurance
    case medical
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .electric: return "Electric"
        case .gas: return "Gas"
        case .water: return "Water"
        case .internet: return "Internet"
        case .phone: return "Phone"
        case .rent: return "Rent"
        case .mortgage: return "Mortgage"
        case .carPayment: return "Car Payment"
        case .insurance: return "Insurance"
        case .medical: return "Medical"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .gas: return "flame.fill"
        case .water: return "drop.fill"
        case .internet: return "wifi"
        case .phone: return "phone.fill"
        case .rent: return "house.fill"
        case .mortgage: return "building.columns.fill"
        case .carPayment: return "car.fill"
        case .insurance: return "shield.fill"
        case .medical: return "cross.case.fill"
        case .other: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .electric: return .yellow
        case .gas: return .orange
        case .water: return .blue
        case .internet: return .purple
        case .phone: return .green
        case .rent: return .brown
        case .mortgage: return .indigo
        case .carPayment: return .cyan
        case .insurance: return .teal
        case .medical: return .red
        case .other: return .gray
        }
    }
}

// MARK: - Income Level

enum ReliefIncomeLevel: String, Codable, CaseIterable, Identifiable {
    case under25k = "under_25k"
    case from25kTo50k = "25k_50k"
    case from50kTo75k = "50k_75k"
    case from75kTo100k = "75k_100k"
    case over100k = "over_100k"
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .under25k: return "Under $25,000"
        case .from25kTo50k: return "$25,000 - $50,000"
        case .from50kTo75k: return "$50,000 - $75,000"
        case .from75kTo100k: return "$75,000 - $100,000"
        case .over100k: return "Over $100,000"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

// MARK: - Employment Status

enum ReliefEmploymentStatus: String, Codable, CaseIterable, Identifiable {
    case employedFullTime = "employed_full_time"
    case employedPartTime = "employed_part_time"
    case selfEmployed = "self_employed"
    case unemployed
    case retired
    case student
    case disabled
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .employedFullTime: return "Employed Full-Time"
        case .employedPartTime: return "Employed Part-Time"
        case .selfEmployed: return "Self-Employed"
        case .unemployed: return "Unemployed"
        case .retired: return "Retired"
        case .student: return "Student"
        case .disabled: return "Disabled"
        case .other: return "Other"
        }
    }
}

// MARK: - Urgency Level

enum ReliefUrgencyLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case critical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var description: String {
        switch self {
        case .low: return "No immediate deadline"
        case .medium: return "Due within 2 weeks"
        case .high: return "Due within 1 week"
        case .critical: return "Past due or shutoff imminent"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "clock"
        case .medium: return "clock.badge"
        case .high: return "clock.badge.exclamationmark"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Document Type

enum ReliefDocumentType: String, Codable, CaseIterable, Identifiable {
    case billStatement = "bill_statement"
    case incomeProof = "income_proof"
    case shutoffNotice = "shutoff_notice"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .billStatement: return "Bill Statement"
        case .incomeProof: return "Income Proof"
        case .shutoffNotice: return "Shutoff Notice"
        case .other: return "Other Document"
        }
    }
}
