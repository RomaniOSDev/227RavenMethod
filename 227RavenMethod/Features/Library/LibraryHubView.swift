import SwiftUI

enum LibrarySection: String, CaseIterable, Identifiable {
    case journals
    case highlights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journals: return "Journals"
        case .highlights: return "Highlights"
        }
    }
}

struct LibraryHubView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var selectedSection: LibrarySection = .journals

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(ignoresBottomSafeArea: false)

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        CustomSegmentedControl(selection: $selectedSection, titleForItem: \.title)
                            .padding(.horizontal, 16)

                        HStack(spacing: 10) {
                            MetricTileView(
                                value: "\(store.mediaJournals.count)",
                                title: "Journals"
                            )
                            MetricTileView(
                                value: "\(store.favoriteMedia.count)",
                                title: "Favorites"
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)

                    Group {
                        switch selectedSection {
                    case .journals:
                        MediaJournalsView(ignoresBottomSafeArea: false)
                    case .highlights:
                        MediaHighlightsView(ignoresBottomSafeArea: false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .appNavigationChrome(selectedSection == .journals ? "My Media Journals" : "Highlights")
            .animation(.easeInOut(duration: 0.3), value: selectedSection)
        }
    }
}
