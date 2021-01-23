import Nimble
import XCTest

@testable import HAClient

final class HAClientAuthenticationTests: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)
    }

    func testSendsAccessTokenWhenAuthenticating() {
        client.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )

        expect(self.mockExchange.sentMessages).to(equal([
            JSONHandler.serialize(AuthMessage(accessToken: "mytoken")),
        ]))
    }

    func testSetsStateAfterSuccessfulAuthentication() {
        client.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )

        mockExchange.simulateIncomingMessage(
            message: JSONHandler.serialize(AuthOkMessage())
        )

        expect(self.client.currentPhase) == HAClient.Phase.authenticated(1)
    }

    func testSetsFailureStateAfterInvalidAuthentication() {
        client?.authenticate(
            token: "invalid_token",
            completion: { },
            onFailure: { _ in }
        )

        mockExchange.simulateIncomingMessage(
            message: JSONHandler.serialize(AuthInvalidMessage(message: "Invalid token"))
        )

        expect(self.client.currentPhase).to(beNil())
    }
}
