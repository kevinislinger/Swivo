import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    private let client: SupabaseClient
    private let baseURL: URL
    
    // Public access to client for realtime functionality
    var supabase: SupabaseClient {
        return client
    }

    private init() {
        // IMPORTANT: Replace with your actual Supabase URL and Anon Key
        let supabaseURL = URL(string: "https://rpexzovoebhnmvusjiug.supabase.co")!
        let supabaseKey = "sb_publishable_uUADlx_py43dMTqtrW1ttQ_qgv70j-4"

        self.baseURL = supabaseURL
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Authentication

    func signInAnonymouslyIfNeeded() async {
        do {
            // user() validates the token on the server
            _ = try await client.auth.user()
            print("User session is valid.")
        } catch {
            // If user() fails, it means no valid session exists.
            print("No valid user session found. Attempting to sign in anonymously.")
            do {
                // Proceed with anonymous sign-in
                _ = try await client.auth.signInAnonymously()
                print("Signed in anonymously successfully.")
            } catch {
                print("Error signing in anonymously: \(error)")
            }
        }
    }
}