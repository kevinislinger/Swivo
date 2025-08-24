import Foundation

struct SessionParticipant: Codable, Equatable {
    let sessionId: UUID
    let userId: UUID
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}
