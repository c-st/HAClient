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
            onConnection: { },
            onFailure: { _ in }
        )

        expect(self.mockExchange.sentMessages).to(equal([
            JSONCoding.serialize(AuthMessage(accessToken: "mytoken")),
        ]))
    }

    func testSetsStateAfterSuccessfulAuthentication() {
        client.authenticate(
            token: "mytoken",
            onConnection: { },
            onFailure: { _ in }
        )

        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(AuthOkMessage())
        )

        expect(self.client.currentPhase) == HAClient.Phase.authenticated
    }

    func testSetsFailureStateAfterInvalidAuthentication() {
        client?.authenticate(
            token: "invalid_token",
            onConnection: { },
            onFailure: { _ in }
        )

        mockExchange.simulateIncomingMessage(
            message: JSONCoding.serialize(AuthInvalidMessage(message: "Invalid token"))
        )

        expect(self.client.currentPhase).to(beNil())
    }
}
