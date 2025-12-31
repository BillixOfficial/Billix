import Foundation
import Supabase
import Auth

/// Singleton service providing access to the Supabase client
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    /// Returns the current authenticated user's ID, if available
    var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }
}
