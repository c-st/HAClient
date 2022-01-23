import Foundation

public class WebSocketStream: AsyncSequence, MessageExchange {

    public typealias Element = URLSessionWebSocketTask.Message
    public typealias AsyncIterator = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator
    
    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    
    private var messageHandlingTask: Task<(), Never>?
    
    private let socket: URLSessionWebSocketTask
    
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
    
    public func connect(
        messageHandler: @escaping ((String) async -> Void),
        errorHandler: @escaping ((Error) async -> Void)
    ) {
        messageHandlingTask = Task {
            do {
                try Task.checkCancellation()
                for try await message in self {
                    switch message {
                    case let .string(text):
                        await messageHandler(text)
                    case let .data(data):
                        NSLog("Ignoring binary message \(data)")
                    default:
                        NSLog("Unknown message received")
                    }
                }
            } catch {
                await errorHandler(error)
            }
        }
    }
    
    public func sendMessage(message: String) async throws {
        NSLog("Sending message %@", message)
        try await socket.send(Element.string(message))
    }
    
    public func disconnect() {
        if (!(messageHandlingTask?.isCancelled ?? true)) {
            messageHandlingTask?.cancel()
        }
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
