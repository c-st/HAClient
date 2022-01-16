import Foundation

// MARK: Outgoing messages

// See https://developers.home-assistant.io/docs/api/websocket/

enum CommandType: String, Codable {
    case listAreas = "config/area_registry/list"
    case listDevices = "config/device_registry/list"
    case listEntities = "config/entity_registry/list"
    case retrieveStates = "get_states"
}

struct Message: Codable {
    let type: CommandType
    let id: Int
}

struct AuthMessage: Codable {
    var type: String = "auth"
    let accessToken: String

    private enum CodingKeys: String, CodingKey {
        case type
        case accessToken = "access_token"
    }
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

struct ResultMessage<T: Codable>: Codable {
    var type: String = IncomingMessageType.result.rawValue
    let id: Int
    let success: Bool
    let result: [T]
}

public struct Area: Codable {
    let name: String
    let areaId: String
    var picture: String? = nil
    
    private enum CodingKeys: String, CodingKey {
        case name
        case areaId = "area_id"
        case picture
    }
}

public struct Device: Codable {
    let id: String
    var areaId: String? = nil
    let name: String
    var nameByUser: String? = nil
    var entryType: String? = nil
    var manufacturer: String? = nil
    var model: String? = nil
    var swVersion: String? = nil
    var viaDeviceId: String? = nil

    private enum CodingKeys: String, CodingKey {
        case id
        case areaId = "area_id"
        case name
        case nameByUser = "name_by_user"
        case entryType = "entry_type"
        case manufacturer
        case model
        case swVersion = "sw_version"
        case viaDeviceId = "via_device_id"
    }
}

public struct Entity: Codable {
    let entityId: String
    var areaId: String? = nil
    var name: String? = nil
    var icon: String? = nil
    var deviceId: String? = nil
    let platform: String

    private enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case areaId = "area_id"
        case name
        case icon
        case deviceId = "device_id"
        case platform
    }
}

public struct State: Codable {
    let entityId: String
    let state: String
    var lastChanged: String? = nil
    var lastUpdated: String? = nil
    var attributes: [String:JSONProperty]? = nil

    private enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
        case attributes
    }
}
