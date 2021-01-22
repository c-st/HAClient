import Foundation
class WebSocket: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
}

struct WebSocketConnection {
    private let websocketEndpoint: String
    private let webSocketDelegate = WebSocket()
    private let webSocketTask: URLSessionWebSocketTask
    private var messageHandler: ((String) -> Void)?
    
    init(endpoint: String) {
        self.websocketEndpoint = endpoint
        
        let session = URLSession(
            configuration: .default,
            delegate: webSocketDelegate,
            delegateQueue: OperationQueue()
        )
        let url = URL(string: websocketEndpoint)!
        self.webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
    }
    
    mutating func setMessageHandler(_ messageHandler: @escaping ((String) -> Void)) {
        self.messageHandler = messageHandler
    }
    
    func sendMessage(message: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(message))
        { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    func receiveMessage() {
        webSocketTask.receive { result in
                switch result {
                case .failure(let error):
                    print("Failed to receive message: \(error)")
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received text message: \(text)")
                        if let messageHandler = self.messageHandler {
                            messageHandler(text)
                        }
                    case .data(let data):
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

struct HAClient {
    private var websocketConnection: WebSocketConnection
    
    init(websocketConnection: WebSocketConnection) {
        self.websocketConnection = websocketConnection
        self.websocketConnection.setMessageHandler(self.onMessage)
    }
    
    func onMessage(message: String) {
        print("Client received message from websocket \(message)")
    }
}
