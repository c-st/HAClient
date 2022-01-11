import Foundation

public protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void))
    func sendMessage(message: String)
    func disconnect()
}

enum HAClientError: Error {
    case authenticationFailed(String)
    case wrongPhase(String)
    case requestTimeout
}

public protocol HAClientProtocol {
    init(messageExchange: MessageExchange)
    func authenticate(token: String) async throws -> Void
    func requestRegistry()
    func requestStates()
}

public class HAClient: HAClientProtocol {
    typealias RequestID = Int

    struct PendingRequest {
        let id: RequestID
        let type: ResultType
    }

    enum Phase: Equatable {
        case initial
        case authRequested
        case authenticated
        case authenticationFailure(failureReason: String)
    }
    
    var currentPhase: Phase = .initial
    
    public let registry: Registry
    private let messageExchange: MessageExchange

    private var lastUsedRequestId: Int?
    private var pendingRequests: [RequestID: PendingRequest] = [:]

    public required init(messageExchange: MessageExchange) {
        registry = Registry()
        self.messageExchange = messageExchange
        self.messageExchange.setMessageHandler(self.handleTextMessage(jsonString:))
    }

    public func authenticate(token: String) async throws -> Void {
        currentPhase = .authRequested
        messageExchange.sendMessage(
            message: JSONCoding.serialize(AuthMessage(accessToken: token))
        )
        
        // Block until phase is updated
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1)
        while currentPhase == .authRequested {
            let nextTime = Date().addingTimeInterval(0.1)
            RunLoop.current.run(until: nextTime)
            if nextTime > endTime {
                throw HAClientError.requestTimeout
            }
        }
        
        switch currentPhase {
        case .authenticationFailure(let failureReason):
            throw HAClientError.authenticationFailed(failureReason)
        default:
            return
        }
    }

    public func requestRegistry() {
        let fetchAreasRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestAreaRegistry(id: fetchAreasRequestId))
        )
        pendingRequests[fetchAreasRequestId] = PendingRequest(
            id: fetchAreasRequestId,
            type: .listAreas
        )

        let fetchDevicesRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestDeviceRegistry(id: fetchDevicesRequestId))
        )
        pendingRequests[fetchDevicesRequestId] = PendingRequest(
            id: fetchDevicesRequestId,
            type: .listDevices
        )

        let fetchEntitiesRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestEntityRegistry(id: fetchEntitiesRequestId))
        )
        pendingRequests[fetchEntitiesRequestId] = PendingRequest(
            id: fetchEntitiesRequestId,
            type: .listEntities
        )
    }

    public func requestStates() {
        let fetchStatesRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestCurrentStates(id: fetchStatesRequestId))
        )
        pendingRequests[fetchStatesRequestId] = PendingRequest(
            id: fetchStatesRequestId,
            type: .currentStates
        )
    }

    private func getAndIncrementId() -> Int {
        let id = (lastUsedRequestId ?? 0) + 1
        lastUsedRequestId = id
        return id
    }

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
            print("Not authenticated. Ignoring message", message)
            return currentPhase
        }
    }

    private func handleMessage(message: BaseResultMessage, jsonData: Data) {
        guard let matchingRequest = pendingRequests[message.id] else {
            print("No matching request found with this ID", message.id)
            return
        }

        switch matchingRequest.type {
        case .listAreas:
            if let message = try? JSON.decoder.decode(ListAreasResultMessage.self, from: jsonData) {
                registry.handleResultMessage(message)
            }
        case .listDevices:
            if let message = try? JSON.decoder.decode(ListDevicesResultMessage.self, from: jsonData) {
                registry.handleResultMessage(message)
            }
        case .listEntities:
            if let message = try? JSON.decoder.decode(ListEntitiesResultMessage.self, from: jsonData) {
                registry.handleResultMessage(message)
            }
        case .currentStates:
            if let message = try? JSON.decoder.decode(CurrentStatesResultMessage.self, from: jsonData) {
                registry.handleResultMessage(message)
            }
        }

        pendingRequests.removeValue(forKey: message.id)
    }
}
