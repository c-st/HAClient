import Foundation

public class WebSocketConnection: MessageExchange {
    private let websocketEndpoint: String
    private let webSocketDelegate = WebSocket()
    private let webSocketTask: URLSessionWebSocketTask
    private var messageHandler: ((String) -> Void)?

    public init(endpoint: String) {
        websocketEndpoint = endpoint

        let session = URLSession(
            configuration: .default,
            delegate: webSocketDelegate,
            delegateQueue: OperationQueue()
        )

        let url = URL(string: websocketEndpoint)!
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()

        receiveMessage()
    }

    public func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
        self.messageHandler = messageHandler
    }

    public func sendMessage(message: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(message)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }

    public func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }

    private func receiveMessage() {
        webSocketTask.receive { result in
            switch result {
            case let .failure(error):
                print("Failed to receive message: \(error)")
            case let .success(message):
                switch message {
                case let .string(text):
                    if let handler = self.messageHandler {
                        handler(text)
                    }
                case let .data(data):
                    print("Ignoring binary message: \(data)")
                @unknown default:
                    fatalError()
                }

                self.receiveMessage() // Wait for next message...
            }
        }
    }
}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
}
