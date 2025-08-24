import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var apnsToken: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case apnsToken = "apns_token"
        case createdAt = "created_at"
    }
    
    // Custom decoder initialization to handle ISO8601 date format from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode standard fields
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        apnsToken = try container.decodeIfPresent(String.self, forKey: .apnsToken)
        
        // Handle different date formats
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            // Create a date formatter for ISO8601 format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Fallback to simpler ISO format without fractional seconds
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: dateString) {
                    createdAt = date
                } else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .createdAt,
                        in: container,
                        debugDescription: "Date string does not match expected format"
                    )
                }
            }
        } else if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            // Handle timestamp format
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            // If all else fails, use current date
            print("Warning: Could not decode created_at date, using current date")
            createdAt = Date()
        }
    }
}
