import Foundation

struct CuratorCollection: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var coverStyleIndex: Int
    var manualRefs: [GraphNodeRef]
    var ruleTags: [String]
    var ruleAfterDate: Date?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        coverStyleIndex: Int = 0,
        manualRefs: [GraphNodeRef] = [],
        ruleTags: [String] = [],
        ruleAfterDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.coverStyleIndex = coverStyleIndex
        self.manualRefs = manualRefs
        self.ruleTags = ruleTags
        self.ruleAfterDate = ruleAfterDate
        self.createdAt = createdAt
    }
}
