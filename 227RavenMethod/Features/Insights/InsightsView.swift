import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var tagPeriod = 7

    private var weekTags: [TagStat] { InsightsEngine.topTags(days: 7, store: store) }
    private var monthTags: [TagStat] { InsightsEngine.topTags(days: 30, store: store) }
    private var heatmap: [ActivityDayStat] { InsightsEngine.activityHeatmap(days: 28, store: store) }
    private var themes: [TrendingTheme] { InsightsEngine.trendingThemes(store: store) }
    private var suggestions: [InsightSuggestion] { InsightsEngine.suggestions(store: store) }

    private var activeTags: [TagStat] { tagPeriod == 7 ? weekTags : monthTags }
    private var maxTagCount: Int { activeTags.map(\.count).max() ?? 1 }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    suggestionsSection
                    tagsSection
                    heatmapSection
                    themesSection
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome("Insights")
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Gentle Nudges", subtitle: "Personalized tips from your graph")

            if suggestions.isEmpty {
                InsightSuggestionCell(
                    symbol: "checkmark.seal.fill",
                    message: "You're all caught up — keep curating your media graph."
                )
            } else {
                ForEach(suggestions) { item in
                    InsightSuggestionCell(symbol: item.symbolName, message: item.message)
                }
            }
        }
        .padding(16)
        .glassCard(accentLeading: true)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(title: "Top Tags")
                Spacer()
                Picker("Period", selection: $tagPeriod) {
                    Text("Week").tag(7)
                    Text("Month").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            if activeTags.isEmpty {
                Text("Add tags to journals to see trends here.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(activeTags.prefix(6)) { stat in
                    InsightTagRowCell(tag: stat.tag, count: stat.count, maxCount: maxTagCount)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(
                title: "Activity Heatmap",
                subtitle: "Last 28 days — journals, events, reviews"
            )
            HeatmapGridView(stats: heatmap)
        }
        .padding(16)
        .glassCard()
    }

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Trending Themes", subtitle: "Patterns in your favorites")

            if themes.isEmpty {
                Text("Mark highlights as favorites to discover themes.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(themes.prefix(5)) { theme in
                    HStack(spacing: 12) {
                        IconBadgeView(symbolName: theme.sampleSymbol, size: 36, filled: false)
                        Text(theme.title)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        Text("\(theme.count)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}
