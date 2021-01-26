import Combine
import Foundation

public struct Area {
    public let id: String
    public let name: String
}

public struct Device: Equatable {
    public let id: String
    public let name: String
    public let manufacturer: String
    public let areaId: String?

    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Entity: Equatable {
    public let id: String
    public let areaId: String?
    public let deviceId: String?
    public let platform: String

    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct State {
    public let entityId: String
    public let stateText: String
}

public class Registry: ObservableObject {
    @Published public private(set) var areas: [Area] = []
    @Published public private(set) var devices: [String: Device] = [:]
    @Published public private(set) var entities: [String: Entity] = [:]
    @Published public private(set) var states: [String: State] = [:]

    public func entitiesInArea(areaId: String) -> [Entity] {
        let deviceIdsInArea = devices.values
            .filter { $0.areaId == areaId }
            .map { $0.id }

        let entitiesFromDevices = entities.values
            .filter { $0.deviceId != nil }
            .filter { deviceIdsInArea.contains($0.deviceId!) }

        return entitiesFromDevices
    }

    func handleResultMessage(_ resultMessage: Any) {
        switch resultMessage {
        case let message as ListAreasResultMessage:
            areas = message.result.map {
                Area(id: $0.areaId, name: $0.name)
            }

        case let message as ListDevicesResultMessage:
            devices = message.result.reduce(into: [String: Device]()) { deviceRegistry, device in
                deviceRegistry[device.id] = Device(
                    id: device.id,
                    name: device.nameByUser ?? device.name,
                    manufacturer: device.manufacturer,
                    areaId: device.areaId
                )
            }

        case let message as ListEntitiesResultMessage:
            entities = message.result.reduce(into: [String: Entity]()) { entityRegistry, entity in
                entityRegistry[entity.id] = Entity(
                    id: entity.id,
                    areaId: entity.areaId,
                    deviceId: entity.deviceId,
                    platform: entity.platform
                )
            }

        case let message as CurrentStatesResultMessage:
            states = message.result.reduce(into: states) { stateRegistry, state in
                stateRegistry[state.entityId] = State(
                    entityId: state.entityId,
                    stateText: state.state
                )
            }

        default:
            break
        }
    }
}
