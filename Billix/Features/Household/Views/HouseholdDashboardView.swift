//
//  HouseholdDashboardView.swift
//  Billix
//
//  Main dashboard for the Household feature with tabs
//  for Feed, Leaderboard, Vault, and Settings.
//

import SwiftUI

struct HouseholdDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HouseholdViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasHousehold {
                    loadingView
                } else if viewModel.hasHousehold {
                    householdContent
                } else {
                    noHouseholdView
                }
            }
            .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                }

                if viewModel.hasHousehold {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            // Nudge indicator
                            if viewModel.unreadNudges > 0 {
                                Button {
                                    // Show nudges
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.system(size: 18))
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                    .foregroundColor(Color(hex: "#5B8A6B"))
                                }
                            }

                            // Invite button
                            Button {
                                viewModel.showInvite = true
                            } label: {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#5B8A6B"))
                            }
                        }
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showCreateHousehold) {
                CreateHouseholdSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showJoinHousehold) {
                JoinHouseholdSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showInvite) {
                InviteSheet(inviteCode: viewModel.household?.inviteCode ?? "")
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading household...")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#8B9A94"))
        }
    }

    private var householdContent: some View {
        VStack(spacing: 0) {
            // Header with household name
            householdHeader

            // Tab picker
            tabPicker

            // Tab content
            TabView(selection: $viewModel.selectedTab) {
                HouseholdFeedView(viewModel: viewModel)
                    .tag(HouseholdTab.feed)

                KarmaLeaderboardView(viewModel: viewModel)
                    .tag(HouseholdTab.leaderboard)

                VaultView()
                    .tag(HouseholdTab.vault)

                HouseholdSettingsView(viewModel: viewModel)
                    .tag(HouseholdTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(hex: "#F7F9F8"))
    }

    private var householdHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Household icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#5B8A6B").opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.household?.name ?? "Household")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    HStack(spacing: 8) {
                        Label("\(viewModel.members.count) members", systemImage: "person.2.fill")
                        Text("·")
                        Label("Score: \(viewModel.household?.collectiveTrustScore ?? 0)", systemImage: "star.fill")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                // Escalation alert badge
                if !viewModel.pendingEscalations.isEmpty {
                    Button {
                        // Show escalations
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text("\(viewModel.pendingEscalations.count)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(HouseholdTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(viewModel.selectedTab == tab
                        ? Color(hex: "#5B8A6B")
                        : Color(hex: "#8B9A94"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.selectedTab == tab
                            ? Color(hex: "#5B8A6B").opacity(0.1)
                            : Color.clear
                    )
                }
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "#E8E8E8"))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var noHouseholdView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color(hex: "#5B8A6B").opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }

            VStack(spacing: 8) {
                Text("No Household Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("Create or join a household to share bills,\ntrack karma, and save together")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    viewModel.showCreateHousehold = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Household")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#5B8A6B"))
                    .cornerRadius(12)
                }

                Button {
                    viewModel.showJoinHousehold = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Join with Code")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#5B8A6B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#5B8A6B").opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Household Feed View

struct HouseholdFeedView: View {
    @ObservedObject var viewModel: HouseholdViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Monthly Hero Card (if exists)
                if let hero = viewModel.monthlyHero {
                    HouseholdHeroCard(hero: hero)
                        .padding(.horizontal, 20)
                }

                // Shared Bills
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Shared Bills")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Spacer()

                        Text("\(viewModel.householdBills.count) bills")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#8B9A94"))
                    }
                    .padding(.horizontal, 20)

                    if viewModel.householdBills.isEmpty {
                        emptyBillsView
                    } else {
                        ForEach(viewModel.householdBills) { bill in
                            HouseholdBillRow(
                                bill: bill,
                                timeline: viewModel.getEscalationTimeline(for: bill),
                                onToggleAutoPilot: {
                                    Task {
                                        await viewModel.toggleAutoPilot(for: bill)
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // Members Quick View
                membersSection

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
    }

    private var emptyBillsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "#8B9A94").opacity(0.5))

            Text("No shared bills yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#8B9A94"))

            Text("Add bills to share with the household")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94").opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#2D3B35"))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.members) { member in
                        MemberQuickCard(
                            member: member,
                            canNudge: viewModel.canNudge(member: member),
                            onNudge: {
                                Task {
                                    await viewModel.sendNudge(to: member)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Supporting Views

struct HouseholdBillRow: View {
    let bill: HouseholdBill
    let timeline: EscalationTimeline
    let onToggleAutoPilot: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Bill icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#5B8A6B").opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: billIcon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.swapBill?.providerName ?? "Bill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    HStack(spacing: 6) {
                        Text(bill.swapBill?.billType ?? "Unknown")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8B9A94"))

                        Text("·")

                        Image(systemName: bill.visibility.icon)
                            .font(.system(size: 10))
                        Text(bill.visibility.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(visibilityColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", bill.swapBill?.amount ?? 0))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    if bill.autoPilotEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane")
                                .font(.system(size: 9))
                            Text(timeline.statusMessage)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#5B8A6B"))
                    }
                }
            }

            // Auto-Pilot toggle
            HStack {
                Toggle(isOn: .init(
                    get: { bill.autoPilotEnabled },
                    set: { _ in onToggleAutoPilot() }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.system(size: 12))
                        Text("Auto-Pilot")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#2D3B35"))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#5B8A6B")))
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var billIcon: String {
        switch bill.swapBill?.billType.lowercased() {
        case "electric", "electricity": return "bolt.fill"
        case "gas": return "flame.fill"
        case "water": return "drop.fill"
        case "internet", "wifi": return "wifi"
        default: return "doc.text.fill"
        }
    }

    private var visibilityColor: Color {
        switch bill.visibility {
        case .personal: return Color(hex: "#8B9A94")
        case .household: return Color(hex: "#5B8A6B")
        case .public: return Color(hex: "#9B7EB8")
        }
    }
}

struct MemberQuickCard: View {
    let member: HouseholdMemberModel
    let canNudge: Bool
    let onNudge: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#5B8A6B").opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(member.effectiveDisplayName.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                // Role badge
                if member.role == .head {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .offset(x: 18, y: -18)
                }
            }

            VStack(spacing: 2) {
                Text(member.effectiveDisplayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .lineLimit(1)

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                    Text("\(member.karmaScore)")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color(hex: "#E8A54B"))
            }

            // Nudge button
            if canNudge {
                Button(action: onNudge) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 10))
                        Text("Nudge")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "#5B8A6B"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#5B8A6B").opacity(0.12))
                    .cornerRadius(8)
                }
            }
        }
        .frame(width: 90)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Sheets

