import Foundation

struct LearnArticle: Identifiable, Codable {
    let id: UUID
    let title: String
    let icon: String // Emoji
    let category: String
    let difficulty: Difficulty
    let readTime: Int // minutes
    let content: String
    let imageURL: String?

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        category: String,
        difficulty: Difficulty = .beginner,
        readTime: Int,
        content: String,
        imageURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.category = category
        self.difficulty = difficulty
        self.readTime = readTime
        self.content = content
        self.imageURL = imageURL
    }

    enum Difficulty: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
}

// MARK: - Mock Data

extension LearnArticle {
    static let mockArticles: [LearnArticle] = [
        LearnArticle(
            title: "How to Negotiate Your Bills",
            icon: "💬",
            category: "Tips",
            difficulty: .beginner,
            readTime: 5,
            content: """
            Negotiating your bills can save hundreds per year. Here's how:

            1. Research competitor rates
            2. Call during off-peak hours
            3. Be polite but firm
            4. Mention you're considering switching
            5. Ask for loyalty discounts

            Most providers have retention departments specifically trained to keep customers. Use this to your advantage.
            """
        ),
        LearnArticle(
            title: "Understanding Your Bill",
            icon: "📄",
            category: "Basics",
            difficulty: .beginner,
            readTime: 4,
            content: """
            Bills can be confusing. Here's what to look for:

            - Base charges vs. usage charges
            - Taxes and regulatory fees
            - Promotional rates vs. regular rates
            - Hidden fees to watch for

            Knowing these basics helps you spot overcharges and negotiate better.
            """
        ),
        LearnArticle(
            title: "When to Switch Providers",
            icon: "🔄",
            category: "Advanced",
            difficulty: .intermediate,
            readTime: 6,
            content: """
            Timing is everything when switching providers:

            - Watch for promotional periods
            - Check contract end dates
            - Compare total costs, not just monthly rates
            - Factor in installation fees
            - Consider service reliability ratings

            Billix tracks market trends to alert you to optimal switching times.
            """
        ),
        LearnArticle(
            title: "Build Better Bill Habits",
            icon: "🎯",
            category: "Tips",
            difficulty: .beginner,
            readTime: 3,
            content: """
            Small habits lead to big savings:

            - Set up autopay for on-time discounts
            - Review bills monthly for errors
            - Track usage to avoid overages
            - Bundle services when beneficial
            - Set price alerts

            Consistency is key to long-term savings.
            """
        )
    ]
}
