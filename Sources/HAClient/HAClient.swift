import Foundation

protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void))
    func sendMessage(message: String)
    func ping()
    func disconnect()
}

enum HAClientError: Error {
    case authenticationFailed(String)
    case wrongPhase(String)
}

class HAClient {
    var currentPhase: Phase?
    let registry: Registry

    private var messageExchange: MessageExchange
    private var lastUsedRequestId: Int?

    typealias VoidCompletionHandler = () -> Void
    typealias AuthFailureHandler = (String) -> Void
    typealias CurrentRequestID = Int

    enum Phase {
        case pendingAuth(VoidCompletionHandler, AuthFailureHandler)
        case authenticated
        case pendingRegistryPopulation(VoidCompletionHandler, Array<PendingRequest>)
    }

    struct PendingRequest {
        let id: Int
        let type: ResultType
    }

    init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        registry = Registry()
        messageExchange.setMessageHandler(handleTextMessage(jsonString:))
    }

    func authenticate(token: String, completion: @escaping () -> Void, onFailure: @escaping (_ errorMessage: String) -> Void) {
        currentPhase = .pendingAuth(completion, onFailure)
        messageExchange.sendMessage(
            message: JSONCoding.serialize(AuthMessage(accessToken: token))
        )
    }

    func populateRegistry(_ completion: @escaping () -> Void) {
        let fetchAreasRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestAreaRegistry(id: fetchAreasRequestId))
        )

        let fetchDevicesRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestDeviceRegistry(id: fetchDevicesRequestId))
        )

        let fetchEntitiesRequestId = getAndIncrementId()
        messageExchange.sendMessage(
            message: JSONCoding.serialize(RequestEntityRegistry(id: fetchEntitiesRequestId))
        )

        currentPhase = .pendingRegistryPopulation(
            completion,
            [
                PendingRequest(id: fetchAreasRequestId, type: .listAreas),
                PendingRequest(id: fetchDevicesRequestId, type: .listDevices),
                PendingRequest(id: fetchEntitiesRequestId, type: .listEntities),
            ]
        )
    }

    private func getAndIncrementId() -> Int {
        let id = (lastUsedRequestId ?? 0) + 1
        lastUsedRequestId = id
        return id
    }

    private func handleTextMessage(jsonString: String) {
        let incomingMessage = JSONCoding.deserialize(jsonString)

        switch currentPhase {
        case let .pendingAuth(completion, onFailure):
            guard let message = incomingMessage else {
                return
            }
            currentPhase = handleAuthenticationMessage(
                message: message,
                completion: completion,
                onFailure: onFailure
            )

        case let .pendingRegistryPopulation(completion, pendingRequests):
            switch incomingMessage {
            case let resultMessage as BaseResultMessage:
                guard resultMessage.success else {
                    currentPhase = .none
                    return
                }
                currentPhase = handleRegistryPopulationMessage(
                    requestId: resultMessage.id,
                    pendingRequests: pendingRequests,
                    jsonData: jsonString.data(using: .utf8)!,
                    completion: completion
                )
            default:
                break
            }

        case .authenticated:
            if let message = incomingMessage {
                print("Message while authenticated", message)
            } else {
                print("Received unsupported message type", jsonString)
            }

        default:
            print("Ignoring text message", jsonString)
        }
    }

    private func handleAuthenticationMessage(message: Any, completion: @escaping VoidCompletionHandler, onFailure: @escaping AuthFailureHandler) -> Phase? {
        switch message {
        case _ as AuthOkMessage:
            completion()
            return .authenticated
        case let authInvalidMessage as AuthInvalidMessage:
            messageExchange.disconnect()
            onFailure(authInvalidMessage.message)
            return nil
        default:
            print("Ignoring message", message)
            return currentPhase
        }
    }

    private func handleRegistryPopulationMessage(requestId: Int, pendingRequests: Array<PendingRequest>, jsonData: Data, completion: @escaping VoidCompletionHandler) -> Phase? {
        guard let matchingRequest = pendingRequests.first(where: { $0.id == requestId }) else {
            print("No matching request found with this ID", requestId)
            return currentPhase
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
        }

        let remainingRequests = pendingRequests.filter({ $0.id != requestId })
        if remainingRequests.isEmpty {
            completion()
            return .authenticated
        } else {
            return .pendingRegistryPopulation(completion, remainingRequests)
        }
    }
}
