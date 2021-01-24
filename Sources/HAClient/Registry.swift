import Foundation

struct Area {
    let id: String
    let name: String
}

struct Device {
    let id: String
    let name: String
    let manufacturer: String
    let areaId: String?
}

struct Entity {
    let id: String
    let areaId: String?
    let deviceId: String?
    let platform: String
}

class Registry {
    private(set) var areas: [Area] = []
    private(set) var devices: [String: Device] = [:]
    private(set) var entities: [String: Entity] = [:]

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

        default:
            break
        }
    }
}
