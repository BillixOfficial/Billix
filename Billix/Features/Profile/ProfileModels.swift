//
//  ProfileModels.swift
//  Billix
//
//  Data models for the Profile feature
//

import SwiftUI

// MARK: - Profile Tab Enum

enum ProfileTab: String, CaseIterable {
    case about = "ABOUT"
    case account = "ACCOUNT"
    case settings = "SETTINGS"
    case support = "SUPPORT"
}

// MARK: - Profile Data Model
// Note: VerificationTier is defined in IDVerificationService.swift

struct ProfileData {
    var name: String
    var email: String
    var dateOfBirth: String
    var address: String
    var profileImageName: String?
    var phone: String

    // ABOUT tab data
    var bio: String
    var socialLinks: [SocialLink]
    var website: String

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    static let preview = ProfileData(
        name: "Emily Nelson",
        email: "emilynelson@gmail.com",
        dateOfBirth: "06/15/1990",
        address: "123 Main St, Newark, NJ",
        profileImageName: nil,
        phone: "+1 (555) 123-4567",
        bio: "Passionate about saving money and helping others manage their bills better. Always looking for the best deals!",
        socialLinks: [
            SocialLink(platform: "twitter", username: "@emilynelson"),
            SocialLink(platform: "linkedin", username: "emilynelson"),
            SocialLink(platform: "instagram", username: "@emily.nelson"),
            SocialLink(platform: "facebook", username: "emily.nelson")
        ],
        website: "www.emilynelson.com"
    )
}

// MARK: - Social Link Model

struct SocialLink: Identifiable {
    let id = UUID()
    var platform: String
    var username: String

    var iconName: String {
        switch platform.lowercased() {
        case "twitter", "x": return "paperplane.fill"
        case "linkedin": return "link"
        case "instagram": return "camera.fill"
        case "facebook": return "person.2.fill"
        default: return "link"
        }
    }

    var color: Color {
        switch platform.lowercased() {
        case "twitter", "x": return Color(hex: "#1DA1F2")
        case "linkedin": return Color(hex: "#0077B5")
        case "instagram": return Color(hex: "#E4405F")
        case "facebook": return Color(hex: "#1877F2")
        default: return .gray
        }
    }
}

// MARK: - Household Models

struct HouseholdMember: Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let role: String
    let joinedAt: Date
}

struct HouseholdDB: Codable {
    let id: UUID
    let name: String
    let invite_code: String
    let owner_id: UUID
    let max_members: Int
    let created_at: Date
    let updated_at: Date
}

struct HouseholdInsert: Codable {
    let name: String
    let owner_id: UUID
}

struct HouseholdMemberDB: Codable {
    let id: UUID
    let household_id: UUID
    let user_id: UUID
    let role: String
    let joined_at: Date
    let households: HouseholdDB?
}

struct HouseholdMemberInsert: Codable {
    let household_id: UUID
    let user_id: UUID
    let role: String
}

struct HouseholdMemberWithProfile: Codable {
    let id: UUID
    let household_id: UUID
    let user_id: UUID
    let role: String
    let joined_at: Date
    let profiles: ProfileRef?
}

struct ProfileRef: Codable {
    let display_name: String?
    let user_id: UUID
}

// MARK: - Helper Response Models

struct VerifiedOnlyResponse: Codable {
    let verified_only_mode: Bool?
}
