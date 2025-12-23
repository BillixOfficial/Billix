//
//  AvailableSwapsView.swift
//  Billix
//
//  Created by Claude Code on 12/23/24.
//  View for browsing and joining available swaps
//

import SwiftUI

struct AvailableSwapsView: View {
    @StateObject private var swapService = MultiPartySwapService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var feedService = MarketplaceFeedService.shared

    @State private var selectedCategory: ReceiptBillCategory?
    @State private var selectedSwapType: SwapType?
    @State private var showFilters = false
    @State private var selectedSwap: MultiPartySwap?
    @State private var showJoinSheet = false

    // Theme colors
    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Category filter chips
                categoryFilterBar

                // Content
                if swapService.isLoading {
                    loadingState
                } else if filteredSwaps.isEmpty {
                    emptyState
                } else {
                    swapsList
                }
            }
        }
        .navigationTitle("Browse Swaps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(primaryText)
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            SwapFiltersSheet(
                selectedCategory: $selectedCategory,
                selectedSwapType: $selectedSwapType
            )
        }
        .sheet(isPresented: $showJoinSheet) {
            if let swap = selectedSwap {
                JoinSwapSheet(swap: swap)
            }
        }
        .onAppear {
            Task {
                await swapService.loadAvailableSwaps()
            }
        }
        .refreshable {
            await swapService.loadAvailableSwaps()
        }
    }

    // MARK: - Filtered Swaps

    private var filteredSwaps: [MultiPartySwap] {
        var swaps = swapService.availableSwaps

        if let type = selectedSwapType {
            swaps = swaps.filter { $0.type == type }
        }

        return swaps
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                filterChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                // Hot categories first
                ForEach(feedService.statistics.hotCategories) { hot in
                    if let category = hot.billCategory {
                        filterChip(
                            label: category.displayName,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category,
                            isHot: true
                        ) {
                            selectedCategory = category
                        }
                    }
                }

                // Other categories
                ForEach(ReceiptBillCategory.allCases.filter { cat in
                    !feedService.statistics.hotCategories.contains { $0.category == cat.rawValue }
                }) { category in
                    filterChip(
                        label: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(cardBg)
    }

    private func filterChip(
        label: String,
        icon: String? = nil,
        color: Color = .gray,
        isSelected: Bool,
        isHot: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isHot {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }

                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? accent : background)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : secondaryText.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Swaps List

    private var swapsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSwaps) { swap in
                    swapCard(swap)
                }
            }
            .padding()
        }
    }

    private func swapCard(_ swap: MultiPartySwap) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: swap.type?.icon ?? "arrow.left.arrow.right")
                        .font(.system(size: 12))
                    Text(swap.type?.displayName ?? "Swap")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(swap.type?.color ?? accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((swap.type?.color ?? accent).opacity(0.15))
                .cornerRadius(6)

                Spacer()

                // Priority badge if boosted
                if swapService.priorityListings.contains(where: { $0.swapId == swap.id && $0.isActive }) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("BOOSTED")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(4)
                }
            }

            // Amount info
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Looking for")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)

                    Text(swap.formattedRemainingAmount)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)

                    Text(swap.formattedTargetAmount)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(secondaryText)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: swap.fillPercentage)
                    .tint(swap.type?.color ?? accent)

                HStack {
                    Text("\(Int(swap.fillPercentage * 100))% filled")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)

                    Spacer()

                    if let minContribution = swap.minContribution {
                        Text("Min: $\(minContribution as NSDecimalNumber)")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)
                    }
                }
            }

            // Details row
            HStack(spacing: 16) {
                detailItem(icon: "person.3", value: "Max \(swap.maxParticipants)")

                if let deadline = swap.executionDeadline {
                    detailItem(icon: "calendar", value: deadline.formatted(date: .abbreviated, time: .omitted))
                }

                Spacer()
            }

            // Join button
            Button {
                selectedSwap = swap
                showJoinSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Join Swap")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accent)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func detailItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(value)
                .font(.system(size: 11))
        }
        .foregroundColor(secondaryText)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(accent)
            Text("Loading swaps...")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(secondaryText)

            Text("No swaps available")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Check back later or create your own swap")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            NavigationLink {
                FractionalSwapSetupView()
            } label: {
                Text("Create a Swap")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Swap Filters Sheet

struct SwapFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ReceiptBillCategory?
    @Binding var selectedSwapType: SwapType?

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Swap type filter
                        filterSection(title: "Swap Type") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                typeFilterButton(nil, label: "All Types")

                                ForEach([SwapType.fractional, .multiParty], id: \.self) { type in
                                    typeFilterButton(type, label: type.displayName)
                                }
                            }
                        }

                        // Category filter
                        filterSection(title: "Bill Category") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                categoryFilterButton(nil, label: "All Categories")

                                ForEach(ReceiptBillCategory.allCases) { category in
                                    categoryFilterButton(category, label: category.displayName)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedCategory = nil
                        selectedSwapType = nil
                    }
                    .foregroundColor(secondaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(accent)
                }
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            content()
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    private func typeFilterButton(_ type: SwapType?, label: String) -> some View {
        let isSelected = selectedSwapType == type

        return Button {
            selectedSwapType = type
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .black : primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? accent : background)
                .cornerRadius(8)
        }
    }

    private func categoryFilterButton(_ category: ReceiptBillCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 4) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .black : primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? accent : background)
            .cornerRadius(8)
        }
    }
}

