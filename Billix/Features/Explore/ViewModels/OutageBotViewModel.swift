//
//  OutageBotViewModel.swift
//  Billix
//
//  ViewModel for Outage Bot feature
//

import Foundation
import SwiftUI

@MainActor
class OutageBotViewModel: ObservableObject {
    // MARK: - Published Properties

    // Data
    @Published var connections: [OutageConnection] = []
    @Published var claims: [OutageClaim] = []
    @Published var detectedOutages: [DetectedOutage] = []

    // Current state
    @Published var currentDetectedOutage: DetectedOutage?
    @Published var selectedConnection: OutageConnection?
    @Published var selectedClaim: OutageClaim?

    // Sheet visibility
    @Published var showAddProvider: Bool = false
    @Published var showReportOutage: Bool = false
    @Published var showOutageConfirmation: Bool = false
    @Published var showEligibilityResult: Bool = false
    @Published var showGuidedClaim: Bool = false
    @Published var showClaimHistory: Bool = false

    // Add Provider form state
    @Published var selectedCategory: OutageBillType = .internet
    @Published var selectedProvider: ProviderOption?
    @Published var enteredZipCode: String = ""

    // Report Outage form state
    @Published var reportStartTime: Date = Date()
    @Published var reportEndTime: Date = Date()
    @Published var isOutageOngoing: Bool = false

    // Loading state
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Computed Properties

    var hasActiveOutages: Bool {
        !detectedOutages.isEmpty
    }

    var hasConnections: Bool {
        !connections.isEmpty
    }

    var recentClaims: [OutageClaim] {
        Array(claims.prefix(5))
    }

    var totalRecovered: Double {
        claims.filter { $0.status == .approved }.reduce(0) { $0 + $1.claimAmount }
    }

    var formattedTotalRecovered: String {
        if totalRecovered >= 1000 {
            return String(format: "$%.1fK", totalRecovered / 1000)
        } else {
            return String(format: "$%.2f", totalRecovered)
        }
    }

    var approvedClaimsCount: Int {
        claims.filter { $0.status == .approved }.count
    }

    var pendingClaimsCount: Int {
        claims.filter { $0.status == .pending || $0.status == .submitted }.count
    }

    var pendingAmount: Double {
        claims.filter { $0.status == .pending || $0.status == .submitted }.reduce(0) { $0 + $1.claimAmount }
    }

    var formattedPendingAmount: String {
        String(format: "$%.2f", pendingAmount)
    }

    var totalClaimsCount: Int {
        claims.count
    }

    // MARK: - Initialization

    init() {
        // Initialize with empty data
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Load mock data
        await MainActor.run {
            self.connections = Self.mockConnections
            self.claims = Self.mockClaims
            self.detectedOutages = []
        }
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Outage Detection

    func checkForOutages() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate checking
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Simulate finding an outage
        if let connection = connections.first(where: { $0.isMonitoring }) {
            let event = OutageEvent(
                providerName: connection.providerName,
                zipCode: connection.zipCode,
                startTime: Date().addingTimeInterval(-3600),
                endTime: nil,
                durationHours: 1.0,
                affectedUsers: 127,
                status: .active
            )
            let detected = DetectedOutage(
                connection: connection,
                event: event,
                crowdReports: 42,
                crowdConfidence: 0.85
            )
            await MainActor.run {
                self.detectedOutages = [detected]
            }
        }
    }

    func toggleMonitoring(for connection: OutageConnection) async {
        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index].isMonitoring.toggle()
        }
    }

    // MARK: - Outage Actions

    func startReportOutage(for connection: OutageConnection) {
        selectedConnection = connection
        reportStartTime = Date()
        reportEndTime = Date()
        isOutageOngoing = false
        showReportOutage = true
    }

    func submitOutageReport() async {
        guard selectedConnection != nil else { return }

        isLoading = true
        defer { isLoading = false }

        // Simulate submission
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
            self.showReportOutage = false
            self.showEligibilityResult = true
        }
    }

    func confirmOutage(_ outage: DetectedOutage) async {
        // Process confirmed outage
        currentDetectedOutage = outage
        showEligibilityResult = true

        // Remove from detected list
        detectedOutages.removeAll { $0.id == outage.id }
    }

    func dismissOutage(_ outage: DetectedOutage) {
        detectedOutages.removeAll { $0.id == outage.id }
    }

    // MARK: - Provider Management

    func addConnection() async {
        guard let provider = selectedProvider else { return }

        isLoading = true
        defer { isLoading = false }

        // Simulate adding
        try? await Task.sleep(nanoseconds: 500_000_000)

        let newConnection = OutageConnection(
            providerName: provider.name,
            providerLogo: provider.logo,
            category: selectedCategory,
            zipCode: enteredZipCode,
            isMonitoring: true
        )

        await MainActor.run {
            self.connections.append(newConnection)
            self.showAddProvider = false
            self.selectedProvider = nil
            self.enteredZipCode = ""
        }
    }

    // MARK: - Claim Management

    func selectClaim(_ claim: OutageClaim) {
        selectedClaim = claim
        // Could show claim detail sheet
    }

    // MARK: - Mock Data

    private static var mockConnections: [OutageConnection] {
        [
            OutageConnection(
                providerName: "Xfinity",
                providerLogo: "wifi",
                category: .internet,
                zipCode: "07030",
                isMonitoring: true,
                totalClaimed: 47.50,
                claimsCount: 2
            ),
            OutageConnection(
                providerName: "PSE&G",
                providerLogo: "bolt.fill",
                category: .power,
                zipCode: "07030",
                isMonitoring: true,
                totalClaimed: 25.00,
                claimsCount: 1
            )
        ]
    }

    private static var mockClaims: [OutageClaim] {
        [
            OutageClaim(
                providerName: "Xfinity",
                outageDate: Date().addingTimeInterval(-86400 * 7),
                durationHours: 4.5,
                claimAmount: 15.00,
                status: .approved
            ),
            OutageClaim(
                providerName: "PSE&G",
                outageDate: Date().addingTimeInterval(-86400 * 14),
                durationHours: 2.0,
                claimAmount: 25.00,
                status: .approved
            ),
            OutageClaim(
                providerName: "Xfinity",
                outageDate: Date().addingTimeInterval(-86400 * 2),
                durationHours: 1.5,
                claimAmount: 12.50,
                status: .pending
            )
        ]
    }
}
