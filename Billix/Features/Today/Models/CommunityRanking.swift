import Foundation

struct CommunityRanking: Codable {
    let percentile: Int // Top X%
    let billixScore: Int // 0-100 or 300-900
    let trustScore: Int // From user_vault
    let avgSavings: Int // Monthly average
    let billsTracked: Int
    let rank: Int? // Actual rank number (optional)
    let totalUsers: Int?

    init(
        percentile: Int,
        billixScore: Int,
        trustScore: Int,
        avgSavings: Int,
        billsTracked: Int,
        rank: Int? = nil,
        totalUsers: Int? = nil
    ) {
        self.percentile = percentile
        self.billixScore = billixScore
        self.trustScore = trustScore
        self.avgSavings = avgSavings
        self.billsTracked = billsTracked
        self.rank = rank
        self.totalUsers = totalUsers
    }

    var rankingText: String {
        if let rank = rank, let totalUsers = totalUsers {
            return "#\(rank) of \(totalUsers.formatted())"
        }
        return "TOP \(percentile)%"
    }
}

// MARK: - Mock Data

extension CommunityRanking {
    static let mockRanking = CommunityRanking(
        percentile: 12,
        billixScore: 74,
        trustScore: 742,
        avgSavings: 127,
        billsTracked: 16,
        rank: 142,
        totalUsers: 1200
    )

    static let topPerformer = CommunityRanking(
        percentile: 5,
        billixScore: 92,
        trustScore: 850,
        avgSavings: 245,
        billsTracked: 34,
        rank: 12,
        totalUsers: 1200
    )

    static let newUser = CommunityRanking(
        percentile: 78,
        billixScore: 42,
        trustScore: 520,
        avgSavings: 45,
        billsTracked: 3,
        rank: 935,
        totalUsers: 1200
    )
}
