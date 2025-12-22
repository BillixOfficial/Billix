//
//  DonationModels.swift
//  Billix
//
//  Models for custom charity donation requests
//  Users submit requests, we verify and process manually
//

import Foundation
import SwiftUI

// MARK: - Donation Request

struct DonationRequest: Identifiable, Codable {
    let id: UUID
    let organizationName: String
    let websiteOrLocation: String // For verification
    let amount: DonationAmount
    let donateInMyName: Bool
    let donorName: String?
    let donorEmail: String?
    let pointsUsed: Int
    let status: RequestStatus
    let createdAt: Date
    let processedAt: Date?

    enum RequestStatus: String, Codable {
        case pending = "Pending Review"
        case approved = "Approved"
        case processing = "Processing"
        case completed = "Completed"
        case rejected = "Rejected"
    }
}

// MARK: - Donation Amount

enum DonationAmount: Int, Codable, CaseIterable {
    case five = 5
    case ten = 10
    case twentyFive = 25

    var pointsCost: Int {
        rawValue * 2000 // $1 = 2,000 points
    }

    var displayText: String {
        "$\(rawValue)"
    }

    var pointsText: String {
        "\(pointsCost) pts"
    }
}

// MARK: - Preview Data

extension DonationRequest {
    static let previewRequests: [DonationRequest] = [
        DonationRequest(
            id: UUID(),
            organizationName: "American Red Cross",
            websiteOrLocation: "redcross.org",
            amount: .ten,
            donateInMyName: true,
            donorName: "John Doe",
            donorEmail: "john@example.com",
            pointsUsed: 20000,
            status: .pending,
            createdAt: Date(),
            processedAt: nil
        ),
        DonationRequest(
            id: UUID(),
            organizationName: "Local Food Bank",
            websiteOrLocation: "Seattle, WA",
            amount: .five,
            donateInMyName: false,
            donorName: nil,
            donorEmail: nil,
            pointsUsed: 10000,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400),
            processedAt: Date()
        )
    ]
}
