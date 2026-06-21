import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let symbolName: String

    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_tag",
            title: "First Tag",
            description: "Tagged your first media item.",
            symbolName: "tag.fill"
        ),
        AchievementDefinition(
            id: "milestone_achiever",
            title: "Milestone Achiever",
            description: "Added 10 tags.",
            symbolName: "star.circle.fill"
        ),
        AchievementDefinition(
            id: "chronicle_beginner",
            title: "Chronicle Beginner",
            description: "Created your first timeline entry.",
            symbolName: "calendar.badge.plus"
        ),
        AchievementDefinition(
            id: "story_builder",
            title: "Story Builder",
            description: "Captured 20 timeline entries.",
            symbolName: "books.vertical.fill"
        ),
        AchievementDefinition(
            id: "favorites_fan",
            title: "Favorites Fan",
            description: "Marked an item as favorite.",
            symbolName: "heart.fill"
        ),
        AchievementDefinition(
            id: "trends_observer",
            title: "Trends Observer",
            description: "Identified trends in favorites.",
            symbolName: "chart.line.uptrend.xyaxis"
        ),
        AchievementDefinition(
            id: "persistent_organizer",
            title: "Persistent Organizer",
            description: "Logged entries consistently for a week.",
            symbolName: "flame.fill"
        ),
        AchievementDefinition(
            id: "seasoned_curator",
            title: "Seasoned Curator",
            description: "Maintained activity for a month.",
            symbolName: "crown.fill"
        )
    ]
}
