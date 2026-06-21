import Foundation

enum MediaGraphService {
    static func journals(forEventID eventID: String, store: AppStorage) -> [JournalEntry] {
        let journalIDs = store.graphLinks
            .filter { $0.kind == .journalEvent && $0.secondaryID == eventID }
            .map(\.primaryID)
        return store.mediaJournals.filter { journalIDs.contains($0.id) }
    }

    static func favorites(forEventID eventID: String, store: AppStorage) -> [MediaHighlightItem] {
        let favoriteIDs = store.graphLinks
            .filter { $0.kind == .eventFavorite && $0.primaryID == eventID }
            .map(\.secondaryID)
        return favoriteIDs.compactMap { id in
            SampleMediaCatalog.items.first { $0.id == id }
        }
    }

    static func favorites(forJournalID journalID: String, store: AppStorage) -> [MediaHighlightItem] {
        let favoriteIDs = store.graphLinks
            .filter { $0.kind == .journalFavorite && $0.primaryID == journalID }
            .map(\.secondaryID)
        return favoriteIDs.compactMap { id in
            SampleMediaCatalog.items.first { $0.id == id }
        }
    }

    static func event(forJournalID journalID: String, store: AppStorage) -> TimelineEvent? {
        guard let eventID = store.graphLinks.first(where: {
            $0.kind == .journalEvent && $0.primaryID == journalID
        })?.secondaryID else { return nil }
        return store.events.first { $0.id == eventID }
    }

    static func sharedTags(journals: [JournalEntry], favorites: [MediaHighlightItem]) -> [String] {
        let journalTags = Set(journals.flatMap(\.tags).map { $0.lowercased() })
        let favoriteWords = Set(
            favorites.flatMap { $0.title.split(separator: " ").map { String($0).lowercased() } }
        )
        return Array(journalTags.intersection(favoriteWords)).sorted()
    }

    static func allSharedTags(journals: [JournalEntry]) -> [String] {
        let counts = journals.flatMap(\.tags).reduce(into: [String: Int]()) { partial, tag in
            let key = tag.lowercased()
            partial[key, default: 0] += 1
        }
        return counts.filter { $0.value > 1 }.map(\.key).sorted()
    }

    static func story(for event: TimelineEvent, store: AppStorage) -> StoryBundle {
        let journals = journals(forEventID: event.id, store: store)
        let eventFavorites = favorites(forEventID: event.id, store: store)
        let linkedJournalFavorites = journals.flatMap { favorites(forJournalID: $0.id, store: store) }
        let mergedFavorites = uniqueFavorites(eventFavorites + linkedJournalFavorites)
        let tags = Array(Set(journals.flatMap(\.tags) + sharedTags(journals: journals, favorites: mergedFavorites))).sorted()

        return StoryBundle(
            id: event.id,
            title: event.title,
            subtitle: event.description.isEmpty ? event.date.formatted(date: .abbreviated, time: .omitted) : event.description,
            anchorEvent: event,
            journals: journals,
            favorites: mergedFavorites,
            sharedTags: tags,
            updatedAt: event.date
        )
    }

    static func allStories(store: AppStorage) -> [StoryBundle] {
        store.events
            .sorted { $0.date > $1.date }
            .map { story(for: $0, store: store) }
    }

    static func search(query: String, store: AppStorage) -> [GraphSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let needle = trimmed.lowercased()
        var results: [GraphSearchResult] = []

        for journal in store.mediaJournals where matches(needle, in: journal.caption, tags: journal.tags) {
            results.append(
                GraphSearchResult(
                    id: "journal-\(journal.id)",
                    kind: .journal,
                    title: journal.caption,
                    subtitle: journal.tags.map { "#\($0)" }.joined(separator: " "),
                    ref: .journal(journal.id),
                    storyEventID: event(forJournalID: journal.id, store: store)?.id,
                    collectionID: nil
                )
            )
        }

        for event in store.events where matches(needle, in: event.title, extra: event.description) {
            results.append(
                GraphSearchResult(
                    id: "event-\(event.id)",
                    kind: .event,
                    title: event.title,
                    subtitle: event.date.formatted(date: .abbreviated, time: .omitted),
                    ref: .event(event.id),
                    storyEventID: event.id,
                    collectionID: nil
                )
            )
        }

        for item in SampleMediaCatalog.items where item.title.lowercased().contains(needle) {
            results.append(
                GraphSearchResult(
                    id: "favorite-\(item.id)",
                    kind: .favorite,
                    title: item.title,
                    subtitle: store.isFavorite(item.id) ? "Favorite" : "Highlight",
                    ref: .favorite(item.id),
                    storyEventID: nil,
                    collectionID: nil
                )
            )
        }

        for collection in store.collections where collection.name.lowercased().contains(needle) {
            results.append(
                GraphSearchResult(
                    id: "collection-\(collection.id)",
                    kind: .collection,
                    title: collection.name,
                    subtitle: "\(CollectionRulesEngine.resolvedItems(for: collection, store: store).count) items",
                    ref: nil,
                    storyEventID: nil,
                    collectionID: collection.id
                )
            )
        }

        for story in allStories(store: store) where story.title.lowercased().contains(needle)
            || story.sharedTags.contains(where: { $0.lowercased().contains(needle) }) {
            results.append(
                GraphSearchResult(
                    id: "story-\(story.id)",
                    kind: .story,
                    title: story.title,
                    subtitle: "\(story.journals.count) journals · \(story.favorites.count) favorites",
                    ref: .event(story.id),
                    storyEventID: story.id,
                    collectionID: nil
                )
            )
        }

        return results
    }

