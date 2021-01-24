import Nimble
import XCTest

@testable import HAClient

final class HAClientPopulateRegistryTests: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange)

        // Authenticate and reset recorded messages:
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

            self.mockExchange.simulateIncomingMessage(
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
                            ListAreasResultMessage.Area(
                                name: "Kitchen",
                                areaId: "kitchen"
                            ),
                        ]
                    )
                )
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONCoding.serialize(BaseResultMessage(id: 2, success: true))
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONCoding.serialize(BaseResultMessage(id: 3, success: true))
            )

            expect(self.client.currentPhase) == .authenticated
            expect(self.client.registry.areas.count).to(be(3))
        }
    }
}
