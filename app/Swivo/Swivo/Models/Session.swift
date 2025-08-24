import Foundation

enum SessionStatus: String, Codable {
    case open
    case matched
    case closed
}

struct Session: Codable, Identifiable, Equatable {
    let id: UUID
    let creatorId: UUID
    let categoryId: UUID
    let quorumN: Int
    var status: SessionStatus
    var matchedOptionId: UUID?
    let inviteCode: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case categoryId = "category_id"
        case quorumN = "quorum_n"
        case status
        case matchedOptionId = "matched_option_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}
