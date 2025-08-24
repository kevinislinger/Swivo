import Foundation

struct SessionOption: Codable, Equatable {
    let sessionId: UUID
    let optionId: UUID
    let orderIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case optionId = "option_id"
        case orderIndex = "order_index"
    }
}
