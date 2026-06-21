import Combine
import Foundation

final class AchievementBannerManager: ObservableObject {
    @Published var currentBanner: AchievementDefinition?
    @Published var isVisible = false

    private var queue: [AchievementDefinition] = []
    private var isProcessing = false

    func enqueue(_ achievements: [AchievementDefinition]) {
        guard !achievements.isEmpty else { return }
        queue.append(contentsOf: achievements)
        processNextIfNeeded()
    }

    private func processNextIfNeeded() {
        guard !isProcessing, currentBanner == nil, let next = queue.first else { return }
        isProcessing = true
        queue.removeFirst()
        currentBanner = next
        isVisible = true
        FeedbackService.achievementUnlocked()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            self.isVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.currentBanner = nil
                self.isProcessing = false
                self.processNextIfNeeded()
            }
        }
    }
}
