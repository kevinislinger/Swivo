import Foundation
import Supabase
import Combine

/// Service responsible for managing authentication state and operations
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let supabase = SupabaseService.shared
    
    /// Published property to track authentication state
    @Published private(set) var isAuthenticated = false
    
    /// The current user
    @Published private(set) var currentUser: User?
    
    /// Authentication error state
    @Published private(set) var authError: Error?
    
    private init() {
        // Check for existing session at launch
        Task {
            await checkSession()
        }
    }
    
    /// Checks if there's a valid session and updates authentication state
    @MainActor
    func checkSession() async {
        // Check if user is already signed in
        if let session = try? await supabase.supabase.auth.session, session.isExpired == false {
            isAuthenticated = true
            await fetchCurrentUser()
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    /// Signs in anonymously and updates authentication state
    @MainActor
    func signInAnonymously() async {
        do {
            // Use the existing method from SupabaseService but mark as throwing
            try await supabase.signInAnonymouslyIfNeeded()
            
            // Update authentication state
            isAuthenticated = true
            
            // Fetch user details
            await fetchCurrentUser()
            
        } catch {
            isAuthenticated = false
            currentUser = nil
            authError = error
            print("Error signing in anonymously: \(error)")
        }
    }
    
    /// Signs out the current user
    @MainActor
    func signOut() async {
        do {
            try await supabase.supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            authError = error
            print("Error signing out: \(error)")
        }
    }
    
    /// Fetches the current user's profile from the database
    @MainActor
    private func fetchCurrentUser() async {
        do {
            guard let authUser = try? await supabase.supabase.auth.user() else {
                print("No authenticated user found")
                return
            }
            
            // Fetch the user profile from the database using the auth user's ID
            let response = try await supabase.supabase.from("users")
                .select()
                .eq("id", value: authUser.id)
                .single()
                .execute()
                
            // Handle the response data and decode manually
            do {
                let data = response.data
                if !data.isEmpty {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    self.currentUser = user
                } else {
                    print("No user data returned from the database")
                }
            } catch {
                print("Failed to decode user data: \(error)")
            }
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }
    
    /// Updates the username for the current user
    @MainActor
    func updateUsername(_ username: String) async -> Bool {
        guard isAuthenticated, let userId = currentUser?.id else {
            return false
        }
        
        do {
            struct UpdatePayload: Codable {
                let username: String
            }
            
            let payload = UpdatePayload(username: username)
            
            let response = try await supabase.supabase.from("users")
                .update(payload)
                .eq("id", value: userId)
                .execute()
            
            if response.status == 200 || response.status == 201 {
                // Update local user object
                var updatedUser = currentUser
                updatedUser?.username = username
                currentUser = updatedUser
                return true
            }
            return false
        } catch {
            print("Error updating username: \(error)")
            return false
        }
    }
    
    /// Updates the APNS token for push notifications
    @MainActor
    func updateAPNSToken(_ token: String?) async {
        guard isAuthenticated, let userId = currentUser?.id else {
            return
        }
        
        do {
            // Create a proper Codable payload
            struct TokenPayload: Codable {
                let apns_token: String?
            }
            
            let payload = TokenPayload(apns_token: token)
            
            _ = try await supabase.supabase.from("users")
                .update(payload)
                .eq("id", value: userId)
                .execute()
            
            // Update local user object
            var updatedUser = currentUser
            updatedUser?.apnsToken = token
            currentUser = updatedUser
        } catch {
            print("Error updating APNS token: \(error)")
        }
    }
}
