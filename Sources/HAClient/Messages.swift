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

struct ListAreasMessage: Codable {
    var type: String = "config/area_registry/list"
    let id: Int
}

struct ListDevicesMessage: Codable {
    var type: String = "config/device_registry/list"
    let id: Int
}

struct ListEntitiesMessage: Codable {
    var type: String = "config/entity_registry/list"
    let id: Int
}

struct RequestCurrentStates: Codable {
    var type: String = "get_states"
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

enum CommandType {
    case listAreas
    case listDevices
    case listEntities
    case retrieveStates
}

public struct Area: Codable {
    let name: String
    let areaId: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case areaId = "area_id"
    }
}

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

public struct ListAreasResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Area]
}

struct ListDevicesResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Device]
}

struct ListEntitiesResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [Entity]

    
}

struct CurrentStatesResultMessage: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [State]

    struct State: Codable {
        let entityId: String
        let state: String

        private enum CodingKeys: String, CodingKey {
            case entityId = "entity_id"
            case state
        }
    }
}
