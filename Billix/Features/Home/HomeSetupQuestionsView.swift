//
//  HomeSetupQuestionsView.swift
//  Billix
//
//  First-time user questions to personalize the Home experience
//  Asks about: bill types, monthly budget, and main goal
//

import SwiftUI
import Supabase

// MARK: - Bill Type Options

enum BillTypeOption: String, CaseIterable, Identifiable {
    case electric = "Electric"
    case gas = "Gas"
    case water = "Water"
    case internet = "Internet"
    case phone = "Phone"
    case streaming = "Streaming"
    case insurance = "Insurance"
    case rent = "Rent/Mortgage"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .electric: return "bolt.fill"
        case .gas: return "flame.fill"
        case .water: return "drop.fill"
        case .internet: return "wifi"
        case .phone: return "iphone"
        case .streaming: return "play.tv.fill"
        case .insurance: return "shield.fill"
        case .rent: return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .electric: return Color(hex: "#E8A54B")
        case .gas: return Color(hex: "#E07A6B")
        case .water: return Color(hex: "#5BA4D4")
        case .internet: return Color(hex: "#5B8A6B")
        case .phone: return Color(hex: "#9B7EB8")
        case .streaming: return Color(hex: "#E07A6B")
        case .insurance: return Color(hex: "#5BA4D4")
        case .rent: return Color(hex: "#8B9A94")
        }
    }
}

// MARK: - Budget Range Options

enum BudgetRangeOption: String, CaseIterable, Identifiable {
    case under200 = "under_200"
    case range200to400 = "200_to_400"
    case range400to600 = "400_to_600"
    case range600to800 = "600_to_800"
    case over800 = "over_800"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .under200: return "Under $200"
        case .range200to400: return "$200 - $400"
        case .range400to600: return "$400 - $600"
        case .range600to800: return "$600 - $800"
        case .over800: return "Over $800"
        }
    }

    var subtitle: String {
        switch self {
        case .under200: return "Just starting out"
        case .range200to400: return "Budget-conscious"
        case .range400to600: return "Average household"
        case .range600to800: return "Larger household"
        case .over800: return "Premium lifestyle"
        }
    }

    var icon: String {
        switch self {
        case .under200: return "leaf.fill"
        case .range200to400: return "chart.bar.fill"
        case .range400to600: return "house.fill"
        case .range600to800: return "building.2.fill"
        case .over800: return "crown.fill"
        }
    }
}

// MARK: - Main Goal Options

enum MainGoalOption: String, CaseIterable, Identifiable {
    case saveMoney = "save_money"
    case trackBills = "track_bills"
    case findDeals = "find_deals"
    case compareRates = "compare_rates"
    case stayOrganized = "stay_organized"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .saveMoney: return "Save money on bills"
        case .trackBills: return "Track all my bills"
        case .findDeals: return "Find better deals"
        case .compareRates: return "Compare local rates"
        case .stayOrganized: return "Stay organized"
        }
    }

    var subtitle: String {
        switch self {
        case .saveMoney: return "Cut costs and keep more money"
        case .trackBills: return "Never miss a payment"
        case .findDeals: return "Discover savings opportunities"
        case .compareRates: return "See how I compare to neighbors"
        case .stayOrganized: return "Manage everything in one place"
        }
    }

    var icon: String {
        switch self {
        case .saveMoney: return "dollarsign.circle.fill"
        case .trackBills: return "doc.text.fill"
        case .findDeals: return "tag.fill"
        case .compareRates: return "chart.bar.fill"
        case .stayOrganized: return "folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .saveMoney: return Color(hex: "#4CAF7A")
        case .trackBills: return Color(hex: "#5BA4D4")
        case .findDeals: return Color(hex: "#E8A54B")
        case .compareRates: return Color(hex: "#9B7EB8")
        case .stayOrganized: return Color(hex: "#5B8A6B")
        }
    }
}

// MARK: - Home Setup Questions View

