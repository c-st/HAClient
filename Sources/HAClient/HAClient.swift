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
    private var messageExchange: MessageExchange

    typealias AuthCompletionHandler = () -> Void
    typealias AuthFailureHandler = (String) -> Void
    typealias CurrentRequestID = Int

    enum Phase {
        case pendingAuth(AuthCompletionHandler, AuthFailureHandler)
        case authenticated(CurrentRequestID)
    }

    init(messageExchange: MessageExchange) {
        self.messageExchange = messageExchange
    }

    func authenticate(token: String, completion: @escaping () -> Void, onFailure: @escaping (_ errorMessage: String) -> Void) {
        currentPhase = .pendingAuth(completion, onFailure)
        messageExchange.setMessageHandler(handleTextMessage(jsonString:))
        messageExchange.sendMessage(
            message: JSONHandler.serialize(AuthMessage(accessToken: token))
        )
    }

    func populateRegistry() {
        do {
            try messageExchange.sendMessage(message: JSONHandler.serialize(RequestAreaRegistry(id: getAndIncrementId())))

            try messageExchange.sendMessage(message: JSONHandler.serialize(RequestDeviceRegistry(id: getAndIncrementId())))

            try messageExchange.sendMessage(message: JSONHandler.serialize(RequestEntityRegistry(id: getAndIncrementId())))
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

    private func sendCommand(commandObject: Encodable) {
        messageExchange.sendMessage(
            message: JSONHandler.serialize(commandObject)
        )
    }

    private func handleTextMessage(jsonString: String) {
        let incomingMessage = JSONHandler.deserialize(jsonString)

        switch currentPhase {
        case let .pendingAuth(completion, onFailure):
            switch incomingMessage {
            case _ as AuthOkMessage:
                currentPhase = .authenticated(1)
                print("Authentication successful")
                completion()
                break
            case let authInvalidMessage as AuthInvalidMessage:
                currentPhase = nil
                messageExchange.disconnect()
                onFailure(authInvalidMessage.message)
            default:
                print("Ignoring message", jsonString)
            }

        case .authenticated:
            if let _ = incomingMessage {
                // print("Message while authenticated", message)
            } else {
                print("Received unsupported message type", jsonString)
            }

        default:
            print("Ignoring text message", jsonString)
        }
    }
}
