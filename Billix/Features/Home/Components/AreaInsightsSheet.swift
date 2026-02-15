//
//  AreaInsightsSheet.swift
//  Billix
//
//  Local area insights - providers, averages, deals
//

import SwiftUI

// LocalDeal is defined in OpenAIService.swift

struct AreaInsightsSheet: View {
    // Location state (mutable to allow changing)
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    // Change location sheet state
    @State private var showChangeLocationSheet = false
    @State private var newZipCode = ""
    @State private var isValidatingZip = false
    @State private var zipError: String?

    // Local Providers state
    @State private var providers: [LocalUtilityProvider] = []
    @State private var isLoadingProviders = true
    @State private var providersError: String?

    // Local Deals state
    @State private var localDeals: [LocalDeal] = []
    @State private var isLoadingDeals = true
    @State private var dealsError: String?

    // Interest capture state
    @State private var submittedDealTitles: Set<String> = []
    @State private var submittingDealTitle: String? = nil

    // Custom initializer to accept initial location values
    init(city: String, state: String, zipCode: String) {
        _city = State(initialValue: city)
        _state = State(initialValue: state)
        _zipCode = State(initialValue: zipCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location Header
                    locationHeader

                    // Local Providers
                    providersSection

                    // Local Deals
                    dealsSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Area Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                // Simulate loading for providers/averages
                try? await Task.sleep(nanoseconds: 500_000_000)
                isLoading = false
            }
            .task {
                await loadLocalProviders()
            }
            .task {
                await loadLocalDeals()
            }
            .sheet(isPresented: $showChangeLocationSheet) {
                changeLocationSheet
            }
        }
    }

    // MARK: - Change Location Sheet

    private var changeLocationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Instructions
                VStack(spacing: 8) {
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.billixDarkTeal)

                    Text("Enter a ZIP Code")
                        .font(.headline)

                    Text("See providers and deals for a different area")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // ZIP Code Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("ZIP Code", text: $newZipCode)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: newZipCode) { _, newValue in
                            // Limit to 5 digits
                            if newValue.count > 5 {
                                newZipCode = String(newValue.prefix(5))
                            }
                            // Clear error when typing
                            zipError = nil
                        }

                    if let error = zipError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)

                // Update Button
                Button {
                    Task {
                        await validateAndUpdateLocation()
                    }
                } label: {
                    HStack {
                        if isValidatingZip {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Update Location")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(newZipCode.count == 5 ? Color.billixDarkTeal : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(newZipCode.count != 5 || isValidatingZip)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Change Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showChangeLocationSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Validate and Update Location

    private func validateAndUpdateLocation() async {
        guard newZipCode.count == 5, newZipCode.allSatisfy({ $0.isNumber }) else {
            zipError = "Please enter a valid 5-digit ZIP code"
            return
        }

        isValidatingZip = true

        do {
            // Use Zippopotam.us API to lookup city/state from ZIP
            let url = URL(string: "https://api.zippopotam.us/us/\(newZipCode)")!
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                zipError = "ZIP code not found"
                isValidatingZip = false
                return
            }

            struct ZipResponse: Codable {
                let places: [Place]

                struct Place: Codable {
                    let placeName: String
                    let stateAbbreviation: String

                    enum CodingKeys: String, CodingKey {
                        case placeName = "place name"
                        case stateAbbreviation = "state abbreviation"
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case places
                }
            }

            let zipData = try JSONDecoder().decode(ZipResponse.self, from: data)

            guard let place = zipData.places.first else {
                zipError = "Could not find location for this ZIP"
                isValidatingZip = false
                return
            }

            // Update location
            city = place.placeName
            state = place.stateAbbreviation
            zipCode = newZipCode

            // Dismiss sheet
            showChangeLocationSheet = false
            isValidatingZip = false

            // Reload data for new location
            await reloadAllData()

        } catch {
            print("❌ ZIP lookup error: \(error)")
            zipError = "Unable to validate ZIP code"
            isValidatingZip = false
        }
    }

    // MARK: - Reload All Data

    private func reloadAllData() async {
        // Clear existing data and show loading states
        providers = []
        localDeals = []
        isLoadingProviders = true
        isLoadingDeals = true
        providersError = nil
        dealsError = nil

        // Load both in parallel
        async let providersTask: () = loadLocalProviders()
        async let dealsTask: () = loadLocalDeals()

        await providersTask
        await dealsTask
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title2)
                .foregroundStyle(Color.billixDarkTeal)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(city), \(state)")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(zipCode)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                newZipCode = zipCode
                zipError = nil
                showChangeLocationSheet = true
            } label: {
                Text("Change")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.billixDarkTeal)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Providers Section

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(title: "Local Utility Providers", icon: "building.2.fill")

            if isLoadingProviders {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Finding providers in your area...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if let error = providersError {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadLocalProviders()
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.billixDarkTeal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if providers.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "building.2.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No providers found for your area")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Providers list
                VStack(spacing: 0) {
                    ForEach(providers) { provider in
                        ProviderRow(provider: provider)

                        if provider.name != providers.last?.name {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Load Local Providers

    private func loadLocalProviders() async {
        isLoadingProviders = true
        providersError = nil

        do {
            providers = try await OpenAIService.shared.getLocalProviders(
                zipCode: zipCode,
                city: city,
                state: state
            )
            isLoadingProviders = false
        } catch {
            providersError = "Unable to load providers"
            isLoadingProviders = false
            print("❌ Failed to load local providers: \(error)")
        }
    }

    // MARK: - Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(title: "Local Deals & Savings", icon: "tag.fill")

            if isLoadingDeals {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Finding deals in your area...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if let error = dealsError {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadLocalDeals()
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.billixDarkTeal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if localDeals.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No deals available for your area")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Deals list
                VStack(spacing: 0) {
                    ForEach(localDeals) { deal in
                        DealRow(
                            deal: deal,
                            isSubmitted: submittedDealTitles.contains(deal.title),
                            isSubmitting: submittingDealTitle == deal.title
                        ) {
                            Task {
                                await submitInterest(deal: deal)
                            }
                        }

                        if deal.id != localDeals.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Load Local Deals

    private func loadLocalDeals() async {
        isLoadingDeals = true
        dealsError = nil

        do {
            localDeals = try await OpenAIService.shared.getLocalDeals(
                zipCode: zipCode,
                city: city,
                state: state
            )
            isLoadingDeals = false
        } catch {
            dealsError = "Unable to load deals"
            isLoadingDeals = false
            print("❌ Failed to load local deals: \(error)")
        }
    }

    // MARK: - Submit Interest

    private func submitInterest(deal: LocalDeal) async {
        guard !submittedDealTitles.contains(deal.title) else { return }

        submittingDealTitle = deal.title

        do {
            // Get current user info from session
            let session = try await SupabaseService.shared.client.auth.session
            let userId = session.user.id.uuidString
            let userEmail = session.user.email

            // Insert into deal_interests table
            struct DealInterestInsert: Encodable {
                let user_id: String?
                let deal_title: String
                let deal_description: String
                let deal_category: String
                let zip_code: String
                let city: String
                let state: String
                let user_email: String?
                let user_name: String?
            }

            let insert = DealInterestInsert(
                user_id: userId,
                deal_title: deal.title,
                deal_description: deal.description,
                deal_category: deal.category,
                zip_code: zipCode,
                city: city,
                state: state,
                user_email: userEmail,
                user_name: nil // Could fetch from profile if needed
            )

            try await SupabaseService.shared.client
                .from("deal_interests")
                .insert(insert)
                .execute()

            // Send email notification via Edge Function
            struct NotifyRequest: Encodable {
                let dealTitle: String
                let dealDescription: String
                let dealCategory: String
                let zipCode: String
                let city: String
                let state: String
                let userEmail: String?
                let userName: String?
            }

            let notifyRequest = NotifyRequest(
                dealTitle: deal.title,
                dealDescription: deal.description,
                dealCategory: deal.category,
                zipCode: zipCode,
                city: city,
                state: state,
                userEmail: userEmail,
                userName: nil
            )

            try? await SupabaseService.shared.client.functions
                .invoke("notify-deal-interest", options: .init(body: notifyRequest))

            // Mark as submitted
            submittedDealTitles.insert(deal.title)

            // Haptic feedback
            await MainActor.run {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }

        } catch {
            print("❌ Failed to submit deal interest: \(error)")
        }

        submittingDealTitle = nil
    }
}

// MARK: - Insights Section Header

private struct InsightsSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.billixDarkTeal)

            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Provider Row

private struct ProviderRow: View {
    let provider: LocalUtilityProvider

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(provider.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: provider.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(provider.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(provider.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Deal Row

private struct DealRow: View {
    let deal: LocalDeal
    let isSubmitted: Bool
    let isSubmitting: Bool
    let onTap: () -> Void

    private var iconColor: Color {
        switch deal.category {
        case "rebate": return .yellow
        case "solar": return .orange
        case "assistance": return .blue
        case "billing": return .purple
        default: return Color.billixMoneyGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: deal.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(deal.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(deal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        if let savings = deal.savingsAmount {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.billixMoneyGreen)

                            if deal.deadline != nil {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if let deadline = deal.deadline {
                            Text(deadline)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Show status indicator
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if isSubmitted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.billixMoneyGreen)
                } else {
                    Text("I'm Interested")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.billixDarkTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.billixDarkTeal.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .disabled(isSubmitted || isSubmitting)
    }
}

// MARK: - Preview

#Preview {
    AreaInsightsSheet(city: "Plainfield", state: "NJ", zipCode: "07060")
}
