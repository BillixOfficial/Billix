import Foundation

/// Represents a user's bill/subscription
struct Bill: Identifiable, Codable {
    let id: UUID
    let providerName: String
    let category: String
    let categoryIcon: String
    let amount: Double
    let dueDate: Date
    let isPaid: Bool
    let isRecurring: Bool
    let frequency: BillingFrequency?

    init(
        id: UUID = UUID(),
        providerName: String,
        category: String,
        categoryIcon: String,
        amount: Double,
        dueDate: Date,
        isPaid: Bool = false,
        isRecurring: Bool = true,
        frequency: BillingFrequency? = .monthly
    ) {
        self.id = id
        self.providerName = providerName
        self.category = category
        self.categoryIcon = categoryIcon
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isRecurring = isRecurring
        self.frequency = frequency
    }

    var isOverdue: Bool {
        !isPaid && dueDate < Date()
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var isDueSoon: Bool {
        !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7
    }
}

enum BillingFrequency: String, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annual = "Annual"
}

// MARK: - Mock Data

extension Bill {
    static let mockElectric = Bill(
        providerName: "PSE&G",
        category: "Electric",
        categoryIcon: "bolt.fill",
        amount: 127.45,
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
        isPaid: false
    )

    static let mockInternet = Bill(
        providerName: "Verizon Fios",
        category: "Internet",
        categoryIcon: "wifi",
        amount: 89.99,
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
        isPaid: false
    )

    static let mockMobile = Bill(
        providerName: "T-Mobile",
        category: "Mobile",
        categoryIcon: "iphone",
        amount: 70.00,
        dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
        isPaid: false
    )

    static let mockGas = Bill(
        providerName: "NJ Natural Gas",
        category: "Gas",
        categoryIcon: "flame.fill",
        amount: 45.30,
        dueDate: Calendar.current.date(byAdding: .day, value: 18, to: Date())!,
        isPaid: true
    )

    static let mockWater = Bill(
        providerName: "Newark Water",
        category: "Water",
        categoryIcon: "drop.fill",
        amount: 32.15,
        dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        isPaid: false
    )

    static let mockStreaming = Bill(
        providerName: "Netflix",
        category: "Streaming",
        categoryIcon: "tv.fill",
        amount: 15.99,
        dueDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!,
        isPaid: false
    )

    static let mockInsurance = Bill(
        providerName: "State Farm",
        category: "Insurance",
        categoryIcon: "shield.fill",
        amount: 125.00,
        dueDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!,
        isPaid: false
    )

    static let mockBills: [Bill] = [
        mockElectric,
        mockInternet,
        mockMobile,
        mockGas,
        mockWater,
        mockStreaming,
        mockInsurance
    ]

    static var mockUpcomingBills: [Bill] {
        mockBills.filter { $0.isDueSoon }.sorted { $0.dueDate < $1.dueDate }
    }

    static var mockTotalMonthly: Double {
        mockBills.filter { $0.isRecurring && $0.frequency == .monthly }.reduce(0) { $0 + $1.amount }
    }

    static var mockOverdueBills: [Bill] {
        mockBills.filter { $0.isOverdue }.sorted { $0.dueDate < $1.dueDate }
    }
}
