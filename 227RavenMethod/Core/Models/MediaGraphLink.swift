import Foundation

struct MediaGraphLink: Identifiable, Codable, Equatable {
    enum LinkKind: String, Codable {
        case journalEvent
        case journalFavorite
        case eventFavorite
    }

    var id: String
    var kind: LinkKind
    var primaryID: String
    var secondaryID: String

    init(
        id: String = UUID().uuidString,
        kind: LinkKind,
        primaryID: String,
        secondaryID: String
    ) {
        self.id = id
        self.kind = kind
        self.primaryID = primaryID
        self.secondaryID = secondaryID
    }
}
