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
    func listAreas() async throws -> [ListAreasResultMessage.Area]?
}

public class HAClient: HAClientProtocol {
    enum HAClientError: Error {
        case authenticationFailed(String)
        case wrongPhase(String)
        case requestTimeout
    }
    
    enum Phase: Equatable {
        case initial
        case authRequested
        case authenticated
        case authenticationFailure(failureReason: String)
    }
    private var currentPhase: Phase = .initial

    private let messageExchange: MessageExchange

    typealias RequestID = Int
    private var lastUsedRequestId: RequestID?
    private var pendingRequests: [RequestID: CommandType] = [:]
    private var responses: [RequestID: Any] = [:]

    public required init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(self.handleTextMessage(jsonString:))
    }
    
    // MARK: Commands

    public func authenticate(token: String) async throws -> Void {
        currentPhase = .authRequested
        messageExchange.sendMessage(
            message: JSONCoding.serialize(AuthMessage(accessToken: token))
        )
        
        try waitFor() {
            currentPhase != .authRequested
        }
        
        switch currentPhase {
        case .authenticationFailure(let failureReason):
            throw HAClientError.authenticationFailed(failureReason)
        default:
            return
        }
    }
    
    public func listAreas() async throws -> [ListAreasResultMessage.Area]? {
        let requestId = getAndIncrementId()
        pendingRequests[requestId] = .listAreas
        sendCommand(
            requestId,
            type: .listAreas,
            message: RequestAreaRegistry(id: requestId)
        )
        
        try waitFor() {
            responses[requestId] != nil
        }
        
        if let response = responses[requestId], let message = response as? ListAreasResultMessage {
            return message.result
        }
        
        return nil
    }
    
    private func sendCommand(_ requestId: RequestID, type: CommandType, message: Encodable) {
        messageExchange.sendMessage(
            message: JSONCoding.serialize(message)
        )
        pendingRequests[requestId] = type
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
                    print("Result was not successful", jsonString)
                    return
                }
                handleMessage(message: resultMessage, jsonData: jsonData)
            default:
                break
            }

        default:
            print("Ignoring text message", jsonString)
        }
    }
    
    private func handleMessage(message: BaseResultMessage, jsonData: Data) {
        guard let matchingRequestType = pendingRequests[message.id] else {
            print("No matching request found with this ID", message.id)
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
