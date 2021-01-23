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
    private var registry: Registry

    enum Phase {
        case pendingAuth(VoidCompletionHandler, AuthFailureHandler)
        case authenticated(CurrentRequestID)
        case pendingRegistryPopulation(VoidCompletionHandler, Int?, Int?, Int?)
    }

    init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
        registry = Registry()
    }

    func authenticate(token: String, completion: @escaping () -> Void, onFailure: @escaping (_ errorMessage: String) -> Void) {
        currentPhase = .pendingAuth(completion, onFailure)
        messageExchange.setMessageHandler(handleTextMessage(jsonString:))
        messageExchange.sendMessage(
            message: JSONHandler.serialize(AuthMessage(accessToken: token))
        )
    }

    func populateRegistry(_ completion: @escaping () -> Void) {
        do {
            let fetchAreasRequestId = try getAndIncrementId()
            messageExchange.sendMessage(
                message: JSONHandler.serialize(RequestAreaRegistry(id: fetchAreasRequestId))
            )

            let fetchDevicesRequestId = try getAndIncrementId()
            messageExchange.sendMessage(
                message: JSONHandler.serialize(RequestDeviceRegistry(id: fetchDevicesRequestId))
            )

            let fetchEntitiesRequestId = try getAndIncrementId()
            messageExchange.sendMessage(
                message: JSONHandler.serialize(RequestEntityRegistry(id: fetchEntitiesRequestId))
            )

            currentPhase = .pendingRegistryPopulation(
                completion,
                fetchAreasRequestId,
                fetchDevicesRequestId,
                fetchEntitiesRequestId
            )
        } catch {
            print("There was an error requesting registry information", error)
        }
    }

    private func getAndIncrementId() throws -> Int {
        switch currentPhase {
        case let .authenticated(currentId):
            currentPhase = .authenticated(currentId + 1)
            return currentId
        default:
            throw HAClientError.wrongPhase("Can only send commands when authenticated")
        }
    }

    private func handleTextMessage(jsonString: String) {
        let incomingMessage = JSONHandler.deserialize(jsonString)

        switch currentPhase {
        case let .pendingAuth(completion, onFailure):
            switch incomingMessage {
            case _ as AuthOkMessage:
                currentPhase = .authenticated(1)
                completion()
                break
            case let authInvalidMessage as AuthInvalidMessage:
                currentPhase = nil
                messageExchange.disconnect()
                onFailure(authInvalidMessage.message)
            default:
                print("Ignoring message", jsonString)
            }

        case let .pendingRegistryPopulation(completion, areaRequestId, deviceRequestId, entityRequestId):
            switch incomingMessage {
            case let resultMessage as ResultMessage:
                if !resultMessage.success {
                    currentPhase = .none
                } else {
                    switch resultMessage.id {
                    case let id where id == areaRequestId:
                        currentPhase = .pendingRegistryPopulation(completion, nil, deviceRequestId, entityRequestId)
                    // TODO: handle areas
                    case let id where id == deviceRequestId:
                        currentPhase = .pendingRegistryPopulation(completion, areaRequestId, nil, entityRequestId)
                    // TODO: handle devices
                    case let id where id == entityRequestId:
                        currentPhase = .pendingRegistryPopulation(completion, areaRequestId, deviceRequestId, nil)
                    // TODO: handle entities
                    default:
                        print("Unknown response id \(resultMessage.id)")
                    }

                    switch currentPhase {
                    case let .pendingRegistryPopulation(completion, nil, nil, nil):
                        let newId = max(areaRequestId ?? 0, deviceRequestId ?? 0, entityRequestId ?? 0) + 1
                        currentPhase = .authenticated(newId)
                        completion()
                        break
                    default:
                        break
                    }
                }
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
}
