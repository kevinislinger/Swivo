import Foundation
import Supabase
import Combine

/// The main networking service that handles API requests to Supabase
class NetworkService {
    static let shared = NetworkService()
    
    private let supabase = SupabaseService.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Handles a Supabase response and decodes it to the expected type
    /// - Parameters:
    ///   - response: The PostgrestResponse from Supabase
    ///   - type: The expected type to decode to
    /// - Returns: Decoded object of type T
    /// - Throws: NetworkError if decoding fails
    private func handleResponse<T: Decodable>(_ response: PostgrestResponse<T>, as type: T.Type) throws -> T {
        // Verify the response status is valid
        guard response.status >= 200 && response.status < 300 else {
            throw NetworkError.serverError(statusCode: response.status, message: "Server returned error status: \(response.status)")
        }
        
        return response.value
    }
    
    /// Handles a Supabase response that returns an array and decodes it
    /// - Parameters:
    ///   - response: The PostgrestResponse from Supabase
    ///   - type: The expected array element type
    /// - Returns: Decoded array of type [T]
    /// - Throws: NetworkError if decoding fails
    private func handleArrayResponse<T: Decodable>(_ response: PostgrestResponse<[T]>, as type: [T].Type) throws -> [T] {
        // Verify the response status is valid
        guard response.status >= 200 && response.status < 300 else {
            throw NetworkError.serverError(statusCode: response.status, message: "Server returned error status: \(response.status)")
        }
        
        return response.value
    }
    
