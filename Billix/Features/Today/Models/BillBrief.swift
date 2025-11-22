import Foundation

struct BillBrief: Identifiable, Codable {
    let id: UUID
    let title: String
    let category: String
    let categoryIcon: String
    let imageURL: String?
    let readTime: Int // minutes
    let publishedDate: Date
    let content: String
    let excerpt: String?

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        categoryIcon: String,
        imageURL: String? = nil,
        readTime: Int,
        publishedDate: Date,
        content: String,
        excerpt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.categoryIcon = categoryIcon
        self.imageURL = imageURL
        self.readTime = readTime
        self.publishedDate = publishedDate
        self.content = content
        self.excerpt = excerpt
    }
}

// MARK: - Mock Data

extension BillBrief {
    static let mockBrief = BillBrief(
        title: "Why Internet Bills Are Rising in Your Area",
        category: "Internet",
        categoryIcon: "📡",
        imageURL: nil,
        readTime: 3,
        publishedDate: Date(),
        content: """
        Internet service providers across the Northeast have increased prices by an average of 8% this quarter. Industry analysts point to infrastructure upgrades and increased bandwidth demands as primary drivers.

        Here's what you can do:
        1. Review your current plan and usage
        2. Compare rates with competitors in your area
        3. Negotiate with your provider using market data

        Billix users who switched providers saved an average of $45/month.
        """,
        excerpt: "ISPs raise prices 8% this quarter. Learn how to save."
    )

    static let mockBriefs: [BillBrief] = [
        mockBrief,
        BillBrief(
            title: "Electric Rates Drop: Best Time to Switch",
            category: "Utilities",
            categoryIcon: "⚡️",
            readTime: 4,
            publishedDate: Date().addingTimeInterval(-86400),
            content: "Summer rate decreases present savings opportunities...",
            excerpt: "Electric rates down 3% - your chance to save."
        ),
        BillBrief(
            title: "5 Hidden Fees on Your Mobile Bill",
            category: "Mobile",
            categoryIcon: "📱",
            readTime: 5,
            publishedDate: Date().addingTimeInterval(-172800),
            content: "Carriers often bury extra charges in fine print...",
            excerpt: "Uncover hidden mobile charges costing you $20+/mo."
        )
    ]
}
