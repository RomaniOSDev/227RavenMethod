import AudioToolbox
import UIKit

enum FeedbackService {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1003)
    }

    static func mediumAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func timelineSaved() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    static func journalSaved() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1105)
    }

    static func favoriteToggled() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1102)
    }

    static func achievementUnlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)
    }
}
