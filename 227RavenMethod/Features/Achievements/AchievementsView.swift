import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppStorage

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(ignoresBottomSafeArea: false)

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard

                        SectionHeaderView(
                            title: "Your Badges",
                            subtitle: "Unlocked through real actions",
                            trailing: "\(store.achievementsUnlocked.count)/8"
                        )
                        .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementDefinition.all) { achievement in
                                AchievementBadgeCell(
                                    achievement: achievement,
                                    unlocked: store.isAchievementUnlocked(achievement.id)
                                )
                            }
                        }
                    }
                    .appScreenContentPadding()
                }
                .scrollContentBackground(.hidden)
            }
            .appNavigationChrome("Achievements")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView(title: "Your Progress", subtitle: "Keep curating to unlock more")

            HStack(spacing: 10) {
                MetricTileView(value: "\(store.itemsAdded)", title: "Tags")
                MetricTileView(value: "\(store.entriesWritten)", title: "Events")
                MetricTileView(value: "\(store.favouritesCount)", title: "Favorites")
            }

            HStack(spacing: 10) {
                MetricTileView(value: "\(store.streakDays)d", title: "Streak")
                MetricTileView(value: "\(store.graphLinks.count)", title: "Links")
                MetricTileView(value: "\(store.reviewsCompleted)", title: "Reviews")
            }
        }
        .padding(16)
        .glassCard(accentLeading: true)
    }
}
