import XCTest

@testable import HAClient

struct TestExamples {
    static func simulatePopulateRegistryResponses(_ mockExchange: FakeMessageExchange) {
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(
                ListAreasResultMessage(
                    id: 1,
                    success: true,
                    result: [
                        ListAreasResultMessage.Area(
                            name: "Living room",
                            areaId: "living-room"
                        ),
                        ListAreasResultMessage.Area(
                            name: "Bedroom",
                            areaId: "bedroom"
                        ),
                    ]
                )
            )
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(
                ListDevicesResultMessage(
                    id: 2,
                    success: true,
                    result: [
                        ListDevicesResultMessage.Device(
                            id: "device-id-1",
                            name: "living_room_lamp",
                            nameByUser: nil,
                            manufacturer: "Lamp Manufacturer",
                            areaId: "living-room"
                        ),
                        ListDevicesResultMessage.Device(
                            id: "device-id-2",
                            name: "bedroom_lamp",
                            nameByUser: nil,
                            manufacturer: "Lamp Manufacturer",
                            areaId: "bedroom"
                        ),
                        ListDevicesResultMessage.Device(
                            id: "device-id-3",
                            name: "Sensor",
                            nameByUser: nil,
                            manufacturer: "Sensor Manufacturer",
                            areaId: "living-room"
                        ),
                    ]
                )
            )
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(
                ListEntitiesResultMessage(
                    id: 3,
                    success: true,
                    result: [
                        ListEntitiesResultMessage.Entity(
                            id: "light.living_room_lamp",
                            areaId: nil,
                            deviceId: "device-id-1",
                            platform: "mqtt"
                        ),
                        ListEntitiesResultMessage.Entity(
                            id: "light.bedroom_lamp",
                            areaId: nil,
                            deviceId: "device-id-2",
                            platform: "mqtt"
                        ),
                        ListEntitiesResultMessage.Entity(
                            id: "sensor.living_room_humidity",
                            areaId: nil,
                            deviceId: "device-id-3",
                            platform: "mqtt"
                        ),
                        ListEntitiesResultMessage.Entity(
                            id: "sensor.living_room_temperature",
                            areaId: nil,
                            deviceId: "device-id-3",
                            platform: "mqtt"
                        ),
                    ]
                )
            )
        )
    }
}
