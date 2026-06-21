import Combine
import Foundation

final class WeeklyReviewViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case overview
        case tags
        case linkEvent
        case favorites
        case reflection
        case complete
    }

    @Published var step: Step = .overview
    @Published var journalTagDrafts: [String: String] = [:]
    @Published var selectedEventID: String?
    @Published var selectedFavoriteIDs: Set<String> = []
    @Published var reflection = ""
    @Published var reflectionError = ""
    @Published var shakeTrigger: CGFloat = 0

    func start(with store: AppStorage) {
        step = .overview
        journalTagDrafts = Dictionary(uniqueKeysWithValues: store.journalsFromLastWeek.map { ($0.id, $0.tags.joined(separator: ", ")) })
        selectedEventID = store.events.first?.id
        selectedFavoriteIDs = []
        reflection = ""
        reflectionError = ""
    }

    func next(store: AppStorage) {
        if step == .tags {
            applyTags(to: store)
        }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
            FeedbackService.lightTap()
        }
    }

    func back() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
            FeedbackService.lightTap()
        }
    }

    func toggleFavorite(_ id: String) {
        if selectedFavoriteIDs.contains(id) {
            selectedFavoriteIDs.remove(id)
        } else if selectedFavoriteIDs.count < 2 {
            selectedFavoriteIDs.insert(id)
            FeedbackService.favoriteToggled()
        } else {
            FeedbackService.warning()
        }
    }

    func finish(store: AppStorage) -> Bool {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else {
            reflectionError = "Write at least a short reflection (8+ characters)."
            shakeTrigger += 1
            FeedbackService.warning()
            return false
        }

        let journalIDs = Array(journalTagDrafts.keys)
        let tagsAdded = journalIDs.reduce(0) { partial, id in
            let original = store.mediaJournals.first { $0.id == id }?.tags ?? []
            let updated = parsedTags(from: journalTagDrafts[id] ?? "")
            return partial + max(0, updated.count - original.count)
        }

        store.completeWeeklyReview(
            reflection: trimmed,
            journalIDs: journalIDs,
            eventID: selectedEventID,
            favoriteIDs: Array(selectedFavoriteIDs),
            tagsAddedCount: tagsAdded
        )
        step = .complete
        return true
    }

    private func applyTags(to store: AppStorage) {
        for (journalID, draft) in journalTagDrafts {
            guard var journal = store.mediaJournals.first(where: { $0.id == journalID }) else { continue }
            let tags = parsedTags(from: draft)
            guard tags != journal.tags else { continue }
            journal.tags = tags
            store.updateJournalEntry(journal)
        }
    }

    private func parsedTags(from text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
