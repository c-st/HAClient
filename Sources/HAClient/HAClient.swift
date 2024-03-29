import Foundation

public protocol HAClientProtocol {
    init(messageExchange: MessageExchange)
    func authenticate(token: String) async throws -> Void
    func sendPing() async throws -> Void

    func listAreas() async throws -> [Area]
    func listDevices() async throws -> [Device]
    func listEntities() async throws -> [Entity]
    func retrieveStates() async throws -> [EntityState]
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
    private let pendingRequests = PendingRequests()
    
    private var currentPhase: Phase = .initial

    public required init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(
            self.handleTextMessage(jsonString:)
        )
    }
    
    // MARK: Send commands

    public func authenticate(token: String) async throws -> Void {
        if !messageExchange.isConnected {
            // Establish connection
            currentPhase = .initial
            messageExchange.connect()
            try await waitFor {
                currentPhase == .authRequested
            } 
        }
       

        // Send auth
        let authCommand = AuthMessage(accessToken: token)
        messageExchange.sendMessage(
            payload: JSONCoding.serialize(authCommand)
        )
        try await waitFor() {
            currentPhase != .authRequested
        }
        
        // Handle auth result
        switch currentPhase {
        case .authenticated:
            NSLog("Authentication successful")
            return
        case .authenticationFailure(let failureReason):
            throw HAClientError.authenticationFailed(failureReason)
        default:
            return
        }
    }
    
    public func sendPing() async throws -> Void {
        let requestId = await pendingRequests.insert(type: .ping)
        messageExchange.sendMessage(
            payload: JSONCoding.serialize(Message(type: .ping, id: requestId))
        )
        
        try await waitFor() {
            await pendingRequests.getResponse(requestId) != nil
        }
        
        let response = await pendingRequests.getResponse(requestId)
        if let _ = response as? BaseMessage {
            await pendingRequests.remove(id: requestId)
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
    
    public func retrieveStates() async throws -> [EntityState] {
        return try await sendCommandAndAwaitResponse(.retrieveStates)
    }
    
    private func sendCommandAndAwaitResponse<T: Codable>(_ type: CommandType) async throws -> [T] {
        guard self.currentPhase == .authenticated else {
            throw HAClientError.authenticationRequired
        }
        
        let requestId = await pendingRequests.insert(type: type)
        messageExchange.sendMessage(
            payload: JSONCoding.serialize(Message(type: type, id: requestId))
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
        let deadline = Date().addingTimeInterval(5)
        while await !condition() {
            try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 20)
            if Date() > deadline {
                throw HAClientError.requestTimeout
            }
        }
    }
    
    // MARK: Message handling

    private func handleTextMessage(jsonString: String) async {
        NSLog("<< \(jsonString)")
        let jsonData = jsonString.data(using: .utf8)!
        
        guard let incomingMessage = JSONCoding.deserialize(jsonString) else {
            NSLog("Failed to deserialize \(jsonString)")
            return
        }

        switch currentPhase {
        case .initial:
            currentPhase = .authRequested
            return
            
        case .authRequested:
            currentPhase = handleAuthenticationMessage(incomingMessage)
            return
            
        case .authenticated:
            switch incomingMessage {
            case let resultMessage as BaseResultMessage:
                guard resultMessage.success else {
                    NSLog("Command was not successful. JSON: %@", jsonString)
                    return
                }
                do {
                    try await handleMessage(message: resultMessage, jsonData: jsonData)
                } catch {
                    NSLog("Message could not be handled. JSON %@", jsonString)
                }
                
            case let resultMessage as PongMessage:
                await handlePong(resultMessage, jsonData: jsonData)
                
            default:
                NSLog("Unknown message encountered. JSON: %s", jsonString)
                break
            }

        default:
            NSLog("Not handling message. JSON: %s", jsonString)
            return
        }
    }
    
    private func handleAuthenticationMessage(_ message: Any) -> Phase {
        switch message {
        case _ as AuthOkMessage:
            return .authenticated
            
        case let authInvalidMessage as AuthInvalidMessage:
            messageExchange.disconnect()
            return .authenticationFailure(failureReason: authInvalidMessage.message)
            
        default:
            return currentPhase
        }
    }
    
    private func handleMessage(message: BaseResultMessage, jsonData: Data) async throws {
        guard let matchingRequestType = await pendingRequests.getType(message.id) else {
            NSLog("No matching request found with ID %@", message.id)
            return
        }
        guard let response = JSONCoding.deserializeCommandResponse(
            type: matchingRequestType,
            jsonData: jsonData
        ) else {
            NSLog("Response for request %i with type %s could not be decoded", message.id, message.type)
            throw HAClientError.responseError
        }
        await pendingRequests.addResponse(id: message.id, response)
    }
    
    private func handlePong(_ message: PongMessage, jsonData: Data) async {
        guard let _ = await pendingRequests.getType(message.id) else {
            NSLog("No matching request found with ID %@", message.id)
            return
        }
        if let response = JSONCoding.deserializeCommandResponse(
            type: .ping,
            jsonData: jsonData
        ) {
            await pendingRequests.addResponse(id: message.id, response)
        }
    }
}
