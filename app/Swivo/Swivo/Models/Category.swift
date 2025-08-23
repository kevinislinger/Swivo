import Foundation

struct Category: Identifiable, Codable {
    var id: UUID
    var name: String
    var iconURL: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconURL = "icon_url"
        case createdAt = "created_at"
    }
}
