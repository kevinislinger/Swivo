import Foundation
import Combine
import SwiftUI

/// Service responsible for managing session state and operations
class SessionService: ObservableObject {
    static let shared = SessionService()
    
    private let networkService = NetworkService.shared
    private let authService = AuthService.shared
    
    // MARK: - Published Properties
    
    /// Currently active session (being viewed or swiped)
    @Published private(set) var currentSession: Session?
    
    /// List of open sessions the user is participating in
    @Published private(set) var openSessions: [Session] = []
    
    /// List of closed or matched sessions the user has participated in
    @Published private(set) var closedSessions: [Session] = []
    
    /// Available categories for creating new sessions
    @Published private(set) var categories: [Category] = []
    
    /// Options for the current session
    @Published private(set) var sessionOptions: [Option] = []
    
    /// Loading state
    @Published private(set) var isLoading = false
    
    /// Error state
    @Published private(set) var error: Error?
    
    /// Refresh timer for automatically refreshing open sessions
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        // Start a timer to refresh open sessions every 30 seconds
        startRefreshTimer()
    }
    
    deinit {
        stopRefreshTimer()
    }
    
    // MARK: - Session Loading
    
    /// Refreshes the list of open sessions
    /// - Returns: Success or failure
    @MainActor
    @discardableResult
    func refreshOpenSessions() async -> Bool {
        isLoading = true
        error = nil
        
        do {
            openSessions = try await networkService.fetchOpenSessions()
            isLoading = false
            return true
        } catch {
            self.error = error
            isLoading = false
            print("Error refreshing open sessions: \(error)")
            return false
        }
    }
    
    /// Refreshes the list of closed sessions
    /// - Returns: Success or failure
    @MainActor
    @discardableResult
    func refreshClosedSessions() async -> Bool {
        isLoading = true
        error = nil
        
        do {
            closedSessions = try await networkService.fetchClosedSessions()
            isLoading = false
            return true
        } catch {
            self.error = error
            isLoading = false
            print("Error refreshing closed sessions: \(error)")
            return false
        }
    }
    
    /// Loads categories for creating new sessions
    /// - Returns: Success or failure
    @MainActor
    @discardableResult
    func loadCategories() async -> Bool {
        isLoading = true
        error = nil
        
        do {
            categories = try await networkService.fetchCategories()
            isLoading = false
            return true
        } catch {
            self.error = error
            isLoading = false
            print("Error loading categories: \(error)")
            return false
        }
    }
    
    // MARK: - Session Management
    
    /// Creates a new session
    /// - Parameters:
    ///   - categoryId: The category ID for this session
    ///   - quorum: Number of participants needed for a match
    /// - Returns: The created session if successful
    @MainActor
    func createSession(categoryId: UUID, quorum: Int) async -> Session? {
        isLoading = true
        error = nil
        
        do {
            let session = try await networkService.createSession(categoryId: categoryId, quorum: quorum)
            currentSession = session
            
            // Refresh the open sessions list to include the new session
            _ = await refreshOpenSessions()
            
            // Load options for this session
            await loadOptionsForCurrentSession()
            
            isLoading = false
            return session
        } catch {
            self.error = error
            isLoading = false
            print("Error creating session: \(error)")
            return nil
        }
    }
    
    /// Joins a session using an invite code
    /// - Parameter inviteCode: The invitation code for the session
    /// - Returns: The joined session if successful
    @MainActor
    func joinSession(inviteCode: String) async -> Session? {
        isLoading = true
        error = nil
        
        do {
            let session = try await networkService.joinSession(inviteCode: inviteCode)
            currentSession = session
            
            // Refresh the open sessions list to include the joined session
            _ = await refreshOpenSessions()
            
            // Load options for this session
            await loadOptionsForCurrentSession()
            
            isLoading = false
            return session
        } catch {
            self.error = error
            isLoading = false
            print("Error joining session: \(error)")
            return nil
        }
    }
    
    /// Loads options for the current session
    @MainActor
    func loadOptionsForCurrentSession() async {
        guard let currentSession = currentSession else {
            sessionOptions = []
            return
        }
        
        do {
            sessionOptions = try await networkService.fetchSessionOptions(sessionId: currentSession.id)
        } catch {
            self.error = error
            print("Error loading session options: \(error)")
            sessionOptions = []
        }
    }
    
    /// Submits a like for an option in the current session
    /// - Parameter optionId: The option that was liked
    /// - Returns: Tuple containing (matchFound, matchedOptionId)
    @MainActor
    func likeOption(optionId: UUID) async -> (matchFound: Bool, matchedOptionId: UUID?) {
        guard let currentSession = currentSession else {
            return (false, nil)
        }
        
        do {
            let result = try await networkService.likeOption(sessionId: currentSession.id, optionId: optionId)
            
            // If a match was found, update the current session
            if result.matchFound {
                await refreshCurrentSession()
                
                // Also refresh the open/closed session lists
                await refreshOpenSessions()
                await refreshClosedSessions()
            }
            
            return result
        } catch {
            self.error = error
            print("Error liking option: \(error)")
            return (false, nil)
        }
    }
    
    /// Refreshes the current session data
    @MainActor
    func refreshCurrentSession() async {
        guard let sessionId = currentSession?.id else { return }
        
        do {
            currentSession = try await networkService.getSession(id: sessionId)
        } catch {
            self.error = error
            print("Error refreshing current session: \(error)")
        }
    }
    
    /// Sets a session as the current session
    /// - Parameter session: The session to set as current
    @MainActor
    func setCurrentSession(_ session: Session) {
        currentSession = session
        
        // Load options for this session
        Task {
            await loadOptionsForCurrentSession()
        }
    }
    
    /// Clears the current session
    func clearCurrentSession() {
        currentSession = nil
        sessionOptions = []
    }
    
    // MARK: - Helper Methods
    
    /// Starts the refresh timer to periodically update open sessions
    private func startRefreshTimer() {
        stopRefreshTimer()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                await self.refreshOpenSessions()
                
                // Also refresh the current session if one is active
                if self.currentSession != nil {
                    await self.refreshCurrentSession()
                }
            }
        }
    }
    
    /// Stops the refresh timer
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
