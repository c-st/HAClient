import Nimble
import XCTest

@testable import HAClient

final class HAClientPopulateRegistryTests: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange)
        client.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(AuthOkMessage())
        )
        mockExchange.sentMessages = []
    }

    func testUsesIncrementingIdWhenMakingRequests() {
        client.populateRegistry {}

        expect(self.mockExchange.sentMessages).to(equal([
            JSONCoding.serialize(RequestAreaRegistry(id: 1)),
            JSONCoding.serialize(RequestDeviceRegistry(id: 2)),
            JSONCoding.serialize(RequestEntityRegistry(id: 3)),
        ]))
    }

    func testCallsCompletionWhenAllPopulationResponsesHaveArrived() {
        waitUntil(timeout: 1) { done in
            self.client.populateRegistry {
                done()
            }

            self.mockExchange.simulateIncomingMessage(
                message: JSONCoding.serialize(BaseResultMessage(id: 1, success: true))
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONCoding.serialize(BaseResultMessage(id: 2, success: true))
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONCoding.serialize(BaseResultMessage(id: 3, success: true))
            )

            expect(self.client.currentPhase) == .authenticated
        }
    }

    func testResetsPhaseIfAResponseWasNotSuccessful() {
        client.populateRegistry {}

        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(BaseResultMessage(id: 1, success: true))
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(BaseResultMessage(id: 2, success: false))
        )
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(BaseResultMessage(id: 3, success: true))
        )

        expect(self.client.currentPhase).toEventually(beNil())
    }

    func testHandlesResponsesToPopulateRegistry() {
        waitUntil(timeout: 1) { done in
            self.client.populateRegistry {
                done()
            }

            TestExamples.simulatePopulateRegistryResponses(self.mockExchange)

            expect(self.client.currentPhase) == .authenticated
            expect(self.client.registry.areas.count).to(be(2))
            expect(self.client.registry.devices.count).to(be(3))
            expect(self.client.registry.entities.count).to(be(4))
        }
    }

    func testReturnsEntitesByArea() {
        client.populateRegistry {}
        TestExamples.simulatePopulateRegistryResponses(self.mockExchange)


        expect(self.client.registry.entitiesInArea(areaId: "living-room").count).to(be(3))
        expect(
            self.client.registry.entitiesInArea(areaId: "living-room")
        ).to(contain([
            Entity(
                id: "light.living_room_lamp",
                areaId: nil,
                deviceId: "device-id-1",
                platform: "mqtt"
            ),
            Entity(
                id: "sensor.living_room_humidity",
                areaId: nil,
                deviceId: "device-id-3",
                platform: "mqtt"
            ),
            Entity(
                id: "sensor.living_room_temperature",
                areaId: nil,
                deviceId: "device-id-3",
                platform: "mqtt"
            ),
        ]))

        expect(self.client.registry.entitiesInArea(areaId: "bedroom").count).to(be(1))
        expect(
            self.client.registry.entitiesInArea(areaId: "bedroom")
        ).to(contain([
            Entity(
                id: "light.bedroom_lamp",
                areaId: nil,
                deviceId: "device-id-2",
                platform: "mqtt"
            ),
        ]))
    }
}
