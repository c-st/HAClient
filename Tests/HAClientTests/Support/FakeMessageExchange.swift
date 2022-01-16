import Foundation

@testable import HAClient

/**
 A fake message exchange.
 This simulates a websocket client and can fake incoming and outgoing messages.
 */
class FakeMessageExchange: MessageExchange {    
//    var sentMessages: [String] = []
//    var receivedMessages: [String] = []
    
    var successfullyAuthenticated: Bool?
   
    // MARK: Fake helpers
    
    // Handler for outgoing messages (Client -> WebSocket endpoint)
    var outgoingMessageHandler: ((String) async -> Void)?

    func simulateIncomingMessage(message: String) async {
        if let handler = messageHandler {
            await handler(message)
        }
    }

    // MARK: Protocol implementation
    
    // Handler for incoming messages (WebSocket endpoint -> client)
    private var messageHandler: ((String) async -> Void)?

    func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void)) {
        self.messageHandler = messageHandler
    }
    
    func sendMessage(message: String) async {
        if let handler = outgoingMessageHandler {
            await handler(message)
        }
//        sentMessages.append(message)
    }

    func disconnect() {
    }
}
