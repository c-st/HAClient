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
    typealias VoidCompletionHandler = () -> Void
    typealias AuthFailureHandler = (String) -> Void
    typealias CurrentRequestID = Int

    var currentPhase: Phase?

    private var messageExchange: MessageExchange
    private var lastUsedRequestId: Int?
    
    let registry: Registry

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
    }

    func authenticate(token: String, completion: @escaping () -> Void, onFailure: @escaping (_ errorMessage: String) -> Void) {
        currentPhase = .pendingAuth(completion, onFailure)
        messageExchange.setMessageHandler(handleTextMessage(jsonString:))
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
            switch incomingMessage {
            case _ as AuthOkMessage:
                currentPhase = .authenticated
                completion()
                break
            case let authInvalidMessage as AuthInvalidMessage:
                currentPhase = nil
                messageExchange.disconnect()
                onFailure(authInvalidMessage.message)
            default:
                print("Ignoring message", jsonString)
            }

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

    private func handleRegistryPopulationMessage(requestId: Int, pendingRequests: Array<PendingRequest>, jsonData: Data, completion: @escaping VoidCompletionHandler) -> Phase? {
        guard let matchingRequest = pendingRequests.first(where: { $0.id == requestId }) else {
            print("No matching request found with this ID", requestId)
            return currentPhase
        }

        switch matchingRequest.type {
        case .listAreas:
            if let message = try? JSON.decoder.decode(ListAreasResultMessage.self, from: jsonData) {
                self.registry.handleResultMessage(message)
            }
        case .listDevices:
            break
        case .listEntities:
            break
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
