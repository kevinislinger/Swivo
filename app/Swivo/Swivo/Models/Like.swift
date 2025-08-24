import Foundation

struct Like: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionId: UUID
    let optionId: UUID
    let userId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case optionId = "option_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
