import Foundation

enum OutgoingMessageType: String {
    case auth
}

enum IncomingMessageType: String, Codable {
    case auth_required
    case auth_ok
    case auth_invalid
}

struct BaseMessage: Codable {
    let type: IncomingMessageType
}

struct AuthMessage: Codable {
    var type: String = OutgoingMessageType.auth.rawValue
    let accessToken: String
    
    private enum CodingKeys: String, CodingKey {
        case type
        case accessToken = "access_token"
    }
}

struct AuthRequired: Codable {
    var type: String = IncomingMessageType.auth_required.rawValue
    let haVersion: String
    
    private enum CodingKeys: String, CodingKey {
        case type
        case haVersion = "ha_version"
    }
}

struct AuthOkMessage: Codable {
    var type: String = IncomingMessageType.auth_ok.rawValue
}

struct AuthInvalidMessage: Codable {
    var type: String = IncomingMessageType.auth_invalid.rawValue
    let message: String
}
