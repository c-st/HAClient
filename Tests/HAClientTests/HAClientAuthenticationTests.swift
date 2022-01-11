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

    func testSendsAccessTokenWhenAuthenticating() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let expectedMsg = JSONCoding.serialize(AuthMessage(accessToken: "mytoken"))
            expect(msg).to(equal(expectedMsg))
            
            // send auth ok response
            let authOk = JSONCoding.serialize(AuthOkMessage())
            self.mockExchange.simulateIncomingMessage(message: authOk)
        }
        
        try await client.authenticate(token: "mytoken")
    }

//    func testSetsStateAfterSuccessfulAuthentication() async throws {
//        try await client.authenticate(token: "mytoken")
//
//        mockExchange.simulateIncomingMessage(
//            message: JSONCoding.serialize(AuthOkMessage())
//        )
//
//        expect(self.client.currentPhase) == HAClient.Phase.authenticated
//    }
//
//    func testSetsFailureStateAfterInvalidAuthentication() async throws {
//        try await client?.authenticate(token: "invalid_token")
//
//        mockExchange.simulateIncomingMessage(
//            message: JSONCoding.serialize(AuthInvalidMessage(message: "Invalid token"))
//        )
//
//        expect(self.client.currentPhase).to(beNil())
//    }
}
