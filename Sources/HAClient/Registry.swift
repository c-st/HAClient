import Foundation

struct Area {
    let id: String
    let name: String
}

class Registry {
    private(set) var areas: [Area] = []

    func handleResultMessage(_ resultMessage: Any) {
        switch resultMessage {
        case let message as ListAreasResultMessage:
            areas = message.result.map { Area(id: $0.areaId, name: $0.name) }
            break
        default:
            break
        }
    }

    // devices
    // entities
}
