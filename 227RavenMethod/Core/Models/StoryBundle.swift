import Foundation

struct StoryBundle: Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    var anchorEvent: TimelineEvent?
    var journals: [JournalEntry]
    var favorites: [MediaHighlightItem]
    var sharedTags: [String]
    var updatedAt: Date
}

struct GraphSearchResult: Identifiable, Equatable {
    enum ResultKind {
        case journal
        case event
        case favorite
        case collection
        case story
    }

    var id: String
    var kind: ResultKind
    var title: String
    var subtitle: String
    var ref: GraphNodeRef?
    var storyEventID: String?
    var collectionID: String?
}

struct TagStat: Identifiable, Equatable {
    var id: String { tag }
    var tag: String
    var count: Int
}

struct ActivityDayStat: Identifiable, Equatable {
    var id: String { dateKey }
    var date: Date
    var dateKey: String
    var count: Int
}

struct InsightSuggestion: Identifiable, Equatable {
    var id: String
    var message: String
    var symbolName: String
}

struct TrendingTheme: Identifiable, Equatable {
    var id: String { title }
    var title: String
    var count: Int
    var sampleSymbol: String
}
