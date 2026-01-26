//
//  BillExplorerViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  ViewModel for Bill Explorer feed
//

import Foundation
import Combine
import SwiftUI

@MainActor
class BillExplorerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var listings: [ExploreBillListing] = []
    @Published var selectedExploreBillType: ExploreBillType?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Computed Properties

    var filteredListings: [ExploreBillListing] {
        guard let selectedType = selectedExploreBillType else {
            return listings
        }
        return listings.filter { $0.billType == selectedType }
    }

    var billTypes: [ExploreBillType] {
        ExploreBillType.allCases
    }

    // MARK: - Initialization

    init() {
        loadMockData()
    }

    // MARK: - Public Methods

    func loadMockData() {
        isLoading = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.listings = ExploreBillListing.mockListings
            self?.isLoading = false
        }
    }

    func refresh() async {
        isLoading = true
        error = nil

        // Simulate network request
        try? await Task.sleep(nanoseconds: 500_000_000)

        listings = ExploreBillListing.mockListings.shuffled()
        isLoading = false
    }

    func selectExploreBillType(_ type: ExploreBillType?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedExploreBillType == type {
                selectedExploreBillType = nil  // Toggle off
            } else {
                selectedExploreBillType = type
            }
        }
    }

    func toggleReaction(for listingId: UUID, reaction: BillReactionType) {
        guard let index = listings.firstIndex(where: { $0.id == listingId }) else { return }

        // Toggle reaction count (simple local state for now)
        var updatedReactions = listings[index].reactions
        let currentCount = updatedReactions[reaction] ?? 0
        updatedReactions[reaction] = currentCount + 1

        listings[index].reactions = updatedReactions

        print("[BillExplorerViewModel] Reaction \(reaction.emoji) added to listing \(listingId)")
    }
}
