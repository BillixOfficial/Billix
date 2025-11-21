import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var userName: String = "User"
    @Published var monthlyDifference: Double = 0
    @Published var billHealthScore: BillHealthScore?
    @Published var savingsOpportunities: [SavingsOpportunity] = []
    @Published var alerts: [HomeAlert] = []
    @Published var recentActivities: [RecentActivity] = []
    @Published var isLoading: Bool = false
    @Published var hasData: Bool = false

    // TruePrice™ Index
    @Published var truePriceIndex: Double = 98.34
    @Published var truePriceChange: Double = -1.2
    @Published var truePriceLastUpdated: String = "2 hours ago"

    // Community Notes
    @Published var totalUsers: Int = 47_823
    @Published var totalSavings: Double = 1_234_567
    @Published var avgSavings: Double = 127
    @Published var monthOverMonth: Double = 23.4

    // Savings Meter
    @Published var monthlyTarget: Double = 200
    @Published var currentSavings: Double = 160

    init() {
        loadData()
    }

    func loadData() {
        // Simulate loading data
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            self.userName = "Sarah"
            self.monthlyDifference = 125.50

            self.billHealthScore = BillHealthScore(
                score: 72,
                interpretation: "Moderate leak risk detected",
                trend: .stable
            )

            self.savingsOpportunities = [
                SavingsOpportunity(
                    billName: "Internet Service",
                    currentProvider: "Comcast",
                    recommendedProvider: "AT&T Fiber",
                    currentPrice: 89.99,
                    truePriceAverage: 65.00,
                    potentialSavings: 25.00,
                    category: .internet
                ),
                SavingsOpportunity(
                    billName: "Mobile Phone",
                    currentProvider: "Verizon",
                    recommendedProvider: "Mint Mobile",
                    currentPrice: 65.00,
                    truePriceAverage: 40.00,
                    potentialSavings: 30.00,
                    category: .phone
                ),
                SavingsOpportunity(
                    billName: "Electric Bill",
                    currentProvider: "PG&E",
                    recommendedProvider: "Solar Plan",
                    currentPrice: 120.00,
                    truePriceAverage: 95.00,
                    potentialSavings: 15.00,
                    category: .electricity
                )
            ]

            self.alerts = [
                HomeAlert(
                    type: .billDue,
                    message: "Comcast bill payment is due",
                    priority: .high,
                    actionTitle: "Pay Now",
                    dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
                ),
                HomeAlert(
                    type: .savingsFound,
                    message: "We found $35/month savings on your phone bill",
                    priority: .medium,
                    actionTitle: "View Details"
                ),
                HomeAlert(
                    type: .promoExpiring,
                    message: "Your promotional rate ends in 15 days",
                    priority: .medium,
                    actionTitle: "Renew or Switch",
                    dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
                )
            ]

            self.recentActivities = [
                RecentActivity(
                    type: .uploaded,
                    billName: "Comcast Internet",
                    timestamp: Date().addingTimeInterval(-3600),
                    status: .completed
                ),
                RecentActivity(
                    type: .analyzed,
                    billName: "Verizon Wireless",
                    timestamp: Date().addingTimeInterval(-7200),
                    status: .completed
                ),
                RecentActivity(
                    type: .saved,
                    billName: "AT&T Mobile",
                    timestamp: Date().addingTimeInterval(-86400),
                    status: .completed,
                    amount: 35
                ),
                RecentActivity(
                    type: .compared,
                    billName: "Electric Bill",
                    timestamp: Date().addingTimeInterval(-172800),
                    status: .completed
                )
            ]

            self.hasData = true
            self.isLoading = false
        }
    }

    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadData()
    }

    func dismissAlert(_ alert: HomeAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
}
