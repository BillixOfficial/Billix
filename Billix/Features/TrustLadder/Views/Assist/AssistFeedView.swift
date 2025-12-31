//
//  AssistFeedView.swift
//  Billix
//
//  Created by Claude Code on 12/31/24.
//  Browse and filter assist requests feed
//

import SwiftUI

// MARK: - Filter Options

enum AssistSortOption: String, CaseIterable {
    case newest = "newest"
    case urgency = "urgency"
    case amountLow = "amount_low"
    case amountHigh = "amount_high"

    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .urgency: return "Most Urgent"
        case .amountLow: return "Amount: Low to High"
        case .amountHigh: return "Amount: High to Low"
        }
    }

    var icon: String {
        switch self {
        case .newest: return "clock"
        case .urgency: return "exclamationmark.circle"
        case .amountLow: return "arrow.up"
        case .amountHigh: return "arrow.down"
        }
    }
}

// MARK: - Assist Feed View

struct AssistFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistService = AssistRequestService.shared

    // Data - uses assistService.availableRequests and assistService.myRequests directly

    // Filters
    @State private var selectedUrgencies: Set<AssistUrgency> = []
    @State private var selectedCategories: Set<String> = []
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var sortOption: AssistSortOption = .urgency

    // UI State
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var showFilters = false
    @State private var showCreateRequest = false
    @State private var selectedRequest: AssistRequest?
    @State private var errorMessage: String?

    // Tabs
    @State private var selectedTab: FeedTab = .browse

    enum FeedTab: String, CaseIterable {
        case browse = "Browse"
        case myRequests = "My Requests"
    }

    private let categories = ["Electric", "Gas", "Water", "Internet", "Phone", "Cable", "Insurance", "Rent", "Other"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Content
                    if isLoading {
                        loadingView
                    } else {
                        switch selectedTab {
                        case .browse:
                            browseView
                        case .myRequests:
                            myRequestsView
                        }
                    }
                }
            }
            .navigationTitle("Bill Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Filter button
                        Button {
                            showFilters = true
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(hasActiveFilters ? .blue : .primary)
                        }

                        // Create button
                        Button {
                            showCreateRequest = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    selectedUrgencies: $selectedUrgencies,
                    selectedCategories: $selectedCategories,
                    minAmount: $minAmount,
                    maxAmount: $maxAmount,
                    sortOption: $sortOption,
                    categories: categories
                )
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateAssistRequestView()
            }
            .sheet(item: $selectedRequest) { request in
                AssistRequestDetailView(request: request)
            }
            .onAppear {
                loadData()
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation { selectedTab = tab }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    // MARK: - Browse View

    private var browseView: some View {
        Group {
            if filteredRequests.isEmpty {
                emptyBrowseView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Active filters summary
                        if hasActiveFilters {
                            activeFiltersBar
                        }

                        // Results count
                        HStack {
                            Text("\(filteredRequests.count) request\(filteredRequests.count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Menu {
                                ForEach(AssistSortOption.allCases, id: \.rawValue) { option in
                                    Button {
                                        sortOption = option
                                    } label: {
                                        HStack {
                                            Text(option.displayName)
                                            if sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: sortOption.icon)
                                    Text(sortOption.displayName)
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 4)

                        // Request cards
                        ForEach(filteredRequests) { request in
                            AssistRequestCard(
                                request: request,
                                requesterTrustScore: nil, // Would fetch from service
                                onTap: {
                                    selectedRequest = request
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - My Requests View

    private var myRequestsView: some View {
        Group {
            if assistService.myRequests.isEmpty {
                emptyMyRequestsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Grouped by status
                        ForEach(groupedMyRequests.keys.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.rawValue) { status in
                            if let requests = groupedMyRequests[status], !requests.isEmpty {
                                Section {
                                    ForEach(requests) { request in
                                        AssistRequestCard(
                                            request: request,
                                            requesterTrustScore: nil,
                                            onTap: {
                                                selectedRequest = request
                                            }
                                        )
                                    }
                                } header: {
                                    HStack {
                                        Circle()
                                            .fill(status.color)
                                            .frame(width: 8, height: 8)
                                        Text(status.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(requests.count)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Empty States

    private var emptyBrowseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Requests Found")
                .font(.system(size: 18, weight: .semibold))

            if hasActiveFilters {
                Text("Try adjusting your filters")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Button {
                    clearFilters()
                } label: {
                    Text("Clear Filters")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            } else {
                Text("No one is currently requesting assistance")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var emptyMyRequestsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Active Requests")
                .font(.system(size: 18, weight: .semibold))

            Text("Need help with a bill?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Button {
                showCreateRequest = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Request")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading requests...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Active Filters Bar

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Urgency filters
                ForEach(Array(selectedUrgencies), id: \.rawValue) { urgency in
                    filterChip(urgency.displayName, color: urgency.color) {
                        selectedUrgencies.remove(urgency)
                    }
                }

                // Category filters
                ForEach(Array(selectedCategories), id: \.self) { category in
                    filterChip(category, color: .blue) {
                        selectedCategories.remove(category)
                    }
                }

                // Amount filters
                if !minAmount.isEmpty || !maxAmount.isEmpty {
                    let amountText = amountFilterText
                    filterChip(amountText, color: .green) {
                        minAmount = ""
                        maxAmount = ""
                    }
                }

                // Clear all
                Button {
                    clearFilters()
                } label: {
                    Text("Clear All")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func filterChip(_ text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12, weight: .medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var hasActiveFilters: Bool {
        !selectedUrgencies.isEmpty ||
        !selectedCategories.isEmpty ||
        !minAmount.isEmpty ||
        !maxAmount.isEmpty
    }

    private var filteredRequests: [AssistRequest] {
        var result = assistService.availableRequests

        // Filter by urgency
        if !selectedUrgencies.isEmpty {
            result = result.filter { selectedUrgencies.contains($0.urgency) }
        }

        // Filter by category
        if !selectedCategories.isEmpty {
            result = result.filter { selectedCategories.contains($0.billCategory) }
        }

        // Filter by min amount
        if let min = Double(minAmount), min > 0 {
            result = result.filter { $0.amountRequested >= min }
        }

        // Filter by max amount
        if let max = Double(maxAmount), max > 0 {
            result = result.filter { $0.amountRequested <= max }
        }

        // Sort
        switch sortOption {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .urgency:
            result.sort { $0.urgency.sortOrder < $1.urgency.sortOrder }
        case .amountLow:
            result.sort { $0.amountRequested < $1.amountRequested }
        case .amountHigh:
            result.sort { $0.amountRequested > $1.amountRequested }
        }

        return result
    }

    private var groupedMyRequests: [AssistRequestStatus: [AssistRequest]] {
        Dictionary(grouping: assistService.myRequests, by: { $0.status })
    }

    private var amountFilterText: String {
        if !minAmount.isEmpty && !maxAmount.isEmpty {
            return "$\(minAmount) - $\(maxAmount)"
        } else if !minAmount.isEmpty {
            return "$\(minAmount)+"
        } else {
            return "Up to $\(maxAmount)"
        }
    }

    // MARK: - Actions

    private func loadData() {
        isLoading = true
        Task {
            await assistService.fetchAvailableRequests()
            await assistService.fetchMyRequests()
            isLoading = false
        }
    }

    private func refreshData() async {
        await assistService.fetchAvailableRequests()
        await assistService.fetchMyRequests()
    }

    private func clearFilters() {
        selectedUrgencies.removeAll()
        selectedCategories.removeAll()
        minAmount = ""
        maxAmount = ""
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUrgencies: Set<AssistUrgency>
    @Binding var selectedCategories: Set<String>
    @Binding var minAmount: String
    @Binding var maxAmount: String
    @Binding var sortOption: AssistSortOption
    let categories: [String]

    var body: some View {
        NavigationView {
            List {
                // Urgency section
                Section("Urgency") {
                    ForEach(AssistUrgency.allCases, id: \.rawValue) { urgency in
                        Button {
                            if selectedUrgencies.contains(urgency) {
                                selectedUrgencies.remove(urgency)
                            } else {
                                selectedUrgencies.insert(urgency)
                            }
                        } label: {
                            HStack {
                                Image(systemName: urgency.icon)
                                    .foregroundColor(urgency.color)
                                    .frame(width: 24)
                                Text(urgency.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedUrgencies.contains(urgency) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Category section
                Section("Category") {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        } label: {
                            HStack {
                                Text(category)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Amount section
                Section("Amount Range") {
                    HStack {
                        Text("Min $")
                            .foregroundColor(.secondary)
                        TextField("0", text: $minAmount)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("Max $")
                            .foregroundColor(.secondary)
                        TextField("Any", text: $maxAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                // Sort section
                Section("Sort By") {
                    ForEach(AssistSortOption.allCases, id: \.rawValue) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(option.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Reset button
                Section {
                    Button("Reset Filters") {
                        selectedUrgencies.removeAll()
                        selectedCategories.removeAll()
                        minAmount = ""
                        maxAmount = ""
                        sortOption = .urgency
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Request Detail View (Placeholder)

struct AssistRequestDetailView: View {
    let request: AssistRequest
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistService = AssistRequestService.shared

    @State private var showMakeOffer = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    headerCard

                    // Bill details
                    detailCard(title: "Bill Information", icon: "doc.text.fill", color: .blue) {
                        VStack(spacing: 12) {
                            detailRow("Category", value: request.billCategory)
                            detailRow("Provider", value: request.billProvider)
                            detailRow("Bill Amount", value: "$\(String(format: "%.2f", request.billAmount))")
                            detailRow("Due Date", value: request.billDueDate.formatted(date: .abbreviated, time: .omitted))
                            if request.isOverdue {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("This bill is overdue!")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // Request details
                    detailCard(title: "Request Details", icon: "dollarsign.circle.fill", color: .green) {
                        VStack(spacing: 12) {
                            detailRow("Amount Requested", value: "$\(String(format: "%.0f", request.amountRequested))", highlight: true)
                            detailRow("Urgency", value: request.urgency.displayName, valueColor: request.urgency.color)
                            if let description = request.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(description)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }

                    // Preferred terms
                    if let terms = request.preferredTerms {
                        detailCard(title: "Preferred Terms", icon: "handshake.fill", color: .orange) {
                            VStack(spacing: 12) {
                                detailRow("Type", value: terms.assistType.displayName, valueColor: terms.assistType.color)
                                if let rate = terms.interestRate, rate > 0 {
                                    detailRow("Interest Offered", value: "\(String(format: "%.1f", rate))%")
                                }
                                if let date = terms.repaymentDate {
                                    detailRow("Repay By", value: date.formatted(date: .abbreviated, time: .omitted))
                                }
                                if let count = terms.installmentCount, count > 1 {
                                    detailRow("Installments", value: "\(count) payments")
                                }
                                if let notes = terms.notes, !notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notes")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        Text(notes)
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                        }
                    }

                    // Fee info
                    feeInfoCard

                    // Disclaimer
                    disclaimerCard

                    // Error
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Action button
                    if request.status == .active {
                        Button {
                            showMakeOffer = true
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Make an Offer to Help")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMakeOffer) {
                MakeOfferSheet(request: request) { success in
                    if success {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: 12) {
            // Urgency badge
            HStack {
                Image(systemName: request.urgency.icon)
                Text(request.urgency.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(request.urgency.color)
            .cornerRadius(8)

            // Amount
            Text("$\(String(format: "%.0f", request.amountRequested))")
                .font(.system(size: 42, weight: .bold, design: .rounded))

            Text("needed for \(request.billProvider)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(request.status.color)
                    .frame(width: 8, height: 8)
                Text(request.status.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func detailCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func detailRow(_ label: String, value: String, highlight: Bool = false, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: highlight ? .bold : .medium))
                .foregroundColor(valueColor ?? .primary)
        }
    }

    private var feeInfoCard: some View {
        let tier = AssistConnectionFeeTier.tier(for: request.amountRequested)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Connection Fee: \(tier.formattedFee)")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text("If your offer is accepted, both you and the requester will pay this fee to connect.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Important")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text("Billix is a marketplace connecting users. All terms are negotiated between parties. Billix does not guarantee transactions or outcomes.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Make Offer Sheet

struct MakeOfferSheet: View {
    let request: AssistRequest
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistService = AssistRequestService.shared

    // Terms
    @State private var assistType: AssistType
    @State private var interestRate: String = ""
    @State private var repaymentDate: Date = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var message: String = ""

    // UI State
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(request: AssistRequest, onComplete: @escaping (Bool) -> Void) {
        self.request = request
        self.onComplete = onComplete
        _assistType = State(initialValue: request.preferredTerms?.assistType ?? .loan)
        if let rate = request.preferredTerms?.interestRate {
            _interestRate = State(initialValue: "\(rate)")
        }
        if let date = request.preferredTerms?.repaymentDate {
            _repaymentDate = State(initialValue: date)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Offer summary
                    VStack(spacing: 8) {
                        Text("Offering to help with")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", request.amountRequested))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(request.billProvider)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Terms selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Proposed Terms")
                            .font(.system(size: 15, weight: .semibold))

                        // Assist type
                        ForEach(AssistType.allCases, id: \.rawValue) { type in
                            Button {
                                assistType = type
                            } label: {
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundColor(type.color)
                                        .frame(width: 24)
                                    Text(type.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if assistType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(assistType == type ? type.color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Loan terms
                    if assistType == .loan || assistType == .partialGift {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repayment Terms")
                                .font(.system(size: 15, weight: .semibold))

                            HStack {
                                Text("Interest Rate")
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("0", text: $interestRate)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)

                            DatePicker("Repay By", selection: $repaymentDate, in: Date()..., displayedComponents: .date)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }

                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message to Requester (Optional)")
                            .font(.system(size: 15, weight: .semibold))

                        TextEditor(text: $message)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Error
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Submit button
                    Button {
                        submitOffer()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Offer")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Make Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitOffer() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let terms = RepaymentTerms(
                    assistType: assistType,
                    interestRate: Double(interestRate),
                    repaymentDate: (assistType == .loan || assistType == .partialGift) ? repaymentDate : nil,
                    installmentCount: nil,
                    installmentAmount: nil,
                    gracePeriodDays: nil,
                    notes: nil
                )

                _ = try await assistService.makeOffer(
                    requestId: request.id,
                    proposedTerms: terms,
                    message: message.isEmpty ? nil : message
                )

                dismiss()
                onComplete(true)
            } catch {
                errorMessage = error.localizedDescription
                onComplete(false)
            }
            isSubmitting = false
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AssistFeedView_Previews: PreviewProvider {
    static var previews: some View {
        AssistFeedView()
    }
}
#endif
