//import Combine
//import Foundation
//
//public struct Area {
//    public let id: String
//    public let name: String
//}
//
//public struct Device: Equatable {
//    public let id: String
//    public let name: String
//    public let manufacturer: String
//    public let areaId: String?
//
//    public static func == (lhs: Device, rhs: Device) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//public struct Entity: Equatable {
//    public let id: String
//    public let areaId: String?
//    public let deviceId: String?
//    public let platform: String
//
//    public static func == (lhs: Entity, rhs: Entity) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//public struct State {
//    public let entityId: String
//    public let stateText: String
//}
//
//public class Registry: ObservableObject {
//    public var allAreas: AnyPublisher<[Area], Never> {
//        allAreasSubject.eraseToAnyPublisher()
//    }
//
//    public var allDevices: AnyPublisher<[String: Device], Never> {
//        allDevicesSubject.eraseToAnyPublisher()
//    }
//
//    public var allEntities: AnyPublisher<[String: Entity], Never> {
//        allEntitiesSubject.eraseToAnyPublisher()
//    }
//
//    public var allStates: AnyPublisher<[String: State], Never> {
//        allStatesSubject.eraseToAnyPublisher()
//    }
//
//    let allAreasSubject = CurrentValueSubject<[Area], Never>([])
//    let allDevicesSubject = CurrentValueSubject<[String: Device], Never>([:])
//    let allEntitiesSubject = CurrentValueSubject<[String: Entity], Never>([:])
//    let allStatesSubject = CurrentValueSubject<[String: State], Never>([:])
//
//    public func entitiesInArea(areaId: String) -> AnyPublisher<[Entity], Never> {
//        return Publishers.CombineLatest(allDevices, allEntities)
//            .map { devices, entities in
//                let deviceIds = devices
//                    .map { $0.value }
//                    .filter { $0.areaId == areaId }
//                    .map { $0.id }
//
//                return entities
//                    .map { $0.value }
//                    .filter { $0.deviceId != nil }
//                    .filter { deviceIds.contains($0.deviceId!) }
//            }
//            .eraseToAnyPublisher()
//    }
//
//    func handleResultMessage(_ resultMessage: Any) {
//        switch resultMessage {
//        case let message as ListAreasResultMessage:
//            allAreasSubject.send(message.result.map {
//                Area(id: $0.areaId, name: $0.name)
//            })
//            print("\(message.result.count) areas")
//
//        case let message as ListDevicesResultMessage:
//            allDevicesSubject.send(message.result.reduce(into: [String: Device]()) { deviceRegistry, device in
//                deviceRegistry[device.id] = Device(
//                    id: device.id,
//                    name: device.nameByUser ?? device.name,
//                    manufacturer: device.manufacturer,
//                    areaId: device.areaId
//                )
//            })
//            print("\(message.result.count) devices")
//
//        case let message as ListEntitiesResultMessage:
//            allEntitiesSubject.send(message.result.reduce(into: [String: Entity]()) { entityRegistry, entity in
//                entityRegistry[entity.id] = Entity(
//                    id: entity.id,
//                    areaId: entity.areaId,
//                    deviceId: entity.deviceId,
//                    platform: entity.platform
//                )
//            })
//            print("\(message.result.count) entities")
//
//        case let message as CurrentStatesResultMessage:
//            allStatesSubject.send(message.result.reduce(into: [:]) { stateRegistry, state in
//                stateRegistry[state.entityId] = State(
//                    entityId: state.entityId,
//                    stateText: state.state
//                )
//            })
//            print("\(message.result.count) states")
//
//        default:
//            break
//        }
//    }
//}
