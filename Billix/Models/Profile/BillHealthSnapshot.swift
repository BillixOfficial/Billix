import Foundation

// MARK: - Bill Health Snapshot Model

struct BillHealthSnapshot: Codable, Equatable {
    var overallGrade: String // "A", "B", "C", "D", "F"
    var overallScore: Int // 0-100
    var monthlyBillsTotal: Double
    var estimatedSavings: Double

    // Category coverage
    var categoriesCovered: [BillCategory]

    var monthlyBillsString: String {
        String(format: "$%.0f", monthlyBillsTotal)
    }

    var estimatedSavingsString: String {
        String(format: "$%.0f/mo", estimatedSavings)
    }

    var gradeColor: String {
        switch overallGrade {
        case "A": return "green"
        case "B": return "blue"
        case "C": return "yellow"
        case "D": return "orange"
        case "F": return "red"
        default: return "gray"
        }
    }
}

// MARK: - Bill Category

struct BillCategory: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    var isCovered: Bool

    static let utilities = BillCategory(
        id: UUID(),
        name: "Utilities",
        icon: "bolt.fill",
        isCovered: true
    )

    static let internetMobile = BillCategory(
        id: UUID(),
        name: "Internet & Mobile",
        icon: "wifi",
        isCovered: true
    )

    static let streaming = BillCategory(
        id: UUID(),
        name: "Streaming & Subscriptions",
        icon: "play.tv.fill",
        isCovered: false
    )

    static let housing = BillCategory(
        id: UUID(),
        name: "Rent / Mortgage",
        icon: "house.fill",
        isCovered: false
    )

    static let all: [BillCategory] = [
        .utilities,
        .internetMobile,
        .streaming,
        .housing
    ]
}

// MARK: - Preview Data

extension BillHealthSnapshot {
    static let preview = BillHealthSnapshot(
        overallGrade: "B",
        overallScore: 82,
        monthlyBillsTotal: 487.50,
        estimatedSavings: 65.00,
        categoriesCovered: [
            .utilities,
            .internetMobile
        ]
    )

    static let previewExcellent = BillHealthSnapshot(
        overallGrade: "A",
        overallScore: 95,
        monthlyBillsTotal: 320.00,
        estimatedSavings: 15.00,
        categoriesCovered: BillCategory.all
    )

    static let previewPoor = BillHealthSnapshot(
        overallGrade: "D",
        overallScore: 58,
        monthlyBillsTotal: 780.00,
        estimatedSavings: 150.00,
        categoriesCovered: [.utilities]
    )
}
