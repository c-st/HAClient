import Nimble
import XCTest

@testable import HAClient

class FakeMessageExchange: MessageExchange {
    var sentMessages: [String] = []

    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
    }

    func sendMessage(message: String) {
        sentMessages.append(message)
    }

    func ping() {
    }
}

final class HAClientTests: XCTestCase {
    var mockExchange: FakeMessageExchange?
    var client: HAClient?

    override func setUp() {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)
    }

    func testSendsAccessTokenAfterConnection() {
        client?.authenticate(token: "token")
        // TODO: expect JSON string
        expect(self.mockExchange?.sentMessages).to(equal(["token foo"]))
    }
}
