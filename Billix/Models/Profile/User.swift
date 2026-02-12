import Foundation

// MARK: - User Vault (Secure Private Data)
/// Matches the `user_vault` table in Supabase
/// Contains sensitive user settings and subscription info

struct UserVault: Identifiable, Codable, Equatable {
    let id: UUID
    var zipCode: String
    var state: String?
    var marketplaceOptOut: Bool
    var preferences: [String: String]?
    var lastLoginAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var trustScore: Int
    var isTrustedHelper: Bool
    var trustFlags: [String]?
    var stripeCustomerId: String?
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, state, preferences
        case zipCode = "zip_code"
        case marketplaceOptOut = "marketplace_opt_out"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case trustScore = "trust_score"
        case isTrustedHelper = "is_trusted_helper"
        case trustFlags = "trust_flags"
        case stripeCustomerId = "stripe_customer_id"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
    }

    // Computed properties
    var zipBand: String {
        String(zipCode.prefix(3)) + "**"
    }
}

// MARK: - User Profile (Public App Data)
/// Now reads from consolidated `profiles` table in Supabase
/// Contains public-facing profile and gamification data

struct UserProfileDB: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var points: Int
    var badgeLevel: BadgeLevel
    var badges: [String]
    var goal: String?
    var goalProgress: [String: String]?
    var goalDeadline: Date?
    var helpfulCount: Int
    var contributionCount: Int
    var billsAnalyzedCount: Int
    var profileVisibility: ProfileVisibility
    var showOnLeaderboard: Bool
    var showBadges: Bool
    var showGoal: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "user_id"  // profiles table uses user_id as primary key
        case bio, points, badges, goal
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case badgeLevel = "badge_level"
        case goalProgress = "goal_progress"
        case goalDeadline = "goal_deadline"
        case helpfulCount = "helpful_count"
        case contributionCount = "contribution_count"
        case billsAnalyzedCount = "bills_analyzed_count"
        case profileVisibility = "profile_visibility"
        case showOnLeaderboard = "show_on_leaderboard"
        case showBadges = "show_badges"
        case showGoal = "show_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var initials: String {
        guard let name = displayName, !name.isEmpty else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Billix Profile (New profiles table)
/// Matches the `profiles` table in Supabase

struct BillixProfile: Codable, Equatable {
    let userId: UUID
    var handle: String
    var displayName: String?
    var zipCode: String
    var city: String?
    var state: String?
    var bio: String?
    var gender: String?
    var birthday: String?
    var trustScore: Int
    var isTrustedHelper: Bool
    var billsAnalyzedCount: Int
    var badgeLevel: String
    var subscriptionTier: String
    var profileVisibility: String
    var createdAt: Date
    var updatedAt: Date

    // Home setup fields
    var homeSetupCompleted: Bool?
    var billTypes: [String]?
    var monthlyBudget: String?
    var mainGoal: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case displayName = "display_name"
        case zipCode = "zip_code"
        case city, state, bio, gender, birthday
        case trustScore = "trust_score"
        case isTrustedHelper = "is_trusted_helper"
        case billsAnalyzedCount = "bills_analyzed_count"
        case badgeLevel = "badge_level"
        case subscriptionTier = "subscription_tier"
        case profileVisibility = "profile_visibility"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case homeSetupCompleted = "home_setup_completed"
        case billTypes = "bill_types"
        case monthlyBudget = "monthly_budget"
        case mainGoal = "main_goal"
    }

    var formattedLocation: String {
        if let city = city, let state = state {
            return "\(zipCode) (\(city), \(state))"
        }
        return zipCode
    }

    var initials: String {
        guard let name = displayName, !name.isEmpty else {
            return String(handle.prefix(2)).uppercased()
        }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Combined User (Convenience Wrapper)
/// Combines vault and profile data for app-level use

struct CombinedUser: Identifiable, Equatable {
    let id: UUID
    var vault: UserVault
    var profile: UserProfileDB
    var billixProfile: BillixProfile?

    var handle: String {
        billixProfile?.handle ?? "user"
    }

    var displayName: String {
        billixProfile?.displayName ?? profile.displayName ?? "User"
    }

    var fullDisplayName: String {
        displayName
    }

    var zipCode: String {
        billixProfile?.zipCode ?? vault.zipCode
    }

    var formattedLocation: String {
        billixProfile?.formattedLocation ?? vault.zipCode
    }

    var bio: String? {
        billixProfile?.bio ?? profile.bio
    }

    var isNewUser: Bool {
        profile.displayName == nil && billixProfile?.displayName == nil
    }

    var requesterPoints: Int {
        0 // TODO: Connect to BillConnection reputation system
    }

    var supporterPoints: Int {
        0 // TODO: Connect to BillConnection reputation system
    }

    var needsHomeSetup: Bool {
        // Show home setup questions if not completed yet
        billixProfile?.homeSetupCompleted != true
    }

    var initials: String {
        billixProfile?.initials ?? profile.initials
    }

    var memberSinceString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Member since: \(formatter.string(from: vault.createdAt))"
    }
}

