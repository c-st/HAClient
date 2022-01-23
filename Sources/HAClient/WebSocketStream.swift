import Foundation

public class WebSocketStream: AsyncSequence, MessageExchange {
    public typealias Element = URLSessionWebSocketTask.Message
    public typealias AsyncIterator = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator
    
    private var stream: AsyncThrowingStream<Element, Error>?
    private let socket: URLSessionWebSocketTask
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    
    public init(_ url: String, session: URLSession = URLSession.shared) {
        socket = session.webSocketTask(with: URL(string: url)!)
        stream = AsyncThrowingStream { continuation in
           self.continuation = continuation
           self.continuation?.onTermination = { @Sendable [socket] _ in
               socket.cancel()
           }
        }
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        guard let stream = stream else {
            fatalError("Stream was not initialized")
        }
        socket.resume()
        listenForMessages()
        return stream.makeAsyncIterator()
    }
    
    public func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void)) {
        Task {
            do {
                for try await message in self {
                    switch message {
                    case let .string(text):
                        await messageHandler(text)
                    case let .data(data):
                        NSLog("Ignoring binary message \(data)")
                    @unknown default:
                        fatalError("Unknown message received")
                    }
                }
            } catch {
                fatalError("Error while handling incoming message: \(error)")
            }
        }
    }
    
    public func sendMessage(message: String) {
        NSLog("Sending message %@", message)
        socket.send(Element.string(message)) { error in
            if let error = error {
                fatalError("WebSocket sending error: \(error)")
            }
        }
    }
    
    public func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
    }
    
    private func listenForMessages() {
        socket.receive { [unowned self] result in
            switch result {
            case .success(let message):
                continuation?.yield(message)
                listenForMessages()
            case .failure(let error):
                continuation?.finish(throwing: error)
            }
        }
    }
}
