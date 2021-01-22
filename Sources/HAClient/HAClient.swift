import Foundation

protocol MessageExchange {
    mutating func setMessageHandler(_ messageHandler: @escaping ((String) -> Void))
    func sendMessage(message: String)
    func ping()
}

struct HAClient {
    private var messageExchange: MessageExchange

    init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(onMessage)
    }

    func authenticate(token: String) {
        messageExchange.sendMessage(
            message: JSONHandler.serialize(AuthMessage(accessToken: token))
        )
    }

    private func onMessage(message: String) {
        print("Client received message from websocket \(message)")
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

struct WebSocketConnection: MessageExchange {
    private let websocketEndpoint: String
    private let webSocketDelegate = WebSocket()
    private let webSocketTask: URLSessionWebSocketTask
    private var messageHandler: ((String) -> Void)?

    init(endpoint: String) {
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

    mutating func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
        self.messageHandler = messageHandler
    }

    func sendMessage(message: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(message)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask.receive { result in
            switch result {
            case let .failure(error):
                print("Failed to receive message: \(error)")
            case let .success(message):
                switch message {
                case let .string(text):
                    print("Received text message: \(text)")
                    if let messageHandler = self.messageHandler {
                        messageHandler(text)
                    }
                case let .data(data):
                    print("Received binary message: \(data)")
                @unknown default:
                    fatalError()
                }

                self.receiveMessage()
            }
        }
    }

    func ping() {
        print("sending a ping")
        webSocketTask.sendPing { error in
            if let error = error {
                print("Error when sending PING \(error)")
            } else {
                print("Successfully sent a ping")
            }
        }
    }
}
