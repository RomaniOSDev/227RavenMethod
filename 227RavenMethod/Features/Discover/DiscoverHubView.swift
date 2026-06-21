import SwiftUI

struct DiscoverHubView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var searchText = ""

    private var searchResults: [GraphSearchResult] {
        store.searchGraph(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(ignoresBottomSafeArea: false)

                ScrollView {
                    VStack(spacing: 18) {
                        statsStrip
                        searchSection
                        SectionHeaderView(title: "Explore", subtitle: "Your media graph toolkit")
                        hubGrid
                    }
                    .appScreenContentPadding()
                }
                .scrollContentBackground(.hidden)
            }
            .appNavigationChrome("Discover")
            .navigationDestination(for: DiscoverRoute.self) { route in
                switch route {
                case .stories:
                    StoriesListView()
                case .insights:
                    InsightsView()
                case .weeklyReview:
                    WeeklyReviewView()
                case .collections:
                    CollectionsView()
                case .story(let eventID):
                    StoryDetailView(eventID: eventID)
                case .collection(let id):
                    CollectionDetailView(collectionID: id)
                }
            }
        }
    }

    private var statsStrip: some View {
        HStack(spacing: 10) {
            MetricTileView(value: "\(store.graphLinks.count)", title: "Links")
            MetricTileView(value: "\(store.stories().count)", title: "Stories")
            MetricTileView(value: "\(store.reviewsCompleted)", title: "Reviews")
        }
        .padding(14)
        .glassCard()
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Search Graph", subtitle: "Journals, events, tags, collections")
            AppSearchField(text: $searchText, placeholder: "Type to search…")

            if !searchText.isEmpty {
                if searchResults.isEmpty {
                    Text("No matches found.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .padding(.top, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(searchResults.prefix(8)) { result in
                            searchResultRow(result)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var hubGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            hubLink(title: "Stories", symbol: "book.pages.fill", subtitle: "\(store.stories().count) linked", badge: nil, route: .stories)
            hubLink(title: "Insights", symbol: "chart.bar.fill", subtitle: "Patterns & trends", badge: "Live", route: .insights)
            hubLink(title: "Weekly Review", symbol: "calendar.badge.clock", subtitle: "Guided session", badge: "\(store.reviewsCompleted)", route: .weeklyReview)
            hubLink(title: "Collections", symbol: "folder.fill", subtitle: "Curated sets", badge: "\(store.collections.count)", route: .collections)
        }
    }

    private func hubLink(title: String, symbol: String, subtitle: String, badge: String?, route: DiscoverRoute) -> some View {
        NavigationLink(value: route) {
            HubFeatureCell(title: title, symbol: symbol, subtitle: subtitle, badge: badge)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
    }

    @ViewBuilder
    private func searchResultRow(_ result: GraphSearchResult) -> some View {
        let cell = SearchResultCell(
            symbol: icon(for: result.kind),
            title: result.title,
            subtitle: result.subtitle,
            showsChevron: result.storyEventID != nil || result.collectionID != nil
        )

        if let eventID = result.storyEventID, result.kind == .story || result.kind == .event {
            NavigationLink(value: DiscoverRoute.story(eventID)) { cell }.buttonStyle(.plain)
        } else if result.kind == .collection, let collectionID = result.collectionID {
            NavigationLink(value: DiscoverRoute.collection(collectionID)) { cell }.buttonStyle(.plain)
        } else {
            cell
        }
    }

    private func icon(for kind: GraphSearchResult.ResultKind) -> String {
        switch kind {
        case .journal: return "square.and.pencil"
        case .event, .story: return "calendar"
        case .favorite: return "star.fill"
        case .collection: return "folder.fill"
        }
    }
}

enum DiscoverRoute: Hashable {
    case stories
    case insights
    case weeklyReview
    case collections
    case story(String)
    case collection(String)
}
