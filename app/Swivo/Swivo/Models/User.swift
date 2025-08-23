import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: UUID
    var username: String
    var apnsToken: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case apnsToken = "apns_token"
        case createdAt = "created_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