// MARK: - Enums

enum SubscriptionTier: String, Codable, Equatable {
    case free
    case premium
    case enterprise
}

enum BadgeLevel: String, Codable, Equatable {
    case newbie  // profiles table default
    case bronze
    case silver
    case gold
    case platinum
    case diamond
}

enum ProfileVisibility: String, Codable, Equatable {
    case `public`
    case friends
    case `private`
}

// MARK: - Insert Models (for creating new records)

struct UserVaultInsert: Codable {
    let id: UUID
    let zipCode: String
    var state: String?
    var marketplaceOptOut: Bool = false
    var preferences: [String: String]? = nil

    enum CodingKeys: String, CodingKey {
        case id, state, preferences
        case zipCode = "zip_code"
        case marketplaceOptOut = "marketplace_opt_out"
    }
}

struct UserProfileInsert: Codable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var goal: String?

    enum CodingKeys: String, CodingKey {
        case id, goal
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Legacy User Profile (Backward Compatibility)
/// Keep for existing code compatibility during migration

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
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    var createdAt: Date
    var totalBillsUploaded: Int
    var badges: [UserBadge]
    var avatarURL: String?

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

// MARK: - User Badge (Legacy)

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

extension UserVault {
    static let preview = UserVault(
        id: UUID(),
        zipCode: "07054",
        state: "NJ",
        marketplaceOptOut: false,
        preferences: nil,
        lastLoginAt: Date(),
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        updatedAt: Date(),
        trustScore: 75,
        isTrustedHelper: true,
        trustFlags: nil,
        stripeCustomerId: nil,
        subscriptionTier: .free,
        subscriptionExpiresAt: nil
    )
}

extension UserProfileDB {
    static let preview = UserProfileDB(
        id: UUID(),
        displayName: "Ronald Richards",
        avatarUrl: nil,
        bio: "Helping my community save money on bills.",
        points: 1250,
        badgeLevel: .silver,
        badges: ["pioneer", "power_user"],
        goal: "Lower my monthly bills",
        goalProgress: nil,
        goalDeadline: nil,
        helpfulCount: 12,
        contributionCount: 16,
        billsAnalyzedCount: 16,
        profileVisibility: .public,
        showOnLeaderboard: true,
        showBadges: true,
        showGoal: true,
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        updatedAt: Date()
    )
}

extension BillixProfile {
    static let preview = BillixProfile(
        userId: UUID(),
        handle: "ronaldrichards",
        displayName: "Ronald Richards",
        zipCode: "07054",
        city: "Newark",
        state: "NJ",
        bio: "Helping my community save money on bills.",
        gender: "male",
        birthday: "1990-06-15",
        trustScore: 75,
        isTrustedHelper: true,
        billsAnalyzedCount: 16,
        badgeLevel: "silver",
        subscriptionTier: "free",
        profileVisibility: "public",
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        updatedAt: Date()
    )
}

extension CombinedUser {
    static let preview = CombinedUser(
        id: UUID(),
        vault: .preview,
        profile: .preview,
        billixProfile: .preview
    )
}

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
