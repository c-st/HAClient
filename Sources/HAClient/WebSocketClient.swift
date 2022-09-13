import Foundation

typealias MessageHandler = (String) async -> Void

public protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void))
    func connect()
    func sendMessage(payload: String)
    func disconnect()
    var isConnected: Bool { get }
}

public class WebSocketClient: NSObject, URLSessionDelegate, URLSessionWebSocketDelegate, MessageExchange {
    private let timeout: TimeInterval!
    private let url: URL!
    
    private var webSocketTask: URLSessionWebSocketTask!
    private var messageHandler: MessageHandler!
    
    public private(set) var isConnected: Bool = false
    
    public init(_ url: String, timeout: TimeInterval = 1) {
        self.timeout = timeout
        self.url = URL(string: url)
        super.init()
    }
    
    public func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void)) {
        self.messageHandler = messageHandler
    }
    
    public func connect() {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true

        let urlSession = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        let urlRequest = URLRequest(url: url, timeoutInterval: timeout)
        webSocketTask = urlSession.webSocketTask(with: urlRequest)
        
        webSocketTask.resume()
        
        readMessage()
    }
    
    private func readMessage() {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                NSLog("Failure with incoming message \(error.localizedDescription)")
                break
            case .success(let message):
                switch message {
                case .string(let string):
                    Task {
                        await self.messageHandler(string)
                    }
                case .data(_):
                    NSLog("Ignoring data message")
                @unknown default:
                    NSLog("Not handling message")
                }
            }
            self.readMessage() // wait for next message
        }
    }
    
    public func sendMessage(payload: String) {
        NSLog(">> \(payload)")
        webSocketTask.send(.string(payload)) { error in
            self.handleError(error)
        }
    }
    
    public func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
        self.isConnected = false
    }
    
    
    private func handleError(_ error: Error?) {
        if let error = error as NSError? {
            if error.code == 57  || error.code == 60 || error.code == 54 {
                NSLog("Disconnecting")
                disconnect()
            } else {
                fatalError("Unhandled error code \(error.code)")
            }
        }
    }
    
    // MARK: UrlSessionDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        NSLog("didCompleteWErrors")
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        NSLog("waiting...")
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        NSLog("Challenge received")
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        NSLog("Connected to websocket")
        self.isConnected = true
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        NSLog("didClose code \(closeCode)")
        self.isConnected = false
    }
}
