import Foundation

@testable import HAClient

/**
 A fake message exchange.
 This simulates a websocket client and can fake incoming and outgoing messages.
 */
class FakeMessageExchange: MessageExchange {
    var isConnected: Bool = false
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
    
    // Handler for handling incoming server messages by client
    private var messageHandler: ((String) async -> Void)?

    func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void)) {
        self.messageHandler = messageHandler
    }
    
    func sendMessage(payload: String) {
        if let handler = outgoingMessageHandler {
            Task {
                NSLog(">> \(payload)")
                await handler(payload)
            }
        }
    }
    
    func connect() {
        NSLog("Connected to FakeMessageExchange")
        isConnected = true
        Task {
            await simulateIncomingMessage(message: JSONCoding.serialize(
                    AuthRequired(haVersion: "fake-version"))
            )
        }
    }
    
    func disconnect() {
        NSLog("Disconnected from FakeMessageExchange")
        isConnected = false
    }
}
