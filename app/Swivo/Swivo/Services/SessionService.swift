import Foundation
import Supabase
import Combine

class SessionService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var openSessions: [Session] = []
    @Published var closedSessions: [Session] = []
    @Published var currentSession: Session?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(supabase: SupabaseClient = SupabaseClient.shared.client) {
        self.supabase = supabase
    }
    
    @MainActor
    func fetchOpenSessions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabase.from("sessions")
                .select("""
                    id,
                    creator_id,
                    category_id,
                    quorum_n,
                    status,
                    matched_option_id,
                    invite_code,
                    created_at,
                    matched_at,
                    categories!inner(id, name, icon_url)
                """)
                .eq("status", value: "open")
                .order("created_at", ascending: false)
                .execute()
            
            self.openSessions = try response.value.decode(to: [Session].self)
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    func fetchClosedSessions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabase.from("sessions")
                .select("""
                    id,
                    creator_id,
                    category_id,
                    quorum_n,
                    status,
                    matched_option_id,
                    invite_code,
                    created_at,
                    matched_at,
                    categories!inner(id, name, icon_url)
                """)
                .in("status", values: ["matched", "closed"])
                .order("created_at", ascending: false)
                .execute()
            
            self.closedSessions = try response.value.decode(to: [Session].self)
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    func createSession(categoryId: UUID, quorumN: Int) async throws -> Session {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call the create_session RPC function
            let response = try await supabase.rpc(
                fn: "create_session",
                params: [
                    "p_category_id": categoryId.uuidString,
                    "p_quorum_n": quorumN
                ]
            ).execute()
            
            let createResponse = try response.value.decode(to: CreateSessionResponse.self)
            
            // Fetch the full session details
            return try await getSession(id: createResponse.sessionId)
        } catch {
            self.error = error
            throw error
        }
    }
    
    @MainActor
    func joinSession(inviteCode: String) async throws -> JoinSessionResponse {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call the join_session RPC function
            let response = try await supabase.rpc(
                fn: "join_session",
                params: ["p_invite_code": inviteCode]
            ).execute()
            
            let joinResponse = try response.value.decode(to: JoinSessionResponse.self)
            
            // If join was successful, fetch the session details
            if joinResponse.success, let sessionId = joinResponse.sessionId {
                currentSession = try await getSession(id: sessionId)
            }
            
            return joinResponse
        } catch {
            self.error = error
            throw error
        }
    }
    
    @MainActor
    func getSession(id: UUID) async throws -> Session {
        let response = try await supabase.from("sessions")
            .select("""
                id,
                creator_id,
                category_id,
                quorum_n,
                status,
                matched_option_id,
                invite_code,
                created_at,
                matched_at,
                categories!inner(id, name, icon_url)
            """)
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        return try response.value.decode(to: Session.self)
    }
    
    @MainActor
    func getSessionOptions(sessionId: UUID) async throws -> [SwipeOption] {
        let response = try await supabase.from("session_options")
            .select("""
                session_id,
                options!inner(
                    id,
                    category_id,
                    label,
                    image_url,
                    created_at
                ),
                order_index
            """)
            .eq("session_id", value: sessionId.uuidString)
            .order("order_index")
            .execute()
        
        struct SessionOption: Codable {
            let options: SwipeOption
            let orderIndex: Int
            
            enum CodingKeys: String, CodingKey {
                case options
                case orderIndex = "order_index"
            }
        }
        
        // Parse the nested response and map to SwipeOption objects
        let sessionOptions = try response.value.decode(to: [SessionOption].self)
        return sessionOptions.map { 
            var option = $0.options
            option.orderIndex = $0.orderIndex
            return option
        }
    }
    
    @MainActor
    func likeOption(sessionId: UUID, optionId: UUID) async throws -> LikeOptionResponse {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call the like_option RPC function
            let response = try await supabase.rpc(
                fn: "like_option",
                params: [
                    "p_session_id": sessionId.uuidString,
                    "p_option_id": optionId.uuidString
                ]
            ).execute()
            
            return try response.value.decode(to: LikeOptionResponse.self)
        } catch {
            self.error = error
            throw error
        }
    }
    
    @MainActor
    func closeSession(sessionId: UUID) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call the close_session RPC function
            let response = try await supabase.rpc(
                fn: "close_session",
                params: ["p_session_id": sessionId.uuidString]
            ).execute()
            
            return try response.value.decode(to: Bool.self)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // Subscriptions for real-time updates could be added here
}
