//
//  HouseholdViewModel.swift
//  Billix
//
//  Main ViewModel for the Household feature dashboard,
//  coordinating all household-related services.
//

import Foundation
import Combine

@MainActor
class HouseholdViewModel: ObservableObject {
    // Services
    private let householdService = HouseholdService.shared
    private let karmaService = KarmaService.shared
    private let nudgeService = NudgeService.shared
    private let fairnessService = FairnessService.shared
    private let autoPilotService = AutoPilotService.shared

    // State
    @Published var selectedTab: HouseholdTab = .feed
    @Published var isLoading = false
    @Published var error: String?
    @Published var showCreateHousehold = false
    @Published var showJoinHousehold = false
    @Published var showSettings = false
    @Published var showInvite = false

    // Computed properties from services
    var household: Household? { householdService.currentHousehold }
    var members: [HouseholdMemberModel] { householdService.members }
    var householdBills: [HouseholdBill] { householdService.householdBills }
    var leaderboard: [KarmaLeaderboardEntry] { karmaService.leaderboard }
    var monthlyHero: HouseholdHero? { karmaService.monthlyHero }
    var unreadNudges: Int { nudgeService.unreadCount }
    var pendingEscalations: [EscalationAlert] { autoPilotService.pendingEscalations }

    var hasHousehold: Bool { household != nil }

    var currentMember: HouseholdMemberModel? {
        householdService.getCurrentMembership()
    }

    var canManageHousehold: Bool {
        householdService.canEditSettings()
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Observe service errors
        householdService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load household and members
            try await householdService.fetchCurrentHousehold()

            if hasHousehold {
                // Load related data in parallel
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await self.karmaService.fetchLeaderboard() }
                    group.addTask { await self.karmaService.fetchRecentEvents() }
                    group.addTask { await self.nudgeService.fetchReceivedNudges() }
                    group.addTask { await self.autoPilotService.fetchAutoPilotBills() }
                    group.addTask {
                        try? await self.householdService.fetchHouseholdBills()
                    }
                }

                // Process any pending escalations
                try? await autoPilotService.processEscalations()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Household Actions

    func createHousehold(name: String, fairnessMode: FairnessMode) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await householdService.createHousehold(name: name, fairnessMode: fairnessMode)
            showCreateHousehold = false
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func joinHousehold(inviteCode: String, displayName: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await householdService.joinHousehold(inviteCode: inviteCode, displayName: displayName)
            showJoinHousehold = false
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func leaveHousehold() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await householdService.leaveHousehold()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Bill Actions

    func addBillToHousehold(swapBillId: UUID, visibility: BillVisibility, autoPilot: Bool) async {
        do {
            try await householdService.addBillToHousehold(
                swapBillId: swapBillId,
                visibility: visibility,
                autoPilotEnabled: autoPilot
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleAutoPilot(for bill: HouseholdBill) async {
        do {
            if bill.autoPilotEnabled {
                try await autoPilotService.disableAutoPilot(billId: bill.id)
            } else {
                try await autoPilotService.enableAutoPilot(billId: bill.id)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Nudge Actions

    func sendNudge(to member: HouseholdMemberModel, message: String? = nil) async {
        do {
            try await nudgeService.sendNudge(toUserId: member.userId, message: message)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func canNudge(member: HouseholdMemberModel) -> Bool {
        nudgeService.canNudge(userId: member.userId)
    }

    // MARK: - Split Calculations

    func calculateSplit(amount: Double) -> [BillSplit] {
        fairnessService.calculateSplit(amount: amount)
    }

    func getBalanceStatus() -> BalanceStatus {
        fairnessService.checkBalance()
    }

    // MARK: - Helpers

    func getInviteMessage() -> String? {
        householdService.generateInviteMessage()
    }

    func getEscalationTimeline(for bill: HouseholdBill) -> EscalationTimeline {
        autoPilotService.getEscalationTimeline(bill: bill)
    }

    func clearError() {
        error = nil
    }
}

// MARK: - Tab Enum

enum HouseholdTab: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case leaderboard = "Leaderboard"
    case vault = "Vault"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .feed: return "list.bullet"
        case .leaderboard: return "trophy.fill"
        case .vault: return "lock.shield.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
