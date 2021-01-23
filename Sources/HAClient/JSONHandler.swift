import Foundation

final class JSONHandler {
    static func serialize(_ message: Encodable) -> String {
        let data = try! JSONSerialization.data(
            withJSONObject: message.asDictionary,
            options: .sortedKeys
        )

        return String(decoding: data, as: UTF8.self)
    }
    
    static func deserialize(_ jsonString: String) -> Any? {
        let jsonData = jsonString.data(using: .utf8)!
        let baseEvent = try! JSON.decoder.decode(BaseMessage.self, from: jsonData)
        
        switch baseEvent.type {
        case .auth_required:
            return try? JSON.decoder.decode(AuthRequired.self, from: jsonData)
        case .auth_ok:
            return try? JSON.decoder.decode(AuthOkMessage.self, from: jsonData)
        case .auth_invalid:
            return try? JSON.decoder.decode(AuthInvalidMessage.self, from: jsonData)
        }
    }
}

extension Encodable {
    subscript(key: String) -> Any? {
        return asDictionary[key]
    }

    var asDictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}

struct JSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