struct HomeSetupQuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var currentStep = 1
    @State private var selectedBillTypes: Set<BillTypeOption> = []
    @State private var selectedBudget: BudgetRangeOption?
    @State private var selectedGoal: MainGoalOption?
    @State private var isLoading = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#1B4332"), Color(hex: "#2D6A4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        if currentStep > 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(currentStep > 1 ? 1 : 0.3))
                    }
                    .disabled(currentStep == 1)

                    Spacer()

                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(1...totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Content
                Group {
                    switch currentStep {
                    case 1: billTypesStep
                    case 2: budgetStep
                    case 3: goalStep
                    default: billTypesStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Continue button
                Button {
                    handleContinue()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#1B4332")))
                        } else {
                            Text(currentStep == totalSteps ? "Get Started" : "Continue")
                                .font(.system(size: 17, weight: .semibold))
                            if currentStep < totalSteps {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .foregroundColor(Color(hex: "#1B4332"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canProceed ? Color.white : Color.white.opacity(0.5))
                    .cornerRadius(28)
                }
                .disabled(!canProceed || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Step 1: Bill Types

    private var billTypesStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)

            // Title
            Text("What bills do you pay?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("Select all that apply. We'll personalize your experience based on these.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Bill type grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(BillTypeOption.allCases) { billType in
                    BillTypeCard(
                        billType: billType,
                        isSelected: selectedBillTypes.contains(billType)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedBillTypes.contains(billType) {
                                selectedBillTypes.remove(billType)
                            } else {
                                selectedBillTypes.insert(billType)
                            }
                        }
                        haptic()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 2: Budget

    private var budgetStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)

            // Title
            Text("Monthly bill budget?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("How much do you typically spend on bills each month?")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Budget options
            VStack(spacing: 12) {
                ForEach(BudgetRangeOption.allCases) { budget in
                    BudgetOptionCard(
                        budget: budget,
                        isSelected: selectedBudget == budget
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedBudget = budget
                        }
                        haptic()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 3: Goal

    private var goalStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.white)

            // Title
            Text("What's your main goal?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("We'll prioritize features and tips based on what matters most to you.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Goal options
            VStack(spacing: 12) {
                ForEach(MainGoalOption.allCases) { goal in
                    GoalOptionCardNew(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGoal = goal
                        }
                        haptic()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var canProceed: Bool {
        switch currentStep {
        case 1: return !selectedBillTypes.isEmpty
        case 2: return selectedBudget != nil
        case 3: return selectedGoal != nil
        default: return false
        }
    }

    private func handleContinue() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            Task {
                await completeSetup()
            }
        }
    }

    private func completeSetup() async {
        isLoading = true

        // Save preferences to user profile
        do {
            try await saveUserPreferences()
            dismiss()
        } catch {
            print("Error saving preferences: \(error)")
            // Still dismiss even on error
            dismiss()
        }

        isLoading = false
    }

    private func saveUserPreferences() async throws {
        let billTypes = selectedBillTypes.map { $0.rawValue }
        let budget = selectedBudget?.rawValue ?? ""
        let goal = selectedGoal?.rawValue ?? ""

        // Update user profile in Supabase
        let client = SupabaseService.shared.client
        guard let userId = try? await client.auth.session.user.id else { return }

        // Use AnyJSON for mixed types
        let updateData: [String: AnyJSON] = [
            "bill_types": .array(billTypes.map { .string($0) }),
            "monthly_budget": .string(budget),
            "main_goal": .string(goal),
            "home_setup_completed": .bool(true)
        ]

        try await client
            .from("profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .execute()

        print("✅ User preferences saved successfully")
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Bill Type Card

private struct BillTypeCard: View {
    let billType: BillTypeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: billType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : billType.color)

                Text(billType.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? billType.color : Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? billType.color : Color.white.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(SetupScaleButtonStyle())
    }
}

// MARK: - Budget Option Card

private struct BudgetOptionCard: View {
    let budget: BudgetRangeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: budget.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(budget.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Option Card (New)

private struct GoalOptionCardNew: View {
    let goal: MainGoalOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : goal.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? goal.color : goal.color.opacity(0.2))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(goal.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Setup Scale Button Style

private struct SetupScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HomeSetupQuestionsView()
}
