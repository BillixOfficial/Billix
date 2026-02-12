import Foundation
import Supabase
import Auth

/// Singleton service providing access to the Supabase client
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // Configure custom JSON decoder for date handling
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds and timezone (for created_at, etc.)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try simple date format (YYYY-MM-DD) for active_date columns
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(dateString)"
            )
        }

        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    decoder: decoder
                ),
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

    // MARK: - Profile Methods

    /// Fetch a user's profile by their user ID
    func fetchProfile(for userId: UUID) async throws -> BillixProfile {
        let profile: BillixProfile = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }
}
