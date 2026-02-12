//
//  DonationModels.swift
//  Billix
//
//  Models for custom charity donation requests
//  Users submit requests, we verify and process manually
//

import Foundation
import SwiftUI

// MARK: - Donation Category

enum DonationCategory: String, Codable, CaseIterable {
    case hunger
    case environment
    case animals
    case education
    case health
    case community

    var displayName: String {
        switch self {
        case .hunger: return "Fight Hunger"
        case .environment: return "Environment"
        case .animals: return "Animal Welfare"
        case .education: return "Education"
        case .health: return "Health"
        case .community: return "Community"
        }
    }

    var icon: String {
        switch self {
        case .hunger: return "fork.knife.circle.fill"
        case .environment: return "leaf.circle.fill"
        case .animals: return "pawprint.circle.fill"
        case .education: return "book.circle.fill"
        case .health: return "heart.circle.fill"
        case .community: return "building.2.circle.fill"
        }
    }
}

// MARK: - Donation (Featured Charity)

struct Donation: Identifiable {
    let id: UUID
    let charityName: String
    let category: DonationCategory
    let logoName: String // SF Symbol name
    let accentColor: String // Hex color
    let impactTitle: String
    let impactDescription: String
    let dollarValue: Double
    let pointsCost: Int

    init(
        id: UUID = UUID(),
        charityName: String,
        category: DonationCategory,
        logoName: String,
        accentColor: String,
        impactTitle: String,
        impactDescription: String,
        dollarValue: Double
    ) {
        self.id = id
        self.charityName = charityName
        self.category = category
        self.logoName = logoName
        self.accentColor = accentColor
        self.impactTitle = impactTitle
        self.impactDescription = impactDescription
        self.dollarValue = dollarValue
        self.pointsCost = Int(dollarValue * 2000) // $1 = 2,000 points
    }

    static let previewDonations: [Donation] = [
        Donation(
            charityName: "Feeding America",
            category: .hunger,
            logoName: "fork.knife",
            accentColor: "#E8A54B",
            impactTitle: "Feed a family for a week",
            impactDescription: "Your donation provides 10 meals to families facing hunger in your community.",
            dollarValue: 5.00
        ),
        Donation(
            charityName: "American Red Cross",
            category: .health,
            logoName: "cross.fill",
            accentColor: "#E31B23",
            impactTitle: "Support disaster relief",
            impactDescription: "Help provide shelter, food, and comfort to disaster victims.",
            dollarValue: 10.00
        ),
        Donation(
            charityName: "One Tree Planted",
            category: .environment,
            logoName: "leaf.fill",
            accentColor: "#2D7D46",
            impactTitle: "Plant 5 trees",
            impactDescription: "Restore forests and fight climate change one tree at a time.",
            dollarValue: 5.00
        ),
        Donation(
            charityName: "Best Friends Animal Society",
            category: .animals,
            logoName: "pawprint.fill",
            accentColor: "#7B4397",
            impactTitle: "Save a shelter pet",
            impactDescription: "Help provide care and find homes for animals in need.",
            dollarValue: 10.00
        ),
        Donation(
            charityName: "DonorsChoose",
            category: .education,
            logoName: "book.fill",
            accentColor: "#00A651",
            impactTitle: "Fund a classroom project",
            impactDescription: "Support teachers and students with essential learning supplies.",
            dollarValue: 10.00
        ),
        Donation(
            charityName: "Habitat for Humanity",
            category: .community,
            logoName: "house.fill",
            accentColor: "#F5821F",
            impactTitle: "Build affordable housing",
            impactDescription: "Help families achieve the strength and stability of homeownership.",
            dollarValue: 25.00
        )
    ]
}

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
