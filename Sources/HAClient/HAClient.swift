import Foundation

public protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void))
    func sendMessage(message: String)
    func disconnect()
}

public protocol HAClientProtocol {
    init(messageExchange: MessageExchange)
    // Commands
    func authenticate(token: String) async throws -> Void
    
    func listAreas() async throws -> [Area]?
    func listDevices() async throws -> [Device]?
    func listEntities() async throws -> [Entity]?
    func retrieveStates() async throws -> [State]?
}

public class HAClient: HAClientProtocol {
    typealias RequestID = Int
    
    enum HAClientError: Error {
        case authenticationFailed(String)
        case authenticationRequired
        case requestTimeout
    }
    
    enum Phase: Equatable {
        case initial
        case authRequested
        case authenticated
        case authenticationFailure(failureReason: String)
    }
    
    private let messageExchange: MessageExchange
    
    private var currentPhase: Phase = .initial
    private var lastUsedRequestId: RequestID?
    private var pendingRequests: [RequestID: CommandType] = [:]
    private var responses: [RequestID: Any] = [:]

    public required init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(self.handleTextMessage(jsonString:))
    }
    
    // MARK: Send commands

    public func authenticate(token: String) async throws -> Void {
        let authCommand = AuthMessage(accessToken: token)
        
        currentPhase = .authRequested
        
        messageExchange.sendMessage(
            message: JSONCoding.serialize(authCommand)
        )
        
        try waitFor() {
            currentPhase != .authRequested
        }
        
        switch currentPhase {
        case .authenticated:
            NSLog("Auth successful")
            return
        case .authenticationFailure(let failureReason):
            throw HAClientError.authenticationFailed(failureReason)
        default:
            return
        }
    }
    
    public func listAreas() async throws -> [Area]? {
        return try await sendCommandAndAwaitResponse(.listAreas)
    }
    
    public func listDevices() async throws -> [Device]? {
        return try await sendCommandAndAwaitResponse(.listDevices)
    }
    
    public func listEntities() async throws -> [Entity]? {
        return try await sendCommandAndAwaitResponse(.listEntities)
    }
    
    public func retrieveStates() async throws -> [State]? {
        return try await sendCommandAndAwaitResponse(.retrieveStates)
    }
    
    private func sendCommandAndAwaitResponse<T: Codable>(_ type: CommandType) async throws -> [T]? {
        guard self.currentPhase == .authenticated else {
            throw HAClientError.authenticationRequired
        }
        
        let requestId = getAndIncrementId()
        pendingRequests[requestId] = type
        
        messageExchange.sendMessage(
            message: JSONCoding.serialize(Message(type: type, id: requestId))
        )
        
        try waitFor() {
            responses[requestId] != nil
        }
        
        if
            let response = responses[requestId],
            let message = response as? ResultMessage<T> {
            return message.result
        }
        
        NSLog("Response could not be decoded %@", responses[requestId].debugDescription)
        return nil
    }

    private func getAndIncrementId() -> Int {
        let id = (lastUsedRequestId ?? 0) + 1
        lastUsedRequestId = id
        return id
    }
    
    private func waitFor(_ condition: () -> Bool) throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1)
        while !condition() {
            let nextTime = Date().addingTimeInterval(0.1)
            RunLoop.current.run(until: nextTime)
            if nextTime > endTime {
                throw HAClientError.requestTimeout
            }
        }
    }
    
    // MARK: Message handling

    private func handleTextMessage(jsonString: String) {
        let incomingMessage = JSONCoding.deserialize(jsonString)
        let jsonData = jsonString.data(using: .utf8)!

        switch currentPhase {
        case .authRequested:
            guard let message = incomingMessage else {
                return
            }
            currentPhase = handleAuthenticationMessage(message)

        case .authenticated:
            switch incomingMessage {
            case let resultMessage as BaseResultMessage:
                guard resultMessage.success else {
                    NSLog("Command processing failed. JSON: %@", jsonString)
                    return
                }
                handleMessage(message: resultMessage, jsonData: jsonData)
            default:
                break
            }

        default:
            NSLog("Not handling message. JSON: %s", jsonString)
            return
        }
    }
    
    private func handleMessage(message: BaseResultMessage, jsonData: Data) {
        guard let matchingRequestType = pendingRequests[message.id] else {
            NSLog("No matching request found with ID %@", message.id)
            return
        }
        responses[message.id] = JSONCoding.deserializeCommandResponse(
            type: matchingRequestType,
            jsonData: jsonData
        )
        pendingRequests.removeValue(forKey: message.id)
    }
    
    private func handleAuthenticationMessage(_ message: Any) -> Phase {
        switch message {
        case _ as AuthOkMessage:
            NSLog("Authentication was successful")
            return .authenticated
            
        case let authInvalidMessage as AuthInvalidMessage:
            NSLog("Authentication failed", authInvalidMessage.message)
            messageExchange.disconnect()
            return .authenticationFailure(failureReason: authInvalidMessage.message)
            
        default:
            return currentPhase
        }
    }
}
