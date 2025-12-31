//
//  ExploreViewModel.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import Foundation
import SwiftUI
import MapKit

/// View mode for the Explore tab
enum ExploreViewMode: String, CaseIterable {
    case feed = "Feed"
    case map = "Map"

    var icon: String {
        switch self {
        case .feed: return "list.bullet"
        case .map: return "map"
        }
    }
}

/// Section within the Explore tab
enum ExploreSection: String, CaseIterable {
    case simulator = "Simulator"
    case marketplace = "Marketplace"
    case gougeIndex = "Gouge Index"

    var icon: String {
        switch self {
        case .simulator: return "chart.line.downtrend.xyaxis"
        case .marketplace: return "tag.fill"
        case .gougeIndex: return "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
class ExploreViewModel: ObservableObject {
    // MARK: - View State

    @Published var viewMode: ExploreViewMode = .feed
    @Published var selectedSection: ExploreSection = .simulator
    @Published var isLoading: Bool = false

    // MARK: - Recession Simulator State

    @Published var selectedScenario: EconomicScenario = .inflationHigh
    @Published var customInflationRate: Double = 5.0
    @Published var stressTestResult: StressTestResult?
    @Published var showScenarioInfo: Bool = false

    // User's current bills (mock data - would come from profile)
    var userBills: [BillCategoryType: Double] = [
        .energy: 120,
        .rent: 1800,
        .internet: 80,
        .mobile: 85,
        .insurance: 150,
        .streaming: 45
    ]

    // MARK: - Bill Heatmap State

    @Published var heatmapCategory: BillCategoryType = .internet
    @Published var heatmapZones: [HeatmapZone] = []
    @Published var selectedZone: HeatmapZone?
    @Published var nearbyDeals: [HeatmapDeal] = []
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7359, longitude: -74.0294), // Hoboken
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // MARK: - Make Me Move State

    @Published var strikePriceOrders: [StrikePriceOrder] = []
    @Published var strikePriceMatches: [StrikePriceMatch] = []
    @Published var showCreateStrikePrice: Bool = false
    @Published var editingStrikePrice: StrikePriceOrder?

    // MARK: - Gouge Index State

    @Published var gougeIndexCategory: BillCategoryType? = nil // nil = all
    @Published var gougeIndexRegion: String = "My ZIP"
    @Published var providerRankings: [ProviderRanking] = []
    @Published var gougeHighlights: [GougeHighlight] = []
    @Published var selectedProvider: ProviderRanking?

    // MARK: - Outage Bot State

    @Published var outageConnections: [OutageConnection] = []
    @Published var recentClaims: [OutageClaim] = []
    @Published var totalClaimedAmount: Double = 0
    @Published var showOutageBotSetup: Bool = false

    // MARK: - Initialization

    init() {
        // Defer loading to avoid publishing during view updates
        Task { @MainActor in
            await loadMockData()
        }
    }

    // MARK: - Data Loading

    func loadMockData() async {
        isLoading = true

        try? await Task.sleep(nanoseconds: 300_000_000)

        loadHeatmapData()
        loadStrikePriceData()
        loadGougeIndexData()
        loadOutageBotData()
        runStressTest()
        isLoading = false
    }

    // MARK: - Recession Simulator

    func runStressTest() {
        let scenario = selectedScenario
        var categoryImpacts: [CategoryImpact] = []
        var totalMonthlyImpact: Double = 0

        let impacts = scenario == .custom
            ? BillCategoryType.allCases.reduce(into: [:]) { dict, cat in
                dict[cat] = customInflationRate / 100.0 * cat.volatility
            }
            : scenario.categoryImpacts

        for category in BillCategoryType.allCases {
            let currentAmount = userBills[category] ?? 0
            let impactRate = impacts[category] ?? 0
            let impactAmount = currentAmount * impactRate

            categoryImpacts.append(CategoryImpact(
                category: category,
                currentAmount: currentAmount,
                projectedAmount: currentAmount + impactAmount,
                impactAmount: impactAmount,
                impactPercent: impactRate * 100
            ))

            totalMonthlyImpact += impactAmount
        }

        // Sort by impact amount
        categoryImpacts.sort { $0.impactAmount > $1.impactAmount }

        // Generate recommendations
        var recommendations: [StressTestRecommendation] = []

        // Energy recommendation if significant impact
        if let energyImpact = categoryImpacts.first(where: { $0.category == .energy }),
           energyImpact.impactAmount > 10 {
            recommendations.append(StressTestRecommendation(
                title: "Lock in a fixed-rate energy plan",
                description: "We see 3 fixed plans under $0.13/kWh in your ZIP.",
                actionType: .lockRate,
                urgency: energyImpact.impactAmount > 30 ? .high : .medium,
                potentialSavings: energyImpact.impactAmount * 0.6
            ))
        }

        // Internet recommendation
        if let internetImpact = categoryImpacts.first(where: { $0.category == .internet }),
           internetImpact.currentAmount > 60 {
            recommendations.append(StressTestRecommendation(
                title: "Set a 'Make Me Move' trigger on internet",
                description: "If someone gets Fiber for $50 or less, we'll alert you instantly.",
                actionType: .setStrikePrice,
                urgency: .medium,
                potentialSavings: internetImpact.currentAmount * 0.3
            ))
        }

        // Cluster recommendation for rent
        if let rentImpact = categoryImpacts.first(where: { $0.category == .rent }),
           rentImpact.impactAmount > 50 {
            recommendations.append(StressTestRecommendation(
                title: "Join a renter's cluster",
                description: "12 neighbors are negotiating together for renewal discounts.",
                actionType: .joinCluster,
                urgency: .low,
                potentialSavings: rentImpact.impactAmount * 0.4
            ))
        }

        stressTestResult = StressTestResult(
            scenario: scenario,
            totalImpactMonthly: totalMonthlyImpact,
            totalImpactYearly: totalMonthlyImpact * 12,
            categoryBreakdown: categoryImpacts,
            recommendations: recommendations
        )
    }

    func selectScenario(_ scenario: EconomicScenario) {
        selectedScenario = scenario
        if scenario != .custom {
            runStressTest()
        }
    }

    func updateCustomInflation(_ rate: Double) {
        customInflationRate = rate
        if selectedScenario == .custom {
            runStressTest()
        }
    }

    // MARK: - Bill Heatmap

    private func loadHeatmapData() {
        // Mock heatmap zones around Hoboken/Jersey City
        heatmapZones = [
            HeatmapZone(zipCode: "07030", latitude: 40.7440, longitude: -74.0324, category: .internet,
                       averagePrice: 95, marketAverage: 65, tier: .gouging, residentCount: 1200, nearbyDealsCount: 8),
            HeatmapZone(zipCode: "07302", latitude: 40.7178, longitude: -74.0431, category: .internet,
                       averagePrice: 72, marketAverage: 65, tier: .high, residentCount: 980, nearbyDealsCount: 5),
            HeatmapZone(zipCode: "07304", latitude: 40.7282, longitude: -74.0776, category: .internet,
                       averagePrice: 58, marketAverage: 65, tier: .low, residentCount: 750, nearbyDealsCount: 12),
            HeatmapZone(zipCode: "07305", latitude: 40.7012, longitude: -74.0876, category: .internet,
                       averagePrice: 65, marketAverage: 65, tier: .normal, residentCount: 620, nearbyDealsCount: 6),
            HeatmapZone(zipCode: "07306", latitude: 40.7350, longitude: -74.0650, category: .internet,
                       averagePrice: 45, marketAverage: 65, tier: .low, residentCount: 540, nearbyDealsCount: 15),
        ]
    }

    func selectZone(_ zone: HeatmapZone) {
        selectedZone = zone
        loadNearbyDeals(for: zone)
    }

    func loadNearbyDeals(for zone: HeatmapZone) {
        // Mock nearby deals
        nearbyDeals = [
            HeatmapDeal(providerName: "T-Mobile 5G Home", price: 49.99, grade: "S-Tier", distance: 0.3, zipCode: "07304", blueprintId: UUID()),
            HeatmapDeal(providerName: "Verizon Fios 300", price: 59.99, grade: "A+", distance: 0.5, zipCode: "07306", blueprintId: UUID()),
            HeatmapDeal(providerName: "Optimum Fiber", price: 55.00, grade: "A", distance: 0.7, zipCode: "07305", blueprintId: nil),
        ]
    }

    func changeHeatmapCategory(_ category: BillCategoryType) {
        heatmapCategory = category
        loadHeatmapData()
    }

    // MARK: - Make Me Move

    private func loadStrikePriceData() {
        strikePriceOrders = [
            StrikePriceOrder(
                category: "Internet",
                providerName: "Comcast",
                currentPrice: 80,
                strikePrice: 50,
                constraints: [
                    StrikePriceConstraint(type: .minSpeed, value: "500 Mbps"),
                    StrikePriceConstraint(type: .noDataCap, value: "true")
                ],
                matchCount: 2
            ),
            StrikePriceOrder(
                category: "Energy",
                providerName: nil,
                currentPrice: 120,
                strikePrice: 90,
                constraints: [],
                matchCount: 0
            )
        ]

        strikePriceMatches = [
            StrikePriceMatch(
                orderId: strikePriceOrders[0].id,
                dealTitle: "Fiber 1 Gig – Retention Offer",
                providerName: "Verizon Fios",
                price: 49.99,
                matchScore: 92,
                listingId: UUID(),
                matchedDate: Date().addingTimeInterval(-3600 * 2)
            )
        ]
    }

    func createStrikePriceOrder(_ order: StrikePriceOrder) {
        strikePriceOrders.append(order)
    }

    func updateStrikePriceOrder(_ order: StrikePriceOrder) {
        if let index = strikePriceOrders.firstIndex(where: { $0.id == order.id }) {
            strikePriceOrders[index] = order
        }
    }

    func deleteStrikePriceOrder(_ order: StrikePriceOrder) {
        strikePriceOrders.removeAll { $0.id == order.id }
    }

    func toggleStrikePriceActive(_ order: StrikePriceOrder) {
        if let index = strikePriceOrders.firstIndex(where: { $0.id == order.id }) {
            strikePriceOrders[index].isActive.toggle()
        }
    }

    // MARK: - Gouge Index

    private func loadGougeIndexData() {
        // This month's highlights
        gougeHighlights = [
            GougeHighlight(
                title: "Most Hated",
                subtitle: "40% above fair price",
                providerName: "Comcast",
                providerLogo: "wifi",
                metric: "+40%",
                highlightType: .mostHated
            ),
            GougeHighlight(
                title: "Biggest Surge",
                subtitle: "+15% this month",
                providerName: "PSEG",
                providerLogo: "bolt.fill",
                metric: "+15%",
                highlightType: .biggestSurge
            ),
            GougeHighlight(
                title: "Best Surprise",
                subtitle: "25% below market",
                providerName: "T-Mobile",
                providerLogo: "antenna.radiowaves.left.and.right",
                metric: "-25%",
                highlightType: .bestSurprise
            )
        ]

        // Full rankings
        providerRankings = [
            ProviderRanking(rank: 1, providerName: "Comcast", providerLogo: "wifi", category: .internet,
                           region: "07030", overchargePercent: 40, recentPriceChange: 8,
                           complaintsCount: 234, rating: .mostHated, typicalBillRange: 75...120),
            ProviderRanking(rank: 2, providerName: "Optimum", providerLogo: "wifi", category: .internet,
                           region: "07030", overchargePercent: 28, recentPriceChange: 5,
                           complaintsCount: 156, rating: .overpriced, typicalBillRange: 60...95),
            ProviderRanking(rank: 3, providerName: "PSEG", providerLogo: "bolt.fill", category: .energy,
                           region: "07030", overchargePercent: 15, recentPriceChange: 15,
                           complaintsCount: 89, rating: .overpriced, typicalBillRange: 100...180),
            ProviderRanking(rank: 4, providerName: "Verizon Fios", providerLogo: "wifi", category: .internet,
                           region: "07030", overchargePercent: 5, recentPriceChange: 2,
                           complaintsCount: 45, rating: .average, typicalBillRange: 50...80),
            ProviderRanking(rank: 5, providerName: "T-Mobile", providerLogo: "antenna.radiowaves.left.and.right", category: .mobile,
                           region: "07030", overchargePercent: -15, recentPriceChange: -5,
                           complaintsCount: 12, rating: .goodValue, typicalBillRange: 25...55),
            ProviderRanking(rank: 6, providerName: "Mint Mobile", providerLogo: "iphone", category: .mobile,
                           region: "07030", overchargePercent: -25, recentPriceChange: 0,
                           complaintsCount: 8, rating: .bestValue, typicalBillRange: 15...30),
        ]
    }

    func filterGougeIndex(category: BillCategoryType?, region: String) {
        gougeIndexCategory = category
        gougeIndexRegion = region
        // In real app, would re-fetch data with filters
    }

    // MARK: - Outage Bot

    private func loadOutageBotData() {
        outageConnections = [
            OutageConnection(
                providerName: "Comcast",
                providerLogo: "wifi",
                category: .internet,
                zipCode: "07030",
                isMonitoring: true,
                lastOutageDate: Date().addingTimeInterval(-86400 * 5),
                lastClaimAmount: 5.40,
                totalClaimed: 32.15,
                claimsCount: 4
            ),
            OutageConnection(
                providerName: "PSEG",
                providerLogo: "bolt.fill",
                category: .power,
                zipCode: "07030",
                isMonitoring: true,
                lastOutageDate: nil,
                lastClaimAmount: nil,
                totalClaimed: 0,
                claimsCount: 0
            )
        ]

        recentClaims = [
            OutageClaim(
                providerName: "Comcast",
                outageDate: Date().addingTimeInterval(-86400 * 5),
                durationHours: 4,
                claimAmount: 5.40,
                status: .approved,
                submittedDate: Date().addingTimeInterval(-86400 * 4),
                resolvedDate: Date().addingTimeInterval(-86400 * 2)
            ),
            OutageClaim(
                providerName: "Comcast",
                outageDate: Date().addingTimeInterval(-86400 * 30),
                durationHours: 8,
                claimAmount: 12.00,
                status: .approved,
                submittedDate: Date().addingTimeInterval(-86400 * 29),
                resolvedDate: Date().addingTimeInterval(-86400 * 25)
            )
        ]

        totalClaimedAmount = outageConnections.reduce(0) { $0 + $1.totalClaimed }
    }

    func toggleOutageMonitoring(for connection: OutageConnection) {
        if let index = outageConnections.firstIndex(where: { $0.id == connection.id }) {
            outageConnections[index].isMonitoring.toggle()
        }
    }

    func addOutageConnection(_ connection: OutageConnection) {
        outageConnections.append(connection)
    }
}
