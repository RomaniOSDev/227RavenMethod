import Foundation

struct TimelineEvent: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var description: String
    var date: Date
    var icon: String

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        date: Date = Date(),
        icon: String = "📅"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.icon = icon
    }
}
