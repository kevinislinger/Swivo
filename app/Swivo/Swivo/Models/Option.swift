import Foundation

struct Option: Codable, Identifiable, Equatable {
    let id: UUID
    let categoryId: UUID
    let label: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case label
        case imageUrl = "image_url"
    }
}
