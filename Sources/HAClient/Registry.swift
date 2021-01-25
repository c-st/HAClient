import Foundation

public struct Area {
    let id: String
    let name: String
}

public struct Device: Equatable {
    let id: String
    let name: String
    let manufacturer: String
    let areaId: String?

    static public func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Entity: Equatable {
    let id: String
    let areaId: String?
    let deviceId: String?
    let platform: String

    static public func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct State {
    let entityId: String
    let stateText: String
}

public class Registry {
    private(set) public var areas: [Area] = []
    private(set) public var devices: [String: Device] = [:]
    private(set) public var entities: [String: Entity] = [:]
    private(set) public var states: [String: State] = [:]

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
            print("Received \(areas.count) areas")
            break

        case let message as ListDevicesResultMessage:
            devices = message.result.reduce(into: [String: Device]()) { deviceRegistry, device in
                deviceRegistry[device.id] = Device(
                    id: device.id,
                    name: device.nameByUser ?? device.name,
                    manufacturer: device.manufacturer,
                    areaId: device.areaId
                )
            }
            print("Received \(devices.count) devices")

        case let message as ListEntitiesResultMessage:
            entities = message.result.reduce(into: [String: Entity]()) { entityRegistry, entity in
                entityRegistry[entity.id] = Entity(
                    id: entity.id,
                    areaId: entity.areaId,
                    deviceId: entity.deviceId,
                    platform: entity.platform
                )
            }
            print("Received \(entities.count) entities")

        case let message as CurrentStatesResultMessage:
            states = message.result.reduce(into: states) { stateRegistry, state in
                stateRegistry[state.entityId] = State(
                    entityId: state.entityId,
                    stateText: state.state
                )
            }
            print("Received \(message.result.count) new states")

        default:
            break
        }
    }
}
