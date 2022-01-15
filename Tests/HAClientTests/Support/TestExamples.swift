import XCTest

@testable import HAClient

// TODO: fix sample data

struct TestExamples {
    static func simulatePopulateRegistryResponses(_ mockExchange: FakeMessageExchange) {
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(
                ListAreasResultMessage(
                    id: 1,
                    success: true,
                    result: [
                        Area(
                            name: "Living room",
                            areaId: "living-room"
                        ),
                        Area(
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
                        Device(
                            id: "device-id-1",
                            name: "living_room_lamp",
                            nameByUser: "",
                            manufacturer: "Lamp Manufacturer",
                            areaId: "living-room"
                        ),
                        Device(
                            id: "device-id-2",
                            name: "bedroom_lamp",
                            nameByUser: "",
                            manufacturer: "Lamp Manufacturer",
                            areaId: "bedroom"
                        ),
                        Device(
                            id: "device-id-3",
                            name: "Sensor",
                            nameByUser: "",
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
                        Entity(
                            id: "light.living_room_lamp",
                            areaId: "",
                            deviceId: "device-id-1",
                            platform: "mqtt"
                        ),
                        Entity(
                            id: "light.bedroom_lamp",
                            areaId: "",
                            deviceId: "device-id-2",
                            platform: "mqtt"
                        ),
                        Entity(
                            id: "sensor.living_room_humidity",
                            areaId: "",
                            deviceId: "device-id-3",
                            platform: "mqtt"
                        ),
                        Entity(
                            id: "sensor.living_room_temperature",
                            areaId: "",
                            deviceId: "device-id-3",
                            platform: "mqtt"
                        ),
                    ]
                )
            )
        )
    }
}
