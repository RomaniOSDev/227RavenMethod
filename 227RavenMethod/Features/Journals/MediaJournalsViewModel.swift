import Combine
import Foundation

final class MediaJournalsViewModel: ObservableObject {
    @Published var showingForm = false
    @Published var caption = ""
    @Published var tagsText = ""
    @Published var captionError = ""
    @Published var shakeTrigger: CGFloat = 0
    @Published var bounceEntryID: String?
    @Published var selectedPhotoData: Data?
    @Published var selectedEventID: String?
    @Published var selectedFavoriteIDs: Set<String> = []
    @Published var editingEntryID: String?

    func prepareNewEntry(draft: String) {
        editingEntryID = nil
        caption = draft
        tagsText = ""
        selectedPhotoData = nil
        selectedEventID = nil
        selectedFavoriteIDs = []
        captionError = ""
        showingForm = true
    }

    func prepareEdit(_ entry: JournalEntry, store: AppStorage) {
        editingEntryID = entry.id
        caption = entry.caption
        tagsText = entry.tags.joined(separator: ", ")
        selectedPhotoData = entry.photoData
        selectedEventID = MediaGraphService.event(forJournalID: entry.id, store: store)?.id
        selectedFavoriteIDs = Set(MediaGraphService.favorites(forJournalID: entry.id, store: store).map(\.id))
        captionError = ""
        showingForm = true
    }

    func applyPhotoData(_ data: Data?) {
        selectedPhotoData = data.flatMap { PhotoDataCompressor.compress(data: $0) }
    }

    func save(using store: AppStorage) -> Bool {
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCaption.isEmpty else {
            captionError = "Caption is required."
            shakeTrigger += 1
            FeedbackService.warning()
            return false
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let editingEntryID,
           var existing = store.mediaJournals.first(where: { $0.id == editingEntryID }) {
            existing.caption = trimmedCaption
            existing.tags = tags
            existing.photoData = selectedPhotoData
            store.updateJournalEntry(existing)
            store.linkJournal(editingEntryID, toEvent: selectedEventID)
            syncFavorites(journalID: editingEntryID, store: store)
            bounceEntryID = editingEntryID
        } else {
            let entry = JournalEntry(
                caption: trimmedCaption,
                date: Date(),
                tags: tags,
                thumbnailStyle: Int.random(in: 0...11),
                photoData: selectedPhotoData
            )
            store.addJournalEntry(entry)
            store.linkJournal(entry.id, toEvent: selectedEventID)
            syncFavorites(journalID: entry.id, store: store)
            bounceEntryID = entry.id
        }

        FeedbackService.journalSaved()
        FeedbackService.success()
        showingForm = false
        caption = ""
        tagsText = ""
        selectedPhotoData = nil
        selectedEventID = nil
        selectedFavoriteIDs = []
        editingEntryID = nil
        return true
    }

    private func syncFavorites(journalID: String, store: AppStorage) {
        let current = Set(MediaGraphService.favorites(forJournalID: journalID, store: store).map(\.id))
        for id in current where !selectedFavoriteIDs.contains(id) {
            store.linkJournal(journalID, toFavorite: id, enabled: false)
        }
        for id in selectedFavoriteIDs where !current.contains(id) {
            store.linkJournal(journalID, toFavorite: id, enabled: true)
        }
    }
}
