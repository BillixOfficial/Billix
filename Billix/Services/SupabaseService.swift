import Foundation
import Supabase

/// Singleton service providing access to the Supabase client
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}
