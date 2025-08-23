import Foundation
import Supabase

/// Singleton for managing Supabase client configuration
class SupabaseClient {
    static let shared = SupabaseClient()
    
    private(set) lazy var client: SupabaseClient = {
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_API_KEY"] ?? Bundle.main.infoDictionary?["SUPABASE_API_KEY"] as? String,
              !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            fatalError("Supabase URL and API key must be set")
        }
        
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }()
    
    private init() {}
}
