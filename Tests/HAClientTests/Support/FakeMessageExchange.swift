import Foundation

@testable import HAClient

/**
 A fake message exchange.
 This simulates a websocket client and can fake incoming and outgoing messages.
 */
class FakeMessageExchange: MessageExchange {
    var sentMessages: [String] = []
    var receivedMessages: [String] = []
    var successfullyAuthenticated: Bool?

    // Handler for incoming messages (WebSocket endpoint -> client)
    private var messageHandler: ((String) -> Void)?
    
    // Handler for outgoing messages (Client -> WebSocket endpoint)
    var outgoingMessageHandler: ((String) -> Void)?

    // MARK: Fake helpers

    func simulateIncomingMessage(message: String) {
        if let handler = messageHandler {
            handler(message)
        }
    }

    // MARK: Protocol

    func sendMessage(message: String) {
        if let handler = outgoingMessageHandler {
            handler(message)
        }
        sentMessages.append(message)
    }

    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
        self.messageHandler = messageHandler
    }

    func disconnect() {
    }
}
