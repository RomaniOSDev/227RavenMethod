import Combine
import Foundation

final class AppStorage: ObservableObject {
    static let shared = AppStorage()

    private enum Keys {
        static let hasSeenOnboarding = "sf_hasSeenOnboarding"
        static let totalSessionsCompleted = "sf_totalSessionsCompleted"
        static let totalMinutesUsed = "sf_totalMinutesUsed"
        static let streakDays = "sf_streakDays"
        static let lastActivityDate = "sf_lastActivityDate"
        static let achievementsUnlocked = "sf_achievementsUnlocked"
        static let events = "sf_events"
        static let lastOpenedEventID = "sf_lastOpenedEventID"
        static let mediaJournals = "sf_mediaJournals"
        static let lastOpenedDate = "sf_lastOpenedDate"
        static let draftCaption = "sf_draftCaption"
        static let favoriteMedia = "sf_favoriteMedia"
        static let highlightLastOpened = "sf_highlightLastOpened"
        static let showTutorial = "sf_showTutorial"
        static let visibleHighlightIDs = "sf_visibleHighlightIDs"
        static let graphLinks = "sf_graphLinks"
        static let collections = "sf_collections"
        static let reviewsCompleted = "sf_reviewsCompleted"
        static let weeklyReviewRecords = "sf_weeklyReviewRecords"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet {
            if let lastActivityDate {
                defaults.set(lastActivityDate, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveAchievements() }
    }

    @Published var events: [TimelineEvent] {
        didSet { saveEvents() }
    }

    @Published var lastOpenedEventID: String? {
        didSet {
            if let lastOpenedEventID {
                defaults.set(lastOpenedEventID, forKey: Keys.lastOpenedEventID)
            } else {
                defaults.removeObject(forKey: Keys.lastOpenedEventID)
            }
        }
    }

    @Published var mediaJournals: [JournalEntry] {
        didSet { saveJournals() }
    }

    @Published var lastOpenedDate: Date {
        didSet { defaults.set(lastOpenedDate, forKey: Keys.lastOpenedDate) }
    }

    @Published var draftCaption: String {
        didSet { defaults.set(draftCaption, forKey: Keys.draftCaption) }
    }

    @Published var favoriteMedia: [String] {
        didSet { defaults.set(favoriteMedia, forKey: Keys.favoriteMedia) }
    }

    @Published var highlightLastOpened: Date {
        didSet { defaults.set(highlightLastOpened, forKey: Keys.highlightLastOpened) }
    }

    @Published var showTutorial: Bool {
        didSet { defaults.set(showTutorial, forKey: Keys.showTutorial) }
    }

    @Published var visibleHighlightIDs: [String] {
        didSet { defaults.set(visibleHighlightIDs, forKey: Keys.visibleHighlightIDs) }
    }

    @Published var graphLinks: [MediaGraphLink] {
        didSet { saveGraphLinks() }
    }

    @Published var collections: [CuratorCollection] {
        didSet { saveCollections() }
    }

    @Published var reviewsCompleted: Int {
        didSet { defaults.set(reviewsCompleted, forKey: Keys.reviewsCompleted) }
    }

    @Published var weeklyReviewRecords: [WeeklyReviewRecord] {
        didSet { saveWeeklyReviewRecords() }
    }

    @Published private(set) var itemsAdded: Int = 0
    @Published private(set) var entriesWritten: Int = 0
    @Published private(set) var favouritesCount: Int = 0

    let bannerManager = AchievementBannerManager()

    private var sessionStartDate: Date?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        self.totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        self.totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        self.streakDays = defaults.integer(forKey: Keys.streakDays)
        self.lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        self.achievementsUnlocked = Self.loadAchievements(from: defaults, decoder: decoder)
        self.events = Self.loadEvents(from: defaults, decoder: decoder)
        self.lastOpenedEventID = defaults.string(forKey: Keys.lastOpenedEventID)
        self.mediaJournals = Self.loadJournals(from: defaults, decoder: decoder)
        self.lastOpenedDate = defaults.object(forKey: Keys.lastOpenedDate) as? Date ?? Date()
        self.draftCaption = defaults.string(forKey: Keys.draftCaption) ?? ""
        self.favoriteMedia = defaults.stringArray(forKey: Keys.favoriteMedia) ?? []
        self.highlightLastOpened = defaults.object(forKey: Keys.highlightLastOpened) as? Date ?? Date()
        self.showTutorial = defaults.object(forKey: Keys.showTutorial) as? Bool ?? true
        self.visibleHighlightIDs = defaults.stringArray(forKey: Keys.visibleHighlightIDs)
            ?? SampleMediaCatalog.items.prefix(8).map(\.id)
        self.graphLinks = Self.loadGraphLinks(from: defaults, decoder: decoder)
        self.collections = Self.loadCollections(from: defaults, decoder: decoder)
        self.reviewsCompleted = defaults.integer(forKey: Keys.reviewsCompleted)
        self.weeklyReviewRecords = Self.loadWeeklyReviewRecords(from: defaults, decoder: decoder)

        recalculateDerivedMetrics()

        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    var totalEntriesCreated: Int {
        events.count + mediaJournals.count
    }

    var journalsFromLastWeek: [JournalEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
        return mediaJournals.filter { $0.date >= cutoff }
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        recordMeaningfulAction()
    }

    func beginSessionIfNeeded() {
        guard sessionStartDate == nil else { return }
        sessionStartDate = Date()
        totalSessionsCompleted += 1
    }

    func endSession() {
        guard let sessionStartDate else { return }
        let elapsedMinutes = max(1, Int(Date().timeIntervalSince(sessionStartDate) / 60))
        totalMinutesUsed += elapsedMinutes
        self.sessionStartDate = nil
    }

    func recordMeaningfulAction() {
        updateStreak(for: Date())
        checkAchievements()
    }

    func addTimelineEvent(_ event: TimelineEvent) {
        events.append(event)
        lastOpenedEventID = event.id
        recalculateDerivedMetrics()
        recordMeaningfulAction()
        notifyNewAchievements()
    }

    func updateTimelineEvent(_ event: TimelineEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        lastOpenedEventID = event.id
        recalculateDerivedMetrics()
        recordMeaningfulAction()
    }

    func deleteTimelineEvent(id: String) {
        events.removeAll { $0.id == id }
        graphLinks.removeAll {
            ($0.kind == .journalEvent && $0.secondaryID == id) ||
            ($0.kind == .eventFavorite && $0.primaryID == id)
        }
        if lastOpenedEventID == id {
            lastOpenedEventID = events.last?.id
        }
        recalculateDerivedMetrics()
        checkAchievements()
    }

    func moveTimelineEvents(from source: IndexSet, to destination: Int) {
        var updated = events
        let moving = source.sorted().map { updated[$0] }
        for index in source.sorted().reversed() {
            updated.remove(at: index)
        }
        var target = destination
        for item in moving {
            updated.insert(item, at: min(target, updated.count))
            target += 1
        }
        events = updated
    }

    func addJournalEntry(_ entry: JournalEntry) {
        mediaJournals.insert(entry, at: 0)
        lastOpenedDate = Date()
        draftCaption = ""
        recalculateDerivedMetrics()
        recordMeaningfulAction()
        notifyNewAchievements()
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        guard let index = mediaJournals.firstIndex(where: { $0.id == entry.id }) else { return }
        mediaJournals[index] = entry
        recalculateDerivedMetrics()
        recordMeaningfulAction()
    }

    func deleteJournalEntry(id: String) {
        mediaJournals.removeAll { $0.id == id }
        graphLinks.removeAll {
            ($0.kind == .journalEvent && $0.primaryID == id) ||
            ($0.kind == .journalFavorite && $0.primaryID == id)
        }
        recalculateDerivedMetrics()
        checkAchievements()
    }

    func toggleFavorite(mediaID: String) {
        if let index = favoriteMedia.firstIndex(of: mediaID) {
            favoriteMedia.remove(at: index)
        } else {
            favoriteMedia.append(mediaID)
        }
        highlightLastOpened = Date()
        recalculateDerivedMetrics()
        recordMeaningfulAction()
        notifyNewAchievements()
    }

    func refreshHighlights() {
        let allIDs = SampleMediaCatalog.items.map(\.id)
        let shuffled = allIDs.shuffled()
        visibleHighlightIDs = Array(shuffled.prefix(8))
        highlightLastOpened = Date()
        FeedbackService.lightTap()
    }

    func isFavorite(_ mediaID: String) -> Bool {
        favoriteMedia.contains(mediaID)
    }

    func linkJournal(_ journalID: String, toEvent eventID: String?) {
        graphLinks.removeAll { $0.kind == .journalEvent && $0.primaryID == journalID }
        guard let eventID else { return }
        graphLinks.append(MediaGraphLink(kind: .journalEvent, primaryID: journalID, secondaryID: eventID))
        recordMeaningfulAction()
    }

    func linkJournal(_ journalID: String, toFavorite favoriteID: String, enabled: Bool) {
        graphLinks.removeAll { $0.kind == .journalFavorite && $0.primaryID == journalID && $0.secondaryID == favoriteID }
        if enabled {
            graphLinks.append(MediaGraphLink(kind: .journalFavorite, primaryID: journalID, secondaryID: favoriteID))
            if !isFavorite(favoriteID) {
                favoriteMedia.append(favoriteID)
            }
            recordMeaningfulAction()
        }
    }

    func linkEvent(_ eventID: String, toFavorite favoriteID: String, enabled: Bool) {
        graphLinks.removeAll { $0.kind == .eventFavorite && $0.primaryID == eventID && $0.secondaryID == favoriteID }
        if enabled {
            graphLinks.append(MediaGraphLink(kind: .eventFavorite, primaryID: eventID, secondaryID: favoriteID))
            if !isFavorite(favoriteID) {
                favoriteMedia.append(favoriteID)
            }
            recordMeaningfulAction()
        }
    }

    func searchGraph(_ query: String) -> [GraphSearchResult] {
        MediaGraphService.search(query: query, store: self)
    }

    func stories() -> [StoryBundle] {
        MediaGraphService.allStories(store: self)
    }

    func story(for eventID: String) -> StoryBundle? {
        guard let event = events.first(where: { $0.id == eventID }) else { return nil }
        return MediaGraphService.story(for: event, store: self)
    }

    func addCollection(_ collection: CuratorCollection) {
        collections.insert(collection, at: 0)
        recordMeaningfulAction()
    }

    func updateCollection(_ collection: CuratorCollection) {
        guard let index = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        collections[index] = collection
        recordMeaningfulAction()
    }

    func deleteCollection(id: String) {
        collections.removeAll { $0.id == id }
    }

    func completeWeeklyReview(
        reflection: String,
        journalIDs: [String],
        eventID: String?,
        favoriteIDs: [String],
        tagsAddedCount: Int
    ) {
        let record = WeeklyReviewRecord(
            reflection: reflection,
            journalIDs: journalIDs,
            eventID: eventID,
            favoriteIDs: favoriteIDs,
            tagsAddedCount: tagsAddedCount
        )
        weeklyReviewRecords.insert(record, at: 0)
        reviewsCompleted += 1

        if let eventID {
            for journalID in journalIDs {
                linkJournal(journalID, toEvent: eventID)
            }
            for favoriteID in favoriteIDs {
                linkEvent(eventID, toFavorite: favoriteID, enabled: true)
            }
        }

        recordMeaningfulAction()
        FeedbackService.success()
    }

    func isAchievementUnlocked(_ id: String) -> Bool {
        achievementsUnlocked[id] != nil
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        reloadFromDefaults()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadAchievements(from: defaults, decoder: decoder)
        events = Self.loadEvents(from: defaults, decoder: decoder)
        lastOpenedEventID = defaults.string(forKey: Keys.lastOpenedEventID)
        mediaJournals = Self.loadJournals(from: defaults, decoder: decoder)
        lastOpenedDate = defaults.object(forKey: Keys.lastOpenedDate) as? Date ?? Date()
        draftCaption = defaults.string(forKey: Keys.draftCaption) ?? ""
        favoriteMedia = defaults.stringArray(forKey: Keys.favoriteMedia) ?? []
        highlightLastOpened = defaults.object(forKey: Keys.highlightLastOpened) as? Date ?? Date()
        showTutorial = defaults.object(forKey: Keys.showTutorial) as? Bool ?? true
        visibleHighlightIDs = defaults.stringArray(forKey: Keys.visibleHighlightIDs)
            ?? SampleMediaCatalog.items.prefix(8).map(\.id)
        graphLinks = Self.loadGraphLinks(from: defaults, decoder: decoder)
        collections = Self.loadCollections(from: defaults, decoder: decoder)
        reviewsCompleted = defaults.integer(forKey: Keys.reviewsCompleted)
        weeklyReviewRecords = Self.loadWeeklyReviewRecords(from: defaults, decoder: decoder)
        sessionStartDate = nil
        recalculateDerivedMetrics()
    }

    private func recalculateDerivedMetrics() {
        itemsAdded = mediaJournals.reduce(0) { $0 + $1.tags.count }
        entriesWritten = events.count
        favouritesCount = favoriteMedia.count
    }

    private func updateStreak(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastActivityDate)
            if calendar.isDate(lastDay, inSameDayAs: today) {
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               calendar.isDate(lastDay, inSameDayAs: yesterday) {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        lastActivityDate = today
    }

    private func checkAchievements() {
        _ = newlyUnlockedAchievements()
    }

    private func notifyNewAchievements() {
        let unlocked = newlyUnlockedAchievements()
        bannerManager.enqueue(unlocked)
    }

    @discardableResult
    private func newlyUnlockedAchievements() -> [AchievementDefinition] {
        var newlyUnlocked: [AchievementDefinition] = []

        for achievement in AchievementDefinition.all {
            guard achievementsUnlocked[achievement.id] == nil else { continue }
            if shouldUnlock(achievement) {
                achievementsUnlocked[achievement.id] = Date()
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    private func shouldUnlock(_ achievement: AchievementDefinition) -> Bool {
        switch achievement.id {
        case "first_tag":
            return itemsAdded >= 1
        case "milestone_achiever":
            return itemsAdded >= 10
        case "chronicle_beginner":
            return entriesWritten >= 1
        case "story_builder":
            return entriesWritten >= 20
        case "favorites_fan":
            return favouritesCount >= 1
        case "trends_observer":
            return favouritesCount >= 5
        case "persistent_organizer":
            return streakDays >= 7
        case "seasoned_curator":
            return streakDays >= 30
        default:
            return false
        }
    }

    private func saveEvents() {
        guard let data = try? encoder.encode(events) else { return }
        defaults.set(data, forKey: Keys.events)
    }

    private func saveJournals() {
        guard let data = try? encoder.encode(mediaJournals) else { return }
        defaults.set(data, forKey: Keys.mediaJournals)
    }

    private func saveAchievements() {
        guard let data = try? encoder.encode(achievementsUnlocked) else { return }
        defaults.set(data, forKey: Keys.achievementsUnlocked)
    }

    private func saveGraphLinks() {
        guard let data = try? encoder.encode(graphLinks) else { return }
        defaults.set(data, forKey: Keys.graphLinks)
    }

    private func saveCollections() {
        guard let data = try? encoder.encode(collections) else { return }
        defaults.set(data, forKey: Keys.collections)
    }

    private func saveWeeklyReviewRecords() {
        guard let data = try? encoder.encode(weeklyReviewRecords) else { return }
        defaults.set(data, forKey: Keys.weeklyReviewRecords)
    }

    private static func loadEvents(from defaults: UserDefaults, decoder: JSONDecoder) -> [TimelineEvent] {
        guard let data = defaults.data(forKey: Keys.events),
              let value = try? decoder.decode([TimelineEvent].self, from: data) else {
            return []
        }
        return value
    }

    private static func loadJournals(from defaults: UserDefaults, decoder: JSONDecoder) -> [JournalEntry] {
        guard let data = defaults.data(forKey: Keys.mediaJournals),
              let value = try? decoder.decode([JournalEntry].self, from: data) else {
            return []
        }
        return value
    }

    private static func loadAchievements(from defaults: UserDefaults, decoder: JSONDecoder) -> [String: Date] {
        guard let data = defaults.data(forKey: Keys.achievementsUnlocked),
              let value = try? decoder.decode([String: Date].self, from: data) else {
            return [:]
        }
        return value
    }

    private static func loadGraphLinks(from defaults: UserDefaults, decoder: JSONDecoder) -> [MediaGraphLink] {
        guard let data = defaults.data(forKey: Keys.graphLinks),
              let value = try? decoder.decode([MediaGraphLink].self, from: data) else {
            return []
        }
        return value
    }

    private static func loadCollections(from defaults: UserDefaults, decoder: JSONDecoder) -> [CuratorCollection] {
        guard let data = defaults.data(forKey: Keys.collections),
              let value = try? decoder.decode([CuratorCollection].self, from: data) else {
            return []
        }
        return value
    }

    private static func loadWeeklyReviewRecords(from defaults: UserDefaults, decoder: JSONDecoder) -> [WeeklyReviewRecord] {
        guard let data = defaults.data(forKey: Keys.weeklyReviewRecords),
              let value = try? decoder.decode([WeeklyReviewRecord].self, from: data) else {
            return []
        }
        return value
    }
}
