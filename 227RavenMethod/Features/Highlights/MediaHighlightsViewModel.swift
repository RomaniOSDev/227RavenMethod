import Combine
import Foundation

final class MediaHighlightsViewModel: ObservableObject {
    @Published var scaledItemID: String?

    func toggleFavorite(_ item: MediaHighlightItem, store: AppStorage) {
        let wasFavorite = store.isFavorite(item.id)
        store.toggleFavorite(mediaID: item.id)
        scaledItemID = item.id

        if !wasFavorite {
            FeedbackService.favoriteToggled()
            FeedbackService.success()
        } else {
            FeedbackService.lightTap()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            if self?.scaledItemID == item.id {
                self?.scaledItemID = nil
            }
        }
    }
}
