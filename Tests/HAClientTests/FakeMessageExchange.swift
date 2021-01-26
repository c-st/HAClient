import Foundation

@testable import HAClient

class FakeMessageExchange: MessageExchange {
    private var messageHandler: ((String) -> Void)?

    var sentMessages: [String] = []
    var receivedMessages: [String] = []
    var successfullyAuthenticated: Bool?

    // MARK: Fake helpers

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

    func disconnect() {
    }
}

extension HAClient.Phase: Equatable {
    public static func == (lhs: HAClient.Phase, rhs: HAClient.Phase) -> Bool {
        switch (lhs, rhs) {
        case (.authenticated, .authenticated):
            return true
        default:
            return false
        }
    }
}
