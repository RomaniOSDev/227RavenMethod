import Foundation

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: String
    var caption: String
    var date: Date
    var tags: [String]
    var thumbnailStyle: Int
    var photoData: Data?

    init(
        id: String = UUID().uuidString,
        caption: String,
        date: Date = Date(),
        tags: [String] = [],
        thumbnailStyle: Int = 0,
        photoData: Data? = nil
    ) {
        self.id = id
        self.caption = caption
        self.date = date
        self.tags = tags
        self.thumbnailStyle = thumbnailStyle
        self.photoData = photoData
    }
}
