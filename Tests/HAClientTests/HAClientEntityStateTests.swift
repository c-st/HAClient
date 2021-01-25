import Foundation
import Nimble
import XCTest

@testable import HAClient

final class HAClientEntityStateTests: XCTestCase {
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

    func testCallsCompletionAfterSuccessfulResponse() {
        waitUntil(timeout: 1) { done in
            self.client.fetchStates {
                done()
            }

            self.mockExchange.simulateIncomingMessage(message:
                JSONCoding.serialize(
                    CurrentStatesResultMessage(
                        id: 5,
                        success: true,
                        result: []
                    )
                )
            )
        }
    }

    func testResetsPhaseIfAResponseWasNotSuccessful() {
        client.fetchStates {}

        mockExchange.simulateIncomingMessage(message:
            JSONCoding.serialize(
                CurrentStatesResultMessage(id: 6, success: false, result: [])
            )
        )

        expect(self.client.currentPhase).toEventually(beNil())
    }

    func testRecordsStateInRegistry() {
        client.fetchStates {}

        mockExchange.simulateIncomingMessage(message:
            JSONCoding.serialize(
                CurrentStatesResultMessage(
                    id: 5,
                    success: true,
                    result: [
                        CurrentStatesResultMessage.State(entityId: "id-1", state: "on"),
                    ]
                )
            )
        )

        expect(self.client.registry.states.count)
            .toEventually(beGreaterThan(0))
        
        expect(self.client.registry.states["id-1"]?.stateText)
            .toEventually(be("on"))
    }
}
