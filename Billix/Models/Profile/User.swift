import Foundation

// MARK: - User Profile Model

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var displayName: String?
    var email: String
    var phoneNumber: String?
    var zipCode: String
    var city: String
    var state: String

    // Verification status
    var isEmailVerified: Bool
    var isPhoneVerified: Bool

    // Account metadata
    var createdAt: Date
    var totalBillsUploaded: Int

    // Badges
    var badges: [UserBadge]

    // Avatar
    var avatarURL: String?

    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var zipBand: String {
        String(zipCode.prefix(3)) + "**"
    }

    var locationString: String {
        "\(city), \(state)"
    }

    var memberSinceString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Member since: \(formatter.string(from: createdAt))"
    }
}

// MARK: - User Badge

enum UserBadge: String, Codable, CaseIterable {
    case pioneer = "Billix Pioneer"
    case earlyUser = "Early User"
    case powerUser = "Power User"
    case savingsExpert = "Savings Expert"

    var icon: String {
        switch self {
        case .pioneer: return "star.fill"
        case .earlyUser: return "clock.fill"
        case .powerUser: return "bolt.fill"
        case .savingsExpert: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Preview Data

extension UserProfile {
    static let preview = UserProfile(
        id: UUID(),
        firstName: "Ronald",
        lastName: "Richards",
        displayName: nil,
        email: "ronald.richards@example.com",
        phoneNumber: "+1 (555) 123-4567",
        zipCode: "07054",
        city: "Newark",
        state: "NJ",
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        totalBillsUploaded: 16,
        badges: [.pioneer, .powerUser],
        avatarURL: nil
    )

    static let previewUnverified = UserProfile(
        id: UUID(),
        firstName: "Jane",
        lastName: "Cooper",
        displayName: nil,
        email: "jane.cooper@example.com",
        phoneNumber: nil,
        zipCode: "10001",
        city: "New York",
        state: "NY",
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: Date(),
        totalBillsUploaded: 0,
        badges: [.earlyUser],
        avatarURL: nil
    )

    static let previewPowerUser = UserProfile(
        id: UUID(),
        firstName: "Devon",
        lastName: "Lane",
        displayName: "Dev",
        email: "devon.lane@example.com",
        phoneNumber: "+1 (555) 987-6543",
        zipCode: "90210",
        city: "Los Angeles",
        state: "CA",
        isEmailVerified: true,
        isPhoneVerified: true,
        createdAt: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
        totalBillsUploaded: 45,
        badges: [.pioneer, .powerUser, .savingsExpert],
        avatarURL: nil
    )
}
