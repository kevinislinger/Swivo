import SwiftUI

@main
struct SwivoApp: App {
    // Initialize services
    @StateObject private var authService = AuthService()
    @StateObject private var sessionService = SessionService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(sessionService)
                .task {
                    // If not authenticated, sign in anonymously
                    if !authService.isAuthenticated {
                        await authService.signInAnonymously()
                    }
                }
        }
    }
}