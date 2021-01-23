import Nimble
import XCTest

@testable import HAClient

final class HAClientRegistryTests: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)

        // Authenticate and reset recordded messages:
        client?.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )
        mockExchange?.simulateIncomingMessage(
            message: JSONHandler.serialize(AuthOkMessage())
        )
        mockExchange.sentMessages = []
    }

    func testUsesIncrementingIdWhenMakingRequests() {
        client.populateRegistry()

        expect(self.mockExchange.sentMessages).to(equal([
            JSONHandler.serialize(RequestAreaRegistry(id: 1)),
            JSONHandler.serialize(RequestDeviceRegistry(id: 2)),
            JSONHandler.serialize(RequestEntityRegistry(id: 3)),
        ]))
    }
}
