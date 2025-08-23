import Foundation
import Supabase
import Combine

class AuthService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    init(supabase: SupabaseClient = SupabaseClient.shared.client) {
        self.supabase = supabase
        
        // Check for existing session
        Task {
            await checkSession()
        }
    }
    
    @MainActor
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to get session
            let session = try await supabase.auth.session
            // If we have a session, get user details
            if session != nil {
                try await fetchUserDetails()
                isAuthenticated = true
            } else {
                isAuthenticated = false
                currentUser = nil
            }
        } catch {
            self.error = error
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    @MainActor
    func signInAnonymously() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sign in anonymously
            let authResponse = try await supabase.auth.signInAnonymously()
            
            // Get user details
            try await fetchUserDetails()
            
            isAuthenticated = true
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    private func fetchUserDetails() async throws {
        // Get the currently logged in user's ID
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        // Fetch user details from the database
        let response = try await supabase.from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        currentUser = try response.value.decode(to: User.self)
    }
    
    @MainActor
    func updateUsername(_ username: String) async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "AuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Update username in the database
        let response = try await supabase.from("users")
            .update(["username": username])
            .eq("id", value: userId)
            .single()
            .execute()
        
        // Refresh user details
        try await fetchUserDetails()
    }
}
