//
//  BillixApp.swift
//  Billix
//
//  Created by Falana on 11/15/25.
//

import SwiftUI
import SwiftData

@main
struct BillixApp: App {
    @StateObject private var authService = AuthService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StoredBill.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var authService: AuthService

    /// Combined state for cleaner animation transitions
    private var viewState: ViewState {
        if authService.isLoading {
            return .loading
        } else if authService.awaitingEmailVerification {
            return .emailVerification
        } else if !authService.isAuthenticated {
            return .login
        } else if authService.needsOnboarding {
            return .onboarding
        } else {
            return .main
        }
    }

    private enum ViewState: Equatable {
        case loading
        case login
        case emailVerification
        case onboarding
        case main
    }

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                SplashView()
            case .login:
                LoginView()
            case .emailVerification:
                // TODO: Re-enable after adding EmailVerificationView.swift to Xcode target
                LoginView()  // Temporary fallback
                // EmailVerificationView()
            case .onboarding:
                NavigationStack {
                    OnboardingView()
                }
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewState)
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            // Cream background to match logo
            Color(hex: "#EFDCBB")
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Billix Logo - larger size
                Image("billix_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#2D5A5E")))
                    .scaleEffect(1.3)
            }
        }
    }
}
