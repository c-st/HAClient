import Nimble
import XCTest

@testable import HAClient

final class HAClientAuthenticationTests: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() async throws {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)
    }

    func test_sendsTokenAndHandlesResponse() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let expectedMsg = JSONCoding.serialize(AuthMessage(accessToken: "mytoken"))
            expect(msg).to(equal(expectedMsg))
            
            // reply with auth_ok
            let authOk = JSONCoding.serialize(AuthOkMessage())
            self.mockExchange.simulateIncomingMessage(message: authOk)
        }
        
        try await client.authenticate(token: "mytoken")
    }

    func test_throwsOnFailedAuthentication() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let authFailed = JSONCoding.serialize(AuthInvalidMessage(message: "Invalid token"))
            self.mockExchange.simulateIncomingMessage(message: authFailed)
        }
        
        do {
            try await client?.authenticate(token: "invalid_token")
            fail("Method did not throw")
        } catch {}
    }
}
