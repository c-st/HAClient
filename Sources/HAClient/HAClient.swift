import Foundation

protocol MessageExchange {
    func setMessageHandler(_ messageHandler: @escaping ((String) -> Void))
    func sendMessage(message: String)
    func ping()
    func disconnect()
}

enum HAClientError: Error {
    case authenticationFailed(String)
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

    private func handleTextMessage(jsonString: String) {
        print("Client received message from websocket \(jsonString)")

        let incomingMessage = JSONHandler.deserialize(jsonString)
        switch currentPhase {
        case let .pendingAuth(completion, onFailure):
            switch incomingMessage {
            case _ as AuthOkMessage:
                currentPhase = .authenticated(0)
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
            switch incomingMessage {
            default:
                print("Msg while authenticated", incomingMessage!)
            }

        default:
            print("Ignoring text message", jsonString)
        }
    }
}
