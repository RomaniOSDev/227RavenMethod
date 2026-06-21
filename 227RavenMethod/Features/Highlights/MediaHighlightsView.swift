import SwiftUI

struct MediaHighlightsView: View {
    @EnvironmentObject private var store: AppStorage
    @StateObject private var viewModel = MediaHighlightsViewModel()
    var ignoresBottomSafeArea: Bool = true

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var visibleItems: [MediaHighlightItem] {
        store.visibleHighlightIDs.compactMap { id in
            SampleMediaCatalog.items.first { $0.id == id }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppBackgroundView(ignoresBottomSafeArea: ignoresBottomSafeArea)

            ScrollView {
                VStack(spacing: 16) {
                    if store.showTutorial {
                        HStack {
                            InfoBannerCell(
                                symbol: "star.circle.fill",
                                message: "Discover amazing highlights by tapping the star! 📸"
                            )
                            Button("Got it") {
                                FeedbackService.lightTap()
                                store.showTutorial = false
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color("AppPrimary"))
                        }
                    }

                    if visibleItems.isEmpty {
                        EmptyStatePanel(
                            symbol: "star.circle.fill",
                            title: "No Highlights Yet!",
                            message: "Tap the star to add your favorites.",
                            actionTitle: "Refresh Samples",
                            action: { store.refreshHighlights() }
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(visibleItems) { item in
                                HighlightCardCell(
                                    item: item,
                                    isFavorite: store.isFavorite(item.id),
                                    isScaled: viewModel.scaledItemID == item.id,
                                    onStar: { viewModel.toggleFavorite(item, store: store) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
            }
            .scrollContentBackground(.hidden)

            FloatingAddButton {
                store.refreshHighlights()
                if store.showTutorial { store.showTutorial = false }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
    }
}
