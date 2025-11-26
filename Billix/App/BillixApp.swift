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
            LinearGradient(
                colors: [Color(hex: "1B4332"), Color(hex: "2D6A4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo or app icon
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("Billix")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
    }
}
