import Foundation

public protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) async -> Void))
    func sendMessage(message: String) async
    func disconnect()
}

public protocol HAClientProtocol {
    init(messageExchange: MessageExchange)
    func authenticate(token: String) async throws -> Void
    // Commands
    func listAreas() async throws -> [Area]
    func listDevices() async throws -> [Device]
    func listEntities() async throws -> [Entity]
    func retrieveStates() async throws -> [State]
}

public class HAClient: HAClientProtocol {
    enum HAClientError: Error {
        case authenticationFailed(String)
        case authenticationRequired
        case responseError
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

    private let pendingRequests = PendingRequestsActor()

    public required init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(self.handleTextMessage(jsonString:))
    }
    
    // MARK: Send commands

    public func authenticate(token: String) async throws -> Void {
        let authCommand = AuthMessage(accessToken: token)
        
        currentPhase = .authRequested
        
        await messageExchange.sendMessage(
            message: JSONCoding.serialize(authCommand)
        )
        
        try await waitFor() {
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
    
    public func listAreas() async throws -> [Area] {
        return try await sendCommandAndAwaitResponse(.listAreas)
    }
    
    public func listDevices() async throws -> [Device] {
        return try await sendCommandAndAwaitResponse(.listDevices)
    }
    
    public func listEntities() async throws -> [Entity] {
        return try await sendCommandAndAwaitResponse(.listEntities)
    }
    
    public func retrieveStates() async throws -> [State] {
        return try await sendCommandAndAwaitResponse(.retrieveStates)
    }
    
    private func sendCommandAndAwaitResponse<T: Codable>(_ type: CommandType) async throws -> [T] {
        guard self.currentPhase == .authenticated else {
            throw HAClientError.authenticationRequired
        }
        
        let requestId = await pendingRequests.insert(type: type)
        await messageExchange.sendMessage(
            message: JSONCoding.serialize(Message(type: type, id: requestId))
        )
        
        try await waitFor() {
            await pendingRequests.getResponse(requestId) != nil
        }
        
        let response = await pendingRequests.getResponse(requestId)
        if let message = response as? ResultMessage<T> {
            await pendingRequests.remove(id: message.id)
            return message.result
        }
        
        throw HAClientError.responseError
    }

    private func waitFor(_ condition: () async -> Bool) async throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1)
        while await !condition() {
            let nextTime = Date().addingTimeInterval(0.1)
            RunLoop.current.run(until: nextTime)
            if nextTime > endTime {
                throw HAClientError.requestTimeout
            }
        }
    }
    
    // MARK: Message handling

    private func handleTextMessage(jsonString: String) async {
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
                await handleMessage(message: resultMessage, jsonData: jsonData)
            default:
                break
            }

        default:
            NSLog("Not handling message. JSON: %s", jsonString)
            return
        }
    }
    
    private func handleMessage(message: BaseResultMessage, jsonData: Data) async {
        guard let matchingRequestType = await pendingRequests.getType(message.id) else {
            NSLog("No matching request found with ID %@", message.id)
            return
        }
        await pendingRequests.addResponse(id: message.id, JSONCoding.deserializeCommandResponse(
            type: matchingRequestType,
            jsonData: jsonData
        ))
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
