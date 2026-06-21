import Combine
import Foundation

final class ChronologyCanvasViewModel: ObservableObject {
    @Published var showingForm = false
    @Published var editingEvent: TimelineEvent?
    @Published var title = ""
    @Published var descriptionText = ""
    @Published var date = Date()
    @Published var selectedIcon = "📅"
    @Published var titleError = ""
    @Published var shakeTrigger: CGFloat = 0
    @Published var animateNewEntryID: String?

    let iconOptions = ["📅", "🎉", "✈️", "🏠", "💼", "🎓", "❤️", "🌟", "📸", "🎵"]

    func prepareNewEntry() {
        editingEvent = nil
        title = ""
        descriptionText = ""
        date = Date()
        selectedIcon = "📅"
        titleError = ""
        showingForm = true
    }

    func prepareEdit(_ event: TimelineEvent) {
        editingEvent = event
        title = event.title
        descriptionText = event.description
        date = event.date
        selectedIcon = event.icon
        titleError = ""
        showingForm = true
    }

    func save(using store: AppStorage) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            titleError = "Title is required."
            shakeTrigger += 1
            FeedbackService.warning()
            return false
        }

        let event = TimelineEvent(
            id: editingEvent?.id ?? UUID().uuidString,
            title: trimmedTitle,
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            icon: selectedIcon
        )

        if editingEvent == nil {
            store.addTimelineEvent(event)
            animateNewEntryID = event.id
            FeedbackService.timelineSaved()
            FeedbackService.success()
        } else {
            store.updateTimelineEvent(event)
            FeedbackService.mediumAction()
            FeedbackService.success()
        }

        showingForm = false
        return true
    }
}
