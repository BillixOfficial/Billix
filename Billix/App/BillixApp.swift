//
//  BillixApp.swift
//  Billix
//
//  Created by Falana on 11/15/25.
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await NotificationService.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

@main
struct BillixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authService = AuthService.shared
    @StateObject private var streakService = StreakService.shared
    @StateObject private var tasksViewModel = TasksViewModel.shared
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StoredBill.self,
            StoredChatSession.self,
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
                .environmentObject(notificationService)
                .onOpenURL { url in
                    // Handle deep links (OAuth callbacks and password reset)
                    Task {
                        // Check if this is a password reset link
                        if url.absoluteString.contains("type=recovery") {
                            authService.isResettingPassword = true
                        }
                        await handleOAuthCallback(url)
                    }
                }
                .task {
                    // Check notification permission status on launch
                    await notificationService.checkPermissionStatus()

                    // Cleanup expired chat sessions
                    cleanupExpiredChatSessions(context: sharedModelContainer.mainContext)
                }
                .onChange(of: authService.isAuthenticated) { wasAuthenticated, isAuthenticated in
                    Task {
                        if isAuthenticated {
                            // Subscribe to realtime swap updates when user logs in
                            await notificationService.subscribeToSwapUpdates()

                            // Sync subscription status from StoreKit to Supabase
                            await SubscriptionSyncService.shared.syncSubscriptionStatus()

                            // Verify membership with both StoreKit and Supabase
                            await StoreKitService.shared.verifyMembershipWithSupabase()
                        } else {
                            // Unsubscribe and remove device token when user logs out
                            await notificationService.unsubscribeFromSwapUpdates()
                            await notificationService.removeDeviceToken()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Fetch streak when app becomes active
                Task {
                    try? await streakService.fetchStreak()
                }
            }
        }
    }

    // MARK: - OAuth Callback Handler

    /// Handle OAuth callback URLs from social sign-in providers (Google, Facebook)
    private func handleOAuthCallback(_ url: URL) async {
        do {
            // Supabase processes the OAuth callback and establishes the session
            // The auth state listener in AuthService will automatically pick up the new session
            try await SupabaseService.shared.client.auth.session(from: url)
        } catch {
            print("OAuth callback error: \(error.localizedDescription)")
        }
    }

    // MARK: - Chat Session Cleanup

    /// Deletes expired chat sessions (older than 7 days)
    private func cleanupExpiredChatSessions(context: ModelContext) {
        let now = Date()
        let descriptor = FetchDescriptor<StoredChatSession>(
            predicate: #Predicate<StoredChatSession> { session in
                session.expiresAt < now
            }
        )

        do {
            let expired = try context.fetch(descriptor)
            if !expired.isEmpty {
                print("Cleaning up \(expired.count) expired chat session(s)")
                expired.forEach { context.delete($0) }
                try context.save()
            }
        } catch {
            print("Failed to cleanup expired chat sessions: \(error)")
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var authService: AuthService

    /// Combined state for cleaner animation transitions
    private var viewState: ViewState {
        if authService.isLoading {
            return .loading
        } else if authService.isResettingPassword {
            // Password reset flow - user clicked reset link in email
            return .resetPassword
        } else if authService.awaitingEmailVerification {
            return .emailVerification
        } else if !authService.isAuthenticated {
            return .login
        } else if authService.isGuestMode {
            // Guest users skip onboarding and go straight to main app
            return .main
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
        case resetPassword
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
            case .resetPassword:
                SetNewPasswordView()
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
