import Nimble
import XCTest

@testable import HAClient

class FakeMessageExchange: MessageExchange {
    private var messageHandler: ((String) -> Void)?

    var sentMessages: [String] = []
    var receivedMessages: [String] = []
    var successfullyAuthenticated: Bool?

    func simulateIncomingMessage(message: String) {
        if let handler = messageHandler {
            handler(message)
        }
    }

    // MARK: Protocol

    func sendMessage(message: String) {
        sentMessages.append(message)
    }

    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
        self.messageHandler = messageHandler
    }

    func ping() {
    }

    func disconnect() {
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
        client?.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )

        expect(self.mockExchange?.sentMessages).to(equal([
            "{\"access_token\":\"mytoken\",\"type\":\"auth\"}",
        ]))
    }

    func testSetsStateAfterSuccessfulAuthentication() {
        client?.authenticate(
            token: "mytoken",
            completion: { },
            onFailure: { _ in }
        )

        mockExchange?.simulateIncomingMessage(
            message: JSONHandler.serialize(AuthOkMessage())
        )

        expect(self.client?.currentPhase) == HAClient.Phase.authenticated(0)
    }
    
    func testSetsFailureStateAfterInvalidAuthentication() {
        client?.authenticate(
            token: "invalid_token",
            completion: { },
            onFailure: { _ in }
        )

        mockExchange?.simulateIncomingMessage(
            message: JSONHandler.serialize(AuthInvalidMessage(message: "Invalid token"))
        )

        expect(self.client?.currentPhase).to(beNil())
    }
}

extension HAClient.Phase: Equatable {
    public static func == (lhs: HAClient.Phase, rhs: HAClient.Phase) -> Bool {
        switch (lhs, rhs) {
        case (.authenticated(_), .authenticated(_)):
            return true
        case (.pendingAuth(_, _), .pendingAuth(_, _)):
            return true
        default:
            return false
        }
    }
}
