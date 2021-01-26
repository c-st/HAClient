import Combine
import Nimble
import XCTest

@testable import HAClient

final class HAClientMessageHandlingTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() {
        cancellables = []
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange)
        client.authenticate(
            token: "mytoken",
            onConnection: { },
            onFailure: { _ in }
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(AuthOkMessage())
        )

        mockExchange.sentMessages = []
    }

    func testHandlesMessagesOutOfOrder() {
        client.requestRegistry()
        client.requestStates()

        // populateRegistry (1/3)
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(ListAreasResultMessage(
                id: 1,
                success: true,
                result: [ListAreasResultMessage.Area(
                    name: "Living room",
                    areaId: "living-room"
                )]))
        )

        // fetchStates
        mockExchange.simulateIncomingMessage(message:
            JSONCoding.serialize(
                CurrentStatesResultMessage(
                    id: 4,
                    success: true,
                    result: [
                        CurrentStatesResultMessage.State(entityId: "id-1", state: "on"),
                    ]
                )
            )
        )

        // populateRegistry
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(ListDevicesResultMessage(
                id: 2,
                success: true,
                result: [ListDevicesResultMessage.Device(
                    id: "device-id-1",
                    name: "living_room_lamp",
                    nameByUser: nil,
                    manufacturer: "Lamp Manufacturer",
                    areaId: "living-room"
                )])
            )
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(ListEntitiesResultMessage(
                id: 3,
                success: true,
                result: [ListEntitiesResultMessage.Entity(
                    id: "light.living_room_lamp",
                    areaId: nil,
                    deviceId: "device-id-1",
                    platform: "mqtt"
                )])
            )
        )

        mockExchange.simulateIncomingMessage(message:
            JSONCoding.serialize(
                CurrentStatesResultMessage(
                    id: 4,
                    success: true,
                    result: [
                        CurrentStatesResultMessage.State(entityId: "id-1", state: "on"),
                    ]
                )
            )
        )
        
        client.registry.allAreas.sink(receiveValue: { value in
            expect(value).to(haveCount(1))
        }).store(in: &cancellables)
        
        client.registry.allDevices.sink(receiveValue: { value in
            expect(value.values).to(haveCount(1))
        }).store(in: &cancellables)

        client.registry.allEntities.sink(receiveValue: { value in
            expect(value.values).to(haveCount(1))
        }).store(in: &cancellables)

        client.registry.allStates.sink(receiveValue: { value in
            expect(value.values).to(haveCount(1))
        }).store(in: &cancellables)
    }
}
