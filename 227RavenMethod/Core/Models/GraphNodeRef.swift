import Foundation

struct GraphNodeRef: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        case journal
        case event
        case favorite
    }

    var kind: Kind
    var id: String

    var nodeID: String { "\(kind.rawValue):\(id)" }

    static func journal(_ id: String) -> GraphNodeRef {
        GraphNodeRef(kind: .journal, id: id)
    }

    static func event(_ id: String) -> GraphNodeRef {
        GraphNodeRef(kind: .event, id: id)
    }

    static func favorite(_ id: String) -> GraphNodeRef {
        GraphNodeRef(kind: .favorite, id: id)
    }
}