    static func collectionItems(for collection: CuratorCollection, store: AppStorage) -> [GraphNodeRef] {
        CollectionRulesEngine.resolvedItems(for: collection, store: store)
    }

    private static func uniqueFavorites(_ items: [MediaHighlightItem]) -> [MediaHighlightItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    private static func matches(_ needle: String, in text: String, tags: [String] = [], extra: String = "") -> Bool {
        if text.lowercased().contains(needle) { return true }
        if extra.lowercased().contains(needle) { return true }
        return tags.contains { $0.lowercased().contains(needle) }
    }
}

enum CollectionRulesEngine {
    static func resolvedItems(for collection: CuratorCollection, store: AppStorage) -> [GraphNodeRef] {
        var refs = collection.manualRefs
        var seen = Set(refs.map(\.nodeID))

        if !collection.ruleTags.isEmpty {
            let normalizedTags = Set(collection.ruleTags.map { $0.lowercased() })
            for journal in store.mediaJournals {
                let journalTags = Set(journal.tags.map { $0.lowercased() })
                guard !journalTags.intersection(normalizedTags).isEmpty else { continue }
                if let ruleDate = collection.ruleAfterDate, journal.date < ruleDate { continue }
                let ref = GraphNodeRef.journal(journal.id)
                if seen.insert(ref.nodeID).inserted {
                    refs.append(ref)
                }
            }

            for favorite in store.favoriteMedia {
                guard let item = SampleMediaCatalog.items.first(where: { $0.id == favorite }) else { continue }
                let words = Set(item.title.split(separator: " ").map { String($0).lowercased() })
                guard !words.intersection(normalizedTags).isEmpty else { continue }
                let ref = GraphNodeRef.favorite(favorite)
                if seen.insert(ref.nodeID).inserted {
                    refs.append(ref)
                }
            }
        }

        return refs
    }
}

enum InsightsEngine {
    static func topTags(days: Int, store: AppStorage) -> [TagStat] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let counts = store.mediaJournals
            .filter { $0.date >= cutoff }
            .flatMap(\.tags)
            .reduce(into: [String: Int]()) { partial, tag in
                let key = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else { return }
                partial[key, default: 0] += 1
            }
        return counts
            .map { TagStat(tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    static func activityHeatmap(days: Int, store: AppStorage) -> [ActivityDayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<days).reversed().compactMap { offset -> ActivityDayStat? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let next = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let journalCount = store.mediaJournals.filter { $0.date >= date && $0.date < next }.count
            let eventCount = store.events.filter { $0.date >= date && $0.date < next }.count
            let reviewCount = store.weeklyReviewRecords.filter { $0.completedAt >= date && $0.completedAt < next }.count
            let key = date.formatted(.iso8601.year().month().day())
            return ActivityDayStat(date: date, dateKey: key, count: journalCount + eventCount + reviewCount)
        }
    }

    static func trendingThemes(store: AppStorage) -> [TrendingTheme] {
        let favorites = store.favoriteMedia.compactMap { id in
            SampleMediaCatalog.items.first { $0.id == id }
        }
        let grouped = favorites.reduce(into: [String: (count: Int, symbol: String)]()) { partial, item in
            let theme = item.title.split(separator: " ").first.map(String.init) ?? item.title
            let current = partial[theme]?.count ?? 0
            partial[theme] = (current + 1, item.symbolName)
        }
        return grouped
            .map { TrendingTheme(title: $0.key, count: $0.value.count, sampleSymbol: $0.value.symbol) }
            .sorted { $0.count > $1.count }
    }

    static func suggestions(store: AppStorage) -> [InsightSuggestion] {
        var items: [InsightSuggestion] = []
        let allTags = Set(store.mediaJournals.flatMap(\.tags).map { $0.lowercased() })

        for tag in allTags {
            guard let lastUsed = store.mediaJournals
                .filter({ $0.tags.map { $0.lowercased() }.contains(tag) })
                .map(\.date)
                .max() else { continue }
            let days = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
            if days >= 30 {
                items.append(
                    InsightSuggestion(
                        id: "tag-\(tag)",
                        message: "You haven't tagged \(tag.capitalized) in \(days) days.",
                        symbolName: "tag.slash"
                    )
                )
            }
        }

        if store.mediaJournals.isEmpty && store.events.isEmpty {
            items.append(
                InsightSuggestion(
                    id: "start",
                    message: "Start your graph by adding a journal entry and linking it to a timeline event.",
                    symbolName: "point.topleft.down.curvedto.point.bottomright.up"
                )
            )
        }

        if store.graphLinks.isEmpty, !store.mediaJournals.isEmpty, !store.events.isEmpty {
            items.append(
                InsightSuggestion(
                    id: "link",
                    message: "Connect journals to timeline events to build richer stories.",
                    symbolName: "link"
                )
            )
        }

        if store.reviewsCompleted == 0 {
            items.append(
                InsightSuggestion(
                    id: "review",
                    message: "Try a Weekly Review to organize the past seven days.",
                    symbolName: "calendar.badge.clock"
                )
            )
        }

        return items
    }
}
