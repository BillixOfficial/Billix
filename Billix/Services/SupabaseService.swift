import Foundation
import Supabase

/// Singleton service providing access to the Supabase client
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Convenience Accessors

    var database: PostgrestClient {
        client.database
    }

    var auth: AuthClient {
        client.auth
    }

    var storage: SupabaseStorageClient {
        client.storage
    }
}
