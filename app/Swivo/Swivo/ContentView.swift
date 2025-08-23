import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}

// Loading view displayed during authentication
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .padding()
        }
    }
}

// Authentication view (for demonstration, since we're using anonymous auth)
struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.left.arrow.right")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Welcome to Swivo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Help your group decide what to do next")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button(action: {
                Task {
                    await authService.signInAnonymously()
                }
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            if let error = authService.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// Main tab view after authentication
struct MainTabView: View {
    var body: some View {
        TabView {
            LandingView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            SettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

// Placeholder views for the different features
struct LandingView: View {
    var body: some View {
        Text("Landing View - Open Sessions")
            .navigationTitle("Sessions")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
            .navigationTitle("Profile")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(SessionService())
}