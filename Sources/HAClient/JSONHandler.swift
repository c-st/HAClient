import Foundation

final class JSONHandler {
    static func serialize(_ message: Encodable) -> String {
        let data = try! JSONSerialization.data(
            withJSONObject: message.asDictionary,
            options: .sortedKeys
        )

        return String(decoding: data, as: UTF8.self)
    }
}

extension Encodable {
    subscript(key: String) -> Any? {
        return asDictionary[key]
    }

    var asDictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}
