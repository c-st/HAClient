import Foundation

public protocol HAClientProtocol {
    init(messageExchange: MessageExchange)
    
    func authenticate(token: String) async throws -> Void
    func sendPing() async throws -> Void
    func reconnect() async throws -> Void
    
    // Registry
    func listAreas() async throws -> [Area]
    func listDevices() async throws -> [Device]
    func listEntities() async throws -> [Entity]
    func retrieveStates() async throws -> [State]
}

public protocol MessageExchange {
    func connect(
        messageHandler: @escaping ((String) async -> Void),
        errorHandler: @escaping ((Error) async -> Void)
    )
    func sendMessage(message: String) async throws
    func disconnect()
}

enum HAClientError: Error {
    case authenticationFailed(String)
    case authenticationRequired
    case responseError
    case requestTimeout
}