    /// Generic method to handle any error from a network request
    /// - Parameter error: The error that occurred
    /// - Returns: A standardized NetworkError
    private func handleError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        } else {
            return NetworkError.unknown(message: error.localizedDescription)
        }
    }
    
    // MARK: - Categories API
    
    /// Fetches all available categories
    /// - Returns: An array of Category objects
    /// - Throws: NetworkError if the request fails
    func fetchCategories() async throws -> [Category] {
        do {
            let response: PostgrestResponse<[Category]> = try await supabase.supabase
                .from("categories")
                .select()
                .order("name")
                .execute()
            
            return try handleArrayResponse(response, as: [Category].self)
        } catch {
            throw handleError(error)
        }
    }
    
    // MARK: - Sessions API
    
    /// Fetches open sessions for the current user
    /// - Returns: An array of Session objects
    /// - Throws: NetworkError if the request fails
    func fetchOpenSessions() async throws -> [Session] {
        do {
            // Ensure we have a user ID
            guard let userId = AuthService.shared.currentUser?.id else {
                throw NetworkError.unauthorized
            }
            
            // Query for sessions where:
            // 1. The user is a participant (joined via session_participants)
            // 2. The session status is 'open'
            let response: PostgrestResponse<[Session]> = try await supabase.supabase
                .from("sessions")
                .select("*, session_participants(*)")
                .eq("status", value: "open")
                .execute()
            
            let allSessions = try handleArrayResponse(response, as: [Session].self)
            
            // Filter to only include sessions where the user is a participant
            // This filtering should ideally be done on the server, but we're doing it here for simplicity
            return allSessions.filter { session in
                // Check if this user is a participant in this session
                if let participants = session.participants {
                    return participants.contains { $0.userId == userId }
                }
                return false
            }
        } catch {
            throw handleError(error)
        }
    }
    
    /// Fetches closed or matched sessions for the current user
    /// - Returns: An array of Session objects
    /// - Throws: NetworkError if the request fails
    func fetchClosedSessions() async throws -> [Session] {
        do {
            // Ensure we have a user ID
            guard let userId = AuthService.shared.currentUser?.id else {
                throw NetworkError.unauthorized
            }
            
            // Query for sessions where:
            // 1. The user is a participant
            // 2. The session status is 'matched' or 'closed'
            let response: PostgrestResponse<[Session]> = try await supabase.supabase
                .from("sessions")
                .select("*, session_participants(*)")
                .in("status", values: ["matched", "closed"])
                .execute()
            
            let allSessions = try handleArrayResponse(response, as: [Session].self)
            
            // Filter to only include sessions where the user is a participant
            return allSessions.filter { session in
                if let participants = session.participants {
                    return participants.contains { $0.userId == userId }
                }
                return false
            }
        } catch {
            throw handleError(error)
        }
    }
    
    // MARK: - Session Creation and Joining
    
    /// Creates a new session
    /// - Parameters:
    ///   - categoryId: The ID of the category for the session
    ///   - quorum: The number of agreements needed for a match
    /// - Returns: The created Session object with an invite code
    /// - Throws: NetworkError if the request fails
    func createSession(categoryId: UUID, quorum: Int) async throws -> Session {
        do {
            // Ensure we have a user ID
            guard let userId = AuthService.shared.currentUser?.id else {
                throw NetworkError.unauthorized
            }
            
            // Create the session using RPC (Remote Procedure Call)
            // This will create the session, generate an invite code, and add the creator as a participant
            let response: PostgrestResponse<Session> = try await supabase.supabase
                .rpc("create_session", params: [
                    "p_category_id": categoryId.uuidString,
                    "p_creator_id": userId.uuidString,
                    "p_quorum_n": String(quorum)
                ])
                .execute()
            
            return try handleResponse(response, as: Session.self)
        } catch {
            throw handleError(error)
        }
    }
    
    /// Joins an existing session using an invite code
    /// - Parameter inviteCode: The invitation code for the session
    /// - Returns: The joined Session object
    /// - Throws: NetworkError if the request fails
    func joinSession(inviteCode: String) async throws -> Session {
        do {
            // Ensure we have a user ID
            guard let userId = AuthService.shared.currentUser?.id else {
                throw NetworkError.unauthorized
            }
            
            // First, find the session with this invite code
            let findResponse: PostgrestResponse<[Session]> = try await supabase.supabase
                .from("sessions")
                .select()
                .eq("invite_code", value: inviteCode)
                .limit(1)
                .execute()
            
            let sessions = try handleArrayResponse(findResponse, as: [Session].self)
            guard let session = sessions.first else {
                throw NetworkError.notFound(message: "No session found with this invite code")
            }
            
            // Check if the session is open
            guard session.status == "open" else {
                if session.status == "matched" {
                    throw NetworkError.sessionAlreadyMatched
                } else {
                    throw NetworkError.sessionClosed
                }
            }
            
            // Join the session by inserting into session_participants
            let joinResponse = try await supabase.supabase
                .from("session_participants")
                .insert([
                    "session_id": session.id.uuidString,
                    "user_id": userId.uuidString
                ])
                .execute()
            
            guard joinResponse.status >= 200 && joinResponse.status < 300 else {
                if joinResponse.status == 409 {
                    throw NetworkError.alreadyJoined
                } else {
                    throw NetworkError.serverError(statusCode: joinResponse.status, message: "Failed to join session")
                }
            }
            
            // Fetch the full session details after joining
            return try await getSession(id: session.id)
        } catch {
            throw handleError(error)
        }
    }
    
    /// Gets a specific session by ID
    /// - Parameter id: The session ID
    /// - Returns: The Session object
    /// - Throws: NetworkError if the request fails
    func getSession(id: UUID) async throws -> Session {
        do {
            let response: PostgrestResponse<Session> = try await supabase.supabase
                .from("sessions")
                .select("*, session_participants(*)")
                .eq("id", value: id.uuidString)
                .single()
                .execute()
            
            return try handleResponse(response, as: Session.self)
        } catch {
            throw handleError(error)
        }
    }
    
    // MARK: - Options API
    
    /// Fetches options for a specific session
    /// - Parameter sessionId: The session ID
    /// - Returns: An array of options for the session
    /// - Throws: NetworkError if the request fails
    func fetchSessionOptions(sessionId: UUID) async throws -> [Option] {
        do {
            // Join session_options and options tables to get all options for this session
            let response: PostgrestResponse<[Option]> = try await supabase.supabase
                .from("session_options")
                .select("options(*)")
                .eq("session_id", value: sessionId.uuidString)
                .execute()
            
            // Extract options from the nested response
            return try handleArrayResponse(response, as: [Option].self)
        } catch {
            throw handleError(error)
        }
    }
    
    /// Submits a like for an option in a session
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - optionId: The option ID that was liked
    /// - Returns: True if this like resulted in a match, false otherwise
    /// - Throws: NetworkError if the request fails
    func likeOption(sessionId: UUID, optionId: UUID) async throws -> (matchFound: Bool, matchedOptionId: UUID?) {
        do {
            // Ensure we have a user ID
            guard let userId = AuthService.shared.currentUser?.id else {
                throw NetworkError.unauthorized
            }
            
            // Instead of using the Edge Function directly, use the database API to insert a like
            // This will trigger the database function that handles the matching logic
            
            // Create a proper Encodable struct for the insert
            struct LikeInsert: Encodable {
                let session_id: String
                let option_id: String
                let user_id: String
            }
            
            // Create a Like object using our Encodable struct
            let like = LikeInsert(
                session_id: sessionId.uuidString,
                option_id: optionId.uuidString,
                user_id: userId.uuidString
            )
            
            // Insert the like into the database
            let insertResponse = try await supabase.supabase.from("likes")
                .insert(like)
                .execute()
            
            // Check if insertion was successful
            guard insertResponse.status >= 200 && insertResponse.status < 300 else {
                throw NetworkError.serverError(statusCode: insertResponse.status, message: "Failed to record like")
            }
            
            // After inserting the like, check if there's a match by querying the session
            let sessionResponse: PostgrestResponse<Session> = try await supabase.supabase.from("sessions")
                .select()
                .eq("id", value: sessionId.uuidString)
                .single()
                .execute()
            
            let session = sessionResponse.value
            
            // If the session status is now "matched", then we have a match
            let matchFound = session.status == "matched"
            
            return (matchFound, session.matchedOptionId)
        } catch {
            throw handleError(error)
        }
    }
}

// MARK: - Error Type

/// Custom error type for networking errors
enum NetworkError: Error, LocalizedError {
    case unauthorized
    case notFound(message: String)
    case serverError(statusCode: Int, message: String)
    case decodingError(message: String)
    case unknown(message: String)
    case sessionClosed
    case sessionAlreadyMatched
    case alreadyJoined
    case sessionFull
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You need to be signed in to perform this action"
        case .notFound(let message):
            return message
        case .serverError(_, let message):
            return message
        case .decodingError(let message):
            return "Failed to parse the server response: \(message)"
        case .unknown(let message):
            return message
        case .sessionClosed:
            return "This session has been closed"
        case .sessionAlreadyMatched:
            return "This session already has a match"
        case .alreadyJoined:
            return "You have already joined this session"
        case .sessionFull:
            return "This session is full"
        }
    }
}