struct CreateHouseholdSheet: View {
    @ObservedObject var viewModel: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var fairnessMode: FairnessMode = .equal

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Household Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Fairness Mode")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(FairnessMode.allCases, id: \.self) { mode in
                        Button {
                            fairnessMode = mode
                        } label: {
                            HStack {
                                Image(systemName: mode.icon)
                                VStack(alignment: .leading) {
                                    Text(mode.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(mode.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if fairnessMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#5B8A6B"))
                                }
                            }
                            .padding()
                            .background(fairnessMode == mode ? Color(hex: "#5B8A6B").opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.createHousehold(name: name, fairnessMode: fairnessMode)
                    }
                } label: {
                    Text("Create Household")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(name.isEmpty ? Color.gray : Color(hex: "#5B8A6B"))
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .navigationTitle("Create Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct JoinHouseholdSheet: View {
    @ObservedObject var viewModel: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var displayName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Code")
                        .font(.headline)
                    TextField("Enter code", text: $inviteCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name (optional)")
                        .font(.headline)
                    TextField("How should roommates see you?", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    Task {
                        await viewModel.joinHousehold(
                            inviteCode: inviteCode,
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                    }
                } label: {
                    Text("Join Household")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(inviteCode.isEmpty ? Color.gray : Color(hex: "#5B8A6B"))
                        .cornerRadius(12)
                }
                .disabled(inviteCode.isEmpty)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .navigationTitle("Join Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct InviteSheet: View {
    let inviteCode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("Invite Roommates")
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    Text("Share this code:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                        .padding()
                        .background(Color(hex: "#5B8A6B").opacity(0.1))
                        .cornerRadius(12)
                }

                Button {
                    UIPasteboard.general.string = inviteCode
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Code")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HouseholdSettingsView: View {
    @ObservedObject var viewModel: HouseholdViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Settings")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                // Placeholder for settings
                VStack(spacing: 12) {
                    HouseholdSettingsRow(icon: "person.2.fill", title: "Manage Members", subtitle: "\(viewModel.members.count) members")
                    HouseholdSettingsRow(icon: "slider.horizontal.3", title: "Fairness Mode", subtitle: viewModel.household?.fairnessMode.displayName ?? "Equal")
                    HouseholdSettingsRow(icon: "airplane", title: "Auto-Pilot Settings", subtitle: viewModel.household?.autoPilotEnabled == true ? "Enabled" : "Disabled")

                    Divider()
                        .padding(.vertical, 8)

                    Button {
                        Task {
                            await viewModel.leaveHousehold()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Leave Household")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
    }
}

struct HouseholdSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#5B8A6B"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "#5B8A6B").opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#8B9A94"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    HouseholdDashboardView()
}
