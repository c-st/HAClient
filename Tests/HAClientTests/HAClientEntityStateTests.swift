import Combine
import Nimble
import XCTest

@testable import HAClient

final class HAClientEntityStateTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() async throws {
        cancellables = []
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange)
        try await client.authenticate(token: "mytoken")
        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(AuthOkMessage())
        )

        mockExchange.sentMessages = []
    }

    func testRecordsStateInRegistry() {
        client.requestStates()

        mockExchange.simulateIncomingMessage(message:
            JSONCoding.serialize(
                CurrentStatesResultMessage(
                    id: 1,
                    success: true,
                    result: [
                        CurrentStatesResultMessage.State(entityId: "id-1", state: "on"),
                    ]
                )
            )
        )

        self.client.registry.allStates.sink(receiveValue: { value in
            expect(value.values.count).to(beGreaterThan(0))
            expect(value["id-1"]?.stateText).to(be("on"))
        }).store(in: &cancellables)
    }
}
