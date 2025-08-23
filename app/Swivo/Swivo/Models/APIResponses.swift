import Foundation

// Response from create_session RPC function
struct CreateSessionResponse: Codable {
    let sessionId: UUID
    let inviteCode: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

// Response from join_session RPC function
struct JoinSessionResponse: Codable {
    let success: Bool
    let message: String?
    let sessionId: UUID?
    let matchedOptionId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case sessionId = "session_id"
        case matchedOptionId = "matched_option_id"
    }
}

// Response from like_option RPC function
struct LikeOptionResponse: Codable {
    let success: Bool
    let matchFound: Bool
    let matchedOptionId: UUID?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case matchFound = "match_found"
        case matchedOptionId = "matched_option_id"
        case message
    }
}
