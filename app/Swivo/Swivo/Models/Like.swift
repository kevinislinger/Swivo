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
    
    // Custom decoder initialization to handle date format from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        optionId = try container.decode(UUID.self, forKey: .optionId)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        // Handle date
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: dateString) {
                    createdAt = date
                } else {
                    createdAt = Date()
                }
            }
        } else {
            createdAt = Date()
        }
    }
}
