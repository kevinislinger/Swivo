//
//  ContentView.swift
//  Swivo
//
//  Created by Kevin on 19.08.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                if authService.isAuthenticated {
                    VStack(spacing: 16) {
                        Text("Authenticated")
                            .font(.headline)
                        
                        if let user = authService.currentUser {
                            Text("Username: \(user.username)")
                            Text("User ID: \(user.id.uuidString)")
                        } else {
                            Text("User data still loading...")
                        }
                        
                        Button("Sign Out") {
                            Task {
                                await authService.signOut()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Not authenticated")
                            .font(.headline)
                        
                        Button("Sign In Anonymously") {
                            Task {
                                await authService.signInAnonymously()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let error = authService.authError {
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Swivo")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
