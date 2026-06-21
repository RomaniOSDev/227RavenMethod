import Combine
import Foundation

struct HomePhotoTile: Identifiable, Equatable {
    let id: String
    let photoData: Data?
    let styleIndex: Int
    let caption: String
    let source: String
}

final class HomeViewModel: ObservableObject {
    struct QuickStat {
        let value: String
        let label: String
        let symbol: String
    }

    func greeting(for date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    func photoTiles(from store: AppStorage, limit: Int = 4) -> [HomePhotoTile] {
        var tiles: [HomePhotoTile] = []

        for journal in store.mediaJournals.prefix(limit) {
            tiles.append(
                HomePhotoTile(
                    id: "journal-\(journal.id)",
                    photoData: journal.photoData,
                    styleIndex: journal.thumbnailStyle,
                    caption: journal.caption,
                    source: "Journal"
                )
            )
        }

        if tiles.count < limit {
            for favoriteID in store.favoriteMedia {
                guard tiles.count < limit else { break }
                guard let item = SampleMediaCatalog.items.first(where: { $0.id == favoriteID }) else { continue }
                tiles.append(
                    HomePhotoTile(
                        id: "favorite-\(item.id)",
                        photoData: nil,
                        styleIndex: item.styleIndex,
                        caption: item.title,
                        source: "Favorite"
                    )
                )
            }
        }

        if tiles.count < limit {
            for item in SampleMediaCatalog.items.prefix(limit - tiles.count) {
                tiles.append(
                    HomePhotoTile(
                        id: "sample-\(item.id)",
                        photoData: nil,
                        styleIndex: item.styleIndex,
                        caption: item.title,
                        source: "Highlight"
                    )
                )
            }
        }

        return tiles
    }

    func quickStats(from store: AppStorage) -> [QuickStat] {
        [
            QuickStat(value: "\(store.streakDays)", label: "Day Streak", symbol: "flame.fill"),
            QuickStat(value: "\(store.graphLinks.count)", label: "Graph Links", symbol: "link"),
            QuickStat(value: "\(store.reviewsCompleted)", label: "Reviews", symbol: "checkmark.seal.fill"),
            QuickStat(value: "\(store.collections.count)", label: "Collections", symbol: "folder.fill")
        ]
    }

    func topTag(from store: AppStorage) -> TagStat? {
        InsightsEngine.topTags(days: 7, store: store).first
    }

    func latestJournal(from store: AppStorage) -> JournalEntry? {
        store.mediaJournals.first
    }

    func upcomingEvent(from store: AppStorage) -> TimelineEvent? {
        store.events.sorted { $0.date > $1.date }.first
    }

    func featuredStory(from store: AppStorage) -> StoryBundle? {
        store.stories().max { lhs, rhs in
            lhs.journals.count + lhs.favorites.count < rhs.journals.count + rhs.favorites.count
        }
    }

    func shouldPromptWeeklyReview(from store: AppStorage) -> Bool {
        guard let last = store.weeklyReviewRecords.first?.completedAt else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 7
    }
}
