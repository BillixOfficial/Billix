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

    var body: some View {
        Group {
            if authService.isLoading {
                SplashView()
            } else if !authService.isAuthenticated {
                LoginView()
            } else if authService.needsOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authService.needsOnboarding)
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
