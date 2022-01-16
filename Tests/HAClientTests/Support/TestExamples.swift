import XCTest

@testable import HAClient

struct TestExamples {
    static let areas = [
        Area(
        name: "Living room",
        areaId: "living-room"
    ),
    Area(
        name: "Bedroom",
        areaId: "bedroom"
    )]
    
    static let devices = [
        Device(
            id: "3d9b0fafd443dbdfa097e2d3652409ad",
            areaId: "living-room",
            name: "livingroom_sofa_lamp",
            manufacturer: "Philips",
            model: "Hue White A60 Single bulb E27/B22"
        ),
        Device(
            id: "3f15d73d9d4b80f21ff605a02a581d5c",
            areaId: "living-room",
            name: "livingroom_table_lamp",
            manufacturer: "Philips",
            model: "Hue White A60 Single bulb E27/B22"
        ),
        Device(
            id: "c69e75a4bfc0ed6529c85f5a9b6a15cd",
            areaId: "bedroom",
            name: "bedroom_lamp",
            manufacturer: "Philips",
            model: "Hue White A60 Single bulb E27/B22"
        ),
        Device(
            id: "31050cce837d748ebbf4fe666458c3fb",
            areaId: "living-room",
            name: "livingroom_motionsensor",
            manufacturer: "Philips",
            model: "Hue motion sensor"
        ),
        Device(
            id: "360d0dbfcc72571ec0d1c90bf70c6583",
            areaId: "bedroom",
            name: "bedroom_motionsensor",
            manufacturer: "Philips",
            model: "Hue motion sensor"
        )
    ]
    
    static let entities = [
        Entity(
            entityId: "light.livingroom_sofa_lamp",
            deviceId: "3d9b0fafd443dbdfa097e2d3652409ad",
            platform: "mqtt"
        ),
        Entity(
            entityId: "light.livingroom_table_lamp",
            deviceId: "3f15d73d9d4b80f21ff605a02a581d5c",
            platform: "mqtt"
        ),
        Entity(
            entityId: "light.bedroom_lamp",
            deviceId: "c69e75a4bfc0ed6529c85f5a9b6a15cd",
            platform: "mqtt"
        ),
        
        Entity(
            entityId: "binary_sensor.livingroom_motionsensor_occupancy",
            deviceId: "31050cce837d748ebbf4fe666458c3fb",
            platform: "mqtt"
        ),
        Entity(
            entityId: "sensor.livingroom_motionsensor_temperature",
            deviceId: "31050cce837d748ebbf4fe666458c3fb",
            platform: "mqtt"
        ),
        Entity(
            entityId: "binary_sensor.livingroom_motionsensor_illuminance_lux",
            deviceId: "31050cce837d748ebbf4fe666458c3fb",
            platform: "mqtt"
        ),
        
        Entity(
            entityId: "binary_sensor.bedroom_motionsensor_occupancy",
            deviceId: "360d0dbfcc72571ec0d1c90bf70c6583",
            platform: "mqtt"
        ),
        Entity(
            entityId: "sensor.bedroom_motionsensor_temperature",
            deviceId: "360d0dbfcc72571ec0d1c90bf70c6583",
            platform: "mqtt"
        ),
        Entity(
            entityId: "binary_sensor.bedroom_motionsensor_illuminance_lux",
            deviceId: "360d0dbfcc72571ec0d1c90bf70c6583",
            platform: "mqtt"
        )
    ]
    
    static let states = [
        State(
            entityId: "light.livingroom_sofa_lamp",
            state: "off",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "friendly_name": JSONProperty.string("livingroom_sofa_lamp"),
                "brightness": JSONProperty.string("255"),
                "color_mode": JSONProperty.string("brightness")
            ]
        ),
        State(
            entityId: "light.livingroom_table_lamp",
            state: "off",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "friendly_name": JSONProperty.string("livingroom_table_lamp"),
                "brightness": JSONProperty.string("255"),
                "color_mode": JSONProperty.string("brightness")
            ]
        ),
        State(
            entityId: "light.bedroom_lamp",
            state: "off",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "friendly_name": JSONProperty.string("bedroom_lamp"),
                "brightness": JSONProperty.string("255"),
                "color_mode": JSONProperty.string("brightness")
            ]
        ),
        
        State(
            entityId: "binary_sensor.livingroom_motionsensor_occupancy",
            state: "off",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(false),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(23.24),
                "illuminance": JSONProperty.double(18697),
                "illuminance_lux": JSONProperty.double(74)
            ]
        ),
        State(
            entityId: "binary_sensor.livingroom_motionsensor_temperature",
            state: "23.24",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(false),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(23.24),
                "illuminance": JSONProperty.double(18697),
                "illuminance_lux": JSONProperty.double(74)
            ]
        ),
        State(
            entityId: "binary_sensor.livingroom_motionsensor_illuminance_lux",
            state: "74",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(false),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(23.24),
                "illuminance": JSONProperty.double(18697),
                "illuminance_lux": JSONProperty.double(74)
            ]
        ),
        
        State(
            entityId: "binary_sensor.bedroom_motionsensor_occupancy",
            state: "on",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(true),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(22.28),
                "illuminance": JSONProperty.double(17707),
                "illuminance_lux": JSONProperty.double(59)
            ]
        ),
        State(
            entityId: "binary_sensor.bedroom_motionsensor_temperature",
            state: "22.28",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(true),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(22.28),
                "illuminance": JSONProperty.double(17707),
                "illuminance_lux": JSONProperty.double(59)
            ]
        ),
        State(
            entityId: "binary_sensor.bedroom_motionsensor_illuminance_lux",
            state: "59",
            lastChanged: "2022-01-14T22:13:58.369664+00:00",
            lastUpdated: "2022-01-15T11:51:31.095673+00:00",
            attributes: [
                "occupancy": JSONProperty.bool(true),
                "occupancy_timeout": JSONProperty.double(1200.0),
                "temperature": JSONProperty.double(22.28),
                "illuminance": JSONProperty.double(17707),
                "illuminance_lux": JSONProperty.double(59)
            ]
        ),
    ]
}
