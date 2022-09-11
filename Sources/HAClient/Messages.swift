import Foundation

// MARK: Outgoing messages

// See https://developers.home-assistant.io/docs/api/websocket/

enum CommandType: String, Codable {
    case ping = "ping"
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
    case pong
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

struct PongMessage: Codable {
    var type: String = IncomingMessageType.pong.rawValue
    let id: Int
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
    public let name: String
    public let areaId: String
    public var picture: String? = nil
    
    public init(name: String, areaId: String, picture: String? = nil) {
        self.name = name
        self.areaId = areaId
        self.picture = picture
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case areaId = "area_id"
        case picture
    }
}

public struct Device: Codable {
    public let id: String
    public var areaId: String? = nil
    public let name: String
    public var nameByUser: String? = nil
    public var entryType: String? = nil
    public var manufacturer: String? = nil
    public var model: String? = nil
    public var swVersion: String? = nil
    public var viaDeviceId: String? = nil
    
    public init(id: String, areaId: String? = nil, name: String, nameByUser: String? = nil, entryType: String? = nil, manufacturer: String? = nil, model: String? = nil, swVersion: String? = nil, viaDeviceId: String? = nil) {
        self.id = id
        self.areaId = areaId
        self.name = name
        self.nameByUser = nameByUser
        self.entryType = entryType
        self.manufacturer = manufacturer
        self.model = model
        self.swVersion = swVersion
        self.viaDeviceId = viaDeviceId
    }

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
    public let entityId: String
    public var areaId: String? = nil
    public var name: String? = nil
    public var icon: String? = nil
    public var deviceId: String? = nil
    public let platform: String
    
    public init(entityId: String, areaId: String? = nil, name: String? = nil, icon: String? = nil, deviceId: String? = nil, platform: String) {
        self.entityId = entityId
        self.areaId = areaId
        self.name = name
        self.icon = icon
        self.deviceId = deviceId
        self.platform = platform
    }

    private enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case areaId = "area_id"
        case name
        case icon
        case deviceId = "device_id"
        case platform
    }
}

public struct EntityState: Codable {
    public let entityId: String
    public let state: String
    public var lastChanged: String? = nil
    public var lastUpdated: String? = nil
    public var attributes: [String : JSONProperty]? = nil
    
    public init(entityId: String, state: String, lastChanged: String? = nil, lastUpdated: String? = nil, attributes: [String : JSONProperty]? = nil) {
        self.entityId = entityId
        self.state = state
        self.lastChanged = lastChanged
        self.lastUpdated = lastUpdated
        self.attributes = attributes
    }

    private enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
        case attributes
    }
}
