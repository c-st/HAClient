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

struct ListDevicesResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Device]

    struct Device: Codable {
        let id: String
        let name: String
        let nameByUser: String?
        let manufacturer: String
        let areaId: String?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case nameByUser = "name_by_user"
            case manufacturer
            case areaId = "area_id"
        }
    }
}

struct ListEntitiesResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Entity]

    struct Entity: Codable {
        let id: String
        let areaId: String?
        let deviceId: String?
        let platform: String
        
        private enum CodingKeys: String, CodingKey {
            case id = "entity_id"
            case areaId = "area_id"
            case deviceId = "device_id"
            case platform
        }
    }
}
