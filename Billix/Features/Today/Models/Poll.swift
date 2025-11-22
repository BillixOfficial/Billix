import Foundation

struct Poll: Identifiable, Codable {
    let id: UUID
    let question: String
    var options: [PollOption]
    let totalVotes: Int
    let expiresAt: Date
    let category: String?

    init(
        id: UUID = UUID(),
        question: String,
        options: [PollOption],
        totalVotes: Int,
        expiresAt: Date,
        category: String? = nil
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.totalVotes = totalVotes
        self.expiresAt = expiresAt
        self.category = category
    }

    var timeRemaining: String {
        let interval = expiresAt.timeIntervalSinceNow

        if interval <= 0 {
            return "Ended"
        }

        let hours = Int(interval) / 3600
        if hours > 0 {
            return "\(hours)h"
        }

        let minutes = Int(interval) / 60
        return "\(minutes)m"
    }
}

struct PollOption: Identifiable, Codable {
    let id: UUID
    let text: String
    var voteCount: Int
    var percentage: Double

    init(
        id: UUID = UUID(),
        text: String,
        voteCount: Int,
        percentage: Double
    ) {
        self.id = id
        self.text = text
        self.voteCount = voteCount
        self.percentage = percentage
    }
}

// MARK: - Mock Data

extension Poll {
    static let mockPoll = Poll(
        question: "Best Internet Provider in 07101?",
        options: [
            PollOption(text: "Verizon Fios", voteCount: 581, percentage: 47.0),
            PollOption(text: "Comcast/Xfinity", voteCount: 395, percentage: 32.0),
            PollOption(text: "AT&T Fiber", voteCount: 258, percentage: 21.0)
        ],
        totalVotes: 1234,
        expiresAt: Date().addingTimeInterval(6 * 3600), // 6 hours from now
        category: "internet"
    )

    static let mockPolls: [Poll] = [
        mockPoll,
        Poll(
            question: "What's your biggest bill challenge?",
            options: [
                PollOption(text: "Tracking due dates", voteCount: 412, percentage: 35.0),
                PollOption(text: "Finding better rates", voteCount: 530, percentage: 45.0),
                PollOption(text: "Understanding charges", voteCount: 236, percentage: 20.0)
            ],
            totalVotes: 1178,
            expiresAt: Date().addingTimeInterval(12 * 3600),
            category: "general"
        )
    ]
}
