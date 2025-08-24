//
//  SwivoApp.swift
//  Swivo
//
//  Created by Kevin on 19.08.25.
//

import SwiftUI

@main
struct SwivoApp: App {
    // Create an environment object for the AuthService
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Perform initial setup
        Task {
            // Attempt to sign in anonymously if needed when the app launches
            await AuthService.shared.signInAnonymously()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}