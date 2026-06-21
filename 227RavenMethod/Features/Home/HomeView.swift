import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStorage
    @Binding var selectedTab: MainTab
    @StateObject private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    private let widgetColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppBackgroundView(ignoresBottomSafeArea: false)

                ScrollView {
                    VStack(spacing: 16) {
                        HomeHeroBanner(
                            greeting: viewModel.greeting(),
                            subtitle: heroSubtitle,
                            photoTiles: viewModel.photoTiles(from: store)
                        )

                        HomeQuickActionsRow(
                            onTimeline: { navigationPath.append(HomeRoute.timeline) },
                            onJournal: { selectedTab = .library },
                            onDiscover: { selectedTab = .discover }
                        )

                        SectionHeaderView(
                            title: "Your Dashboard",
                            subtitle: "Live widgets from your media graph",
                            trailing: formattedToday
                        )
                        .padding(.horizontal, 4)

                        LazyVGrid(columns: widgetColumns, spacing: 12) {
                            ForEach(viewModel.quickStats(from: store), id: \.label) { stat in
                                HomeStatWidget(stat: stat)
                            }
                        }

                        weeklyReviewWidget

                        if let entry = viewModel.latestJournal(from: store) {
                            NavigationLink(value: HomeRoute.library) {
                                HomeWideWidget(
                                    title: "Latest Journal",
                                    subtitle: "Most recent entry",
                                    symbol: "photo.on.rectangle.angled"
                                ) {
                                    HomeRecentJournalWidget(entry: entry)
                                }
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                        }

                        if let event = viewModel.upcomingEvent(from: store) {
                            NavigationLink(value: HomeRoute.story(event.id)) {
                                HomeWideWidget(
                                    title: "Timeline Highlight",
                                    subtitle: "Your latest life event",
                                    symbol: "calendar.badge.clock"
                                ) {
                                    HomeTimelinePreviewWidget(
                                        event: event,
                                        linkCount: linkCount(for: event.id)
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                        }

                        if let topTag = viewModel.topTag(from: store) {
                            NavigationLink(value: HomeRoute.insights) {
                                HomeWideWidget(
                                    title: "Trending Tag",
                                    subtitle: "Most used this week",
                                    symbol: "number"
                                ) {
                                    InsightTagRowCell(
                                        tag: topTag.tag,
                                        count: topTag.count,
                                        maxCount: topTag.count
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if let story = viewModel.featuredStory(from: store), story.journals.count + story.favorites.count > 0 {
                            NavigationLink(value: HomeRoute.story(story.id)) {
                                HomeActionWidget(
                                    title: "Featured Story",
                                    subtitle: story.title,
                                    symbol: "book.pages.fill",
                                    badge: "\(story.journals.count + story.favorites.count)"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink(value: HomeRoute.collections) {
                            HomeActionWidget(
                                title: "Curator Collections",
                                subtitle: "\(store.collections.count) active sets with smart rules",
                                symbol: "folder.fill",
                                badge: store.collections.isEmpty ? "New" : nil
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.timeline) {
                            HomeActionWidget(
                                title: "Open Full Timeline",
                                subtitle: "\(store.events.count) life events · drag, edit, link stories",
                                symbol: "calendar"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .appScreenContentPadding()
                    .padding(.bottom, 8)
                }
                .scrollContentBackground(.hidden)
            }
            .appNavigationChrome("Home")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .timeline:
                    ChronologyCanvasView()
                case .weeklyReview:
                    WeeklyReviewView()
                case .insights:
                    InsightsView()
                case .collections:
                    CollectionsView()
                case .story(let eventID):
                    StoryDetailView(eventID: eventID)
                case .library:
                    MediaJournalsView()
                }
            }
        }
    }

    private var heroSubtitle: String {
        if store.mediaJournals.isEmpty && store.events.isEmpty {
            return "Start curating your media graph today."
        }
        return "\(store.totalEntriesCreated) entries · \(store.graphLinks.count) connections"
    }

    private var formattedToday: String {
        Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private var weeklyReviewWidget: some View {
        NavigationLink(value: HomeRoute.weeklyReview) {
            HomeActionWidget(
                title: "Weekly Review",
                subtitle: viewModel.shouldPromptWeeklyReview(from: store)
                    ? "Your weekly session is ready — tag, link, and reflect."
                    : "Keep your graph organized with a quick ritual.",
                symbol: "calendar.badge.clock",
                badge: viewModel.shouldPromptWeeklyReview(from: store) ? "Ready" : nil
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
    }

    private func linkCount(for eventID: String) -> Int {
        store.graphLinks.filter {
            ($0.kind == .journalEvent && $0.secondaryID == eventID) ||
            ($0.kind == .eventFavorite && $0.primaryID == eventID)
        }.count
    }
}
