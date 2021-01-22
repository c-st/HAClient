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

    func testSendsAccessTokenWhenAuthenticating() {
        client?.authenticate(token: "mytoken")
        expect(self.mockExchange?.sentMessages).to(equal([
            "{\"access_token\":\"mytoken\",\"type\":\"auth\"}",
        ]))
    }
    
    func testInvokesSuccessCallbackAfterAuth() {}
    
    func testInvokesErrorCallbackAfterFailedAuth() {}
}
