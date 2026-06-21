import Foundation

struct WeeklyReviewRecord: Identifiable, Codable, Equatable {
    var id: String
    var completedAt: Date
    var reflection: String
    var journalIDs: [String]
    var eventID: String?
    var favoriteIDs: [String]
    var tagsAddedCount: Int

    init(
        id: String = UUID().uuidString,
        completedAt: Date = Date(),
        reflection: String,
        journalIDs: [String],
        eventID: String?,
        favoriteIDs: [String],
        tagsAddedCount: Int
    ) {
        self.id = id
        self.completedAt = completedAt
        self.reflection = reflection
        self.journalIDs = journalIDs
        self.eventID = eventID
        self.favoriteIDs = favoriteIDs
        self.tagsAddedCount = tagsAddedCount
    }
}
