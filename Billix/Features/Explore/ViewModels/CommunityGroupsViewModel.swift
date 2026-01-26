//
//  CommunityGroupsViewModel.swift
//  Billix
//
//  Created by Claude Code on 1/25/26.
//  ViewModel for Community Groups with Supabase backend
//

import Foundation
import Combine

@MainActor
class CommunityGroupsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var groups: [CommunityGroup] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Computed Properties

    var joinedGroups: [CommunityGroup] {
        groups.filter { $0.isJoined }
    }

    // MARK: - Private Properties
    private let service: CommunityServiceProtocol

    // MARK: - Initialization

    init(service: CommunityServiceProtocol? = nil) {
        self.service = service ?? CommunityService.shared
    }

    // MARK: - Public Methods

    /// Load all groups
    func loadGroups() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            groups = try await service.fetchGroups()
        } catch {
            self.error = error.localizedDescription
            // Fall back to mock data if fetch fails
            groups = CommunityGroup.mockGroups
        }

        isLoading = false
    }

    /// Refresh groups
    func refreshGroups() async {
        CommunityService.shared.clearCache()
        await loadGroups()
    }

    // MARK: - Group Actions

    /// Toggle join/leave for a group (optimistic update)
    func toggleJoin(for group: CommunityGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }

        // Optimistic update
        let wasJoined = groups[index].isJoined
        groups[index].isJoined.toggle()

        // Sync with backend
        Task {
            do {
                if wasJoined {
                    try await service.leaveGroup(id: group.id)
                } else {
                    try await service.joinGroup(id: group.id)
                }
            } catch {
                // Revert on failure
                if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                    groups[idx].isJoined = wasJoined
                }
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Filtering

    /// Filter groups by search text (client-side)
    func filteredGroups(searchText: String) -> [CommunityGroup] {
        guard !searchText.isEmpty else { return groups }

        return groups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}
