import Foundation

struct Category: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let iconUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrl = "icon_url"
    }
}
