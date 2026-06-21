import Foundation

struct MediaHighlightItem: Identifiable, Equatable {
    let id: String
    let title: String
    let styleIndex: Int
    let symbolName: String
}

enum SampleMediaCatalog {
    static let items: [MediaHighlightItem] = [
        MediaHighlightItem(id: "hl_01", title: "Sunset Walk", styleIndex: 0, symbolName: "sun.max.fill"),
        MediaHighlightItem(id: "hl_02", title: "City Lights", styleIndex: 1, symbolName: "building.2.fill"),
        MediaHighlightItem(id: "hl_03", title: "Ocean Breeze", styleIndex: 2, symbolName: "water.waves"),
        MediaHighlightItem(id: "hl_04", title: "Mountain Trail", styleIndex: 3, symbolName: "mountain.2.fill"),
        MediaHighlightItem(id: "hl_05", title: "Garden Bloom", styleIndex: 4, symbolName: "leaf.fill"),
        MediaHighlightItem(id: "hl_06", title: "Coffee Moment", styleIndex: 5, symbolName: "cup.and.saucer.fill"),
        MediaHighlightItem(id: "hl_07", title: "Rainy Day", styleIndex: 6, symbolName: "cloud.rain.fill"),
        MediaHighlightItem(id: "hl_08", title: "Starlit Night", styleIndex: 7, symbolName: "moon.stars.fill"),
        MediaHighlightItem(id: "hl_09", title: "Family Gathering", styleIndex: 8, symbolName: "person.3.fill"),
        MediaHighlightItem(id: "hl_10", title: "Creative Studio", styleIndex: 9, symbolName: "paintbrush.fill"),
        MediaHighlightItem(id: "hl_11", title: "Weekend Trip", styleIndex: 10, symbolName: "car.fill"),
        MediaHighlightItem(id: "hl_12", title: "Quiet Reading", styleIndex: 11, symbolName: "book.fill")
    ]
}