// MARK: - Join Swap Sheet

struct JoinSwapSheet: View {
    let swap: MultiPartySwap

    @Environment(\.dismiss) private var dismiss
    @StateObject private var swapService = MultiPartySwapService.shared

    @State private var selectedContribution: ContributionOption?
    @State private var customAmount: String = ""
    @State private var useCustomAmount = false
    @State private var isJoining = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    private let cardBg = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    private let primaryText = Color.white
    private let secondaryText = Color.gray

    private var contributionOptions: [ContributionOption] {
        ContributionOption.options(for: swap.remainingAmount)
    }

    private var contributionAmount: Decimal {
        if useCustomAmount {
            return Decimal(string: customAmount) ?? 0
        }
        return selectedContribution?.amount ?? 0
    }

    private var isValidContribution: Bool {
        let amount = contributionAmount
        guard amount > 0 else { return false }

        if let minContribution = swap.minContribution, amount < minContribution {
            return false
        }

        if amount > swap.remainingAmount {
            return false
        }

        return true
    }

    var body: some View {
        NavigationView {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Swap summary
                        swapSummaryCard

                        // Contribution options
                        contributionSection

                        // Custom amount
                        customAmountSection

                        // Error
                        if let error = errorMessage {
                            errorBanner(error)
                        }

                        // Legal notice
                        legalNotice

                        // Join button
                        joinButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Join Swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(secondaryText)
                }
            }
            .alert("Joined Successfully!", isPresented: $showSuccess) {
                Button("Great") {
                    dismiss()
                }
            } message: {
                Text("You've joined the swap. You'll be notified when it's time to make your payment.")
            }
        }
    }

    // MARK: - Swap Summary

    private var swapSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: swap.type?.icon ?? "arrow.left.arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(swap.type?.color ?? accent)

                Text(swap.type?.displayName ?? "Swap")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryText)

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text(swap.formattedRemainingAmount)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(primaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Target")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                    Text(swap.formattedTargetAmount)
                        .font(.system(size: 16))
                        .foregroundColor(secondaryText)
                }
            }

            ProgressView(value: swap.fillPercentage)
                .tint(swap.type?.color ?? accent)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Contribution Section

    private var contributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Your Contribution")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(contributionOptions) { option in
                    contributionButton(option)
                }
            }
        }
    }

    private func contributionButton(_ option: ContributionOption) -> some View {
        let isSelected = selectedContribution?.id == option.id && !useCustomAmount
        let isDisabled = option.amount < (swap.minContribution ?? 0)

        return Button {
            selectedContribution = option
            useCustomAmount = false
        } label: {
            VStack(spacing: 4) {
                Text(option.displayPercentage)
                    .font(.system(size: 14, weight: .bold))
                Text(option.formattedAmount)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .black : (isDisabled ? secondaryText : primaryText))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? accent : cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDisabled ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isDisabled)
    }

    // MARK: - Custom Amount

    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                useCustomAmount = true
                selectedContribution = nil
            } label: {
                HStack {
                    Image(systemName: useCustomAmount ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(useCustomAmount ? accent : secondaryText)

                    Text("Custom amount")
                        .font(.system(size: 14))
                        .foregroundColor(primaryText)
                }
            }

            if useCustomAmount {
                HStack {
                    Text("$")
                        .foregroundColor(secondaryText)
                    TextField("0.00", text: $customAmount)
                        .keyboardType(.decimalPad)
                        .foregroundColor(primaryText)
                }
                .padding()
                .background(cardBg)
                .cornerRadius(10)

                if let min = swap.minContribution {
                    Text("Minimum: $\(min as NSDecimalNumber)")
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Legal Notice

    private var legalNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)

            Text("By joining, you commit to paying your contribution directly to the bill provider. Billix coordinates the swap but does not handle payments.")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
                .lineSpacing(2)
        }
        .padding()
        .background(cardBg.opacity(0.5))
        .cornerRadius(10)
    }

    // MARK: - Join Button

    private var joinButton: some View {
        Button {
            joinSwap()
        } label: {
            HStack {
                if isJoining {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirm & Join")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValidContribution ? accent : secondaryText)
            .cornerRadius(14)
        }
        .disabled(!isValidContribution || isJoining)
    }

    // MARK: - Actions

    private func joinSwap() {
        isJoining = true
        errorMessage = nil

        Task {
            do {
                try await swapService.joinSwap(swap.id, contribution: contributionAmount)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isJoining = false
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AvailableSwapsView()
    }
    .preferredColorScheme(.dark)
}
