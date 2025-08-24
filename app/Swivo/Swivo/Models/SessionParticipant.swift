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
    
    // Custom decoder initialization to handle date format from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        // Handle date
        if let dateString = try? container.decode(String.self, forKey: .joinedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                joinedAt = date
            } else {
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: dateString) {
                    joinedAt = date
                } else {
                    joinedAt = Date()
                }
            }
        } else {
            joinedAt = Date()
        }
    }
}
