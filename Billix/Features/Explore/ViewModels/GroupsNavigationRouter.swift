//
//  GroupsNavigationRouter.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Router to manage Groups tab navigation state independently of view lifecycle
//  Solves SwiftUI TabView + NavigationStack state reset issues
//

import SwiftUI

/// Router class that holds navigation state for Groups tab
/// Using @StateObject in parent ensures state survives TabView's view recreation
@MainActor
class GroupsNavigationRouter: ObservableObject {
    @Published var selectedGroup: CommunityGroup?
    @Published var navigationPath = NavigationPath()

    // Debounce flag to prevent "presentation in progress" errors
    private var isPresenting = false
    private var lastPresentTime: Date?

    // Debug flag
    private var debugEnabled = true

    func navigateTo(group: CommunityGroup) {
        // Debounce: prevent rapid presentations (must wait 500ms between presentations)
        if let lastTime = lastPresentTime, Date().timeIntervalSince(lastTime) < 0.5 {
            return
        }

        // Don't present if already presenting or animation in progress
        guard !isPresenting, selectedGroup == nil else {
            return
        }

        isPresenting = true
        lastPresentTime = Date()
        selectedGroup = group

        // Reset isPresenting after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isPresenting = false
        }
    }

    func popToRoot() {
        selectedGroup = nil
        navigationPath = NavigationPath()
    }

    func reset() {
        selectedGroup = nil
        navigationPath = NavigationPath()
    }
}
