import Foundation

struct SwipeOption: Identifiable, Codable {
    var id: UUID
    var categoryId: UUID
    var label: String
    var imageURL: String?
    var createdAt: Date
    var orderIndex: Int? // Only present in session_options relationship
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case label
        case imageURL = "image_url"
        case createdAt = "created_at"
        case orderIndex = "order_index"
    }
}

struct Like: Identifiable, Codable {
    var id: UUID
    var sessionId: UUID
    var optionId: UUID
    var userId: UUID
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case optionId = "option_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
