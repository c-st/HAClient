import Foundation

// MARK: Outgoing messages

struct AuthMessage: Codable {
    var type: String = "auth"
    let accessToken: String

    private enum CodingKeys: String, CodingKey {
        case type
        case accessToken = "access_token"
    }
}

struct RequestAreaRegistry: Codable {
    var type: String = "config/area_registry/list"
    let id: Int
}

struct RequestDeviceRegistry: Codable {
    var type: String = "config/device_registry/list"
    let id: Int
}

struct RequestEntityRegistry: Codable {
    var type: String = "config/entity_registry/list"
    let id: Int
}

// MARK: Incoming messages

struct BaseMessage: Codable {
    let type: IncomingMessageType
}

enum IncomingMessageType: String, Codable {
    case auth_required
    case auth_ok
    case auth_invalid
    case result
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

struct BaseResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
}

// MARK: Result payloads

enum ResultType {
    case listAreas
    case listDevices
    case listEntities
}

struct ListAreasResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Area]

    struct Area: Codable {
        let name: String
        let areaId: String

        private enum CodingKeys: String, CodingKey {
            case name
            case areaId = "area_id"
        }
    }
}
