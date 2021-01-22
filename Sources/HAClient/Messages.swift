import Foundation

enum OutgoingMessageType: String {
    case auth
}

struct AuthMessage: Codable {
    var type: String = OutgoingMessageType.auth.rawValue
    let accessToken: String
    
    private enum CodingKeys: String, CodingKey {
        case type
        case accessToken = "access_token"
    }
}
