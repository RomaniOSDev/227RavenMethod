import SwiftUI

struct StoriesListView: View {
    @EnvironmentObject private var store: AppStorage

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    if store.events.isEmpty {
                        EmptyStatePanel(
                            symbol: "book.pages",
                            title: "No Stories Yet",
                            message: "Create timeline events and link journals to build your personal media graph."
                        )
                        .padding(.bottom, 8)
                    } else {
                        SectionHeaderView(
                            title: "Linked Stories",
                            subtitle: "Events with connected media",
                            trailing: "\(store.stories().count)"
                        )
                        .padding(.horizontal, 4)

                        ForEach(store.stories()) { story in
                            NavigationLink(value: DiscoverRoute.story(story.id)) {
                                StoryListCell(story: story)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                        }
                    }
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome("Stories")
    }
}

struct StoryDetailView: View {
    @EnvironmentObject private var store: AppStorage
    let eventID: String

    private var story: StoryBundle? {
        store.story(for: eventID)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    if let story {
                        heroHeader(story)

                        if !story.sharedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeaderView(title: "Shared Tags")
                                TagChipRowView(tags: story.sharedTags, maxVisible: 8)
                            }
                            .padding(16)
                            .glassCard()
                        }

                        sectionBlock(title: "Linked Journals", count: story.journals.count, empty: "No journals linked yet.") {
                            ForEach(story.journals) { journal in
                                JournalEntryCell(
                                    entry: journal,
                                    linkedEventTitle: nil
                                )
                            }
                        }

                        sectionBlock(title: "Linked Favorites", count: story.favorites.count, empty: "Star highlights and link them to this story.") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(story.favorites) { item in
                                    HighlightCardCell(
                                        item: item,
                                        isFavorite: true,
                                        isScaled: false,
                                        onStar: {}
                                    )
                                }
                            }
                        }
                    } else {
                        EmptyStatePanel(
                            symbol: "exclamationmark.triangle",
                            title: "Story Not Found",
                            message: "This story may have been removed."
                        )
                    }
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome(story?.title ?? "Story")
    }

    private func heroHeader(_ story: StoryBundle) -> some View {
        HStack(spacing: 14) {
            IconBadgeView(symbolName: "book.pages.fill", emoji: story.anchorEvent?.icon, size: 56)
            VStack(alignment: .leading, spacing: 6) {
                if let event = story.anchorEvent {
                    Text(event.description.isEmpty ? "Timeline Story" : event.description)
                        .font(.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(event.date.formatted(date: .long, time: .omitted))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            Spacer()
        }
        .padding(16)
        .glassCard(accentLeading: true)
    }

    @ViewBuilder
    private func sectionBlock<Content: View>(
        title: String,
        count: Int,
        empty: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: title, trailing: "\(count)")
            if count == 0 {
                Text(empty)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                content()
            }
        }
    }
}

struct FlowTagView: View {
    let tags: [String]

    var body: some View {
        TagChipRowView(tags: tags, maxVisible: 20)
    }
}
