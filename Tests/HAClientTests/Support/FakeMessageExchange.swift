import Foundation

@testable import HAClient

/**
 A fake message exchange.
 This simulates a websocket client and can fake incoming and outgoing messages.
 */
class FakeMessageExchange: MessageExchange {
    var isConnected: Bool = true
    
    // var sentMessages: [String] = []
    
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
    
    func sendMessage(payload: String) {
        if let handler = outgoingMessageHandler {
            Task {
                await handler(payload)
            }
        }
        // sentMessages.append(message)
    }
    
    func connect() {}
    func disconnect() {}
}
