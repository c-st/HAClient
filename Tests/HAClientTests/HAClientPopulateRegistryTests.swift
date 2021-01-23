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
            message: JSONHandler.serialize(AuthOkMessage())
        )
        mockExchange.sentMessages = []
    }

    func testUsesIncrementingIdWhenMakingRequests() {
        client.populateRegistry {}

        expect(self.mockExchange.sentMessages).to(equal([
            JSONHandler.serialize(RequestAreaRegistry(id: 1)),
            JSONHandler.serialize(RequestDeviceRegistry(id: 2)),
            JSONHandler.serialize(RequestEntityRegistry(id: 3)),
        ]))
    }

    func testCallsCompletionWhenAllPopulationResponsesHaveArrived() {
        waitUntil(timeout: 1) { done in
            self.client.populateRegistry {
                done()
            }

            self.mockExchange.simulateIncomingMessage(
                message: JSONHandler.serialize(ResultMessage(id: 1, success: true))
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONHandler.serialize(ResultMessage(id: 2, success: true))
            )
            self.mockExchange.simulateIncomingMessage(
                message: JSONHandler.serialize(ResultMessage(id: 3, success: true))
            )

            expect(self.client.currentPhase) == .authenticated(4)
        }
    }

    func testResetsPhaseIfAResponseWasNotSuccessful() {
        client.populateRegistry {}

        mockExchange.simulateIncomingMessage(
            message: JSONHandler.serialize(ResultMessage(id: 1, success: true))
        )
        mockExchange.simulateIncomingMessage(
            message: JSONHandler.serialize(ResultMessage(id: 2, success: false))
        )
        mockExchange.simulateIncomingMessage(
            message: JSONHandler.serialize(ResultMessage(id: 3, success: true))
        )

        expect(self.client.currentPhase).toEventually(beNil())
    }
}
