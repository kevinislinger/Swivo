import Foundation

enum SessionStatus: String, Codable {
    case open
    case matched
    case closed
}

struct Session: Identifiable, Codable {
    var id: UUID
    var creatorId: UUID
    var categoryId: UUID
    var quorumN: Int
    var status: SessionStatus
    var matchedOptionId: UUID?
    var inviteCode: String
    var createdAt: Date
    var matchedAt: Date?
    
    // Relationships
    var category: Category?
    var participants: [User]?
    var options: [SwipeOption]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case categoryId = "category_id"
        case quorumN = "quorum_n"
        case status
        case matchedOptionId = "matched_option_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
        case matchedAt = "matched_at"
        case category
        case participants
        case options
    }
    
    var participantCount: Int {
        participants?.count ?? 0
    }
    
    var isCreator: Bool {
        // This will need to be compared with the current user's ID in actual implementation
        false
    }
}
