import SwiftUI
import UIKit

enum HomeRoute: Hashable {
    case timeline
    case weeklyReview
    case insights
    case collections
    case story(String)
    case library
}

struct HomeHeroBanner: View {
    let greeting: String
    let subtitle: String
    let photoTiles: [HomePhotoTile]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HomeHero")
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.15),
                    Color("AppBackground").opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                HomePhotoMosaic(tiles: photoTiles)
            }
            .padding(16)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background {
            DepthCardSurface(cornerRadius: 22, elevation: .raised)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.45), Color("AppAccent").opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct HomePhotoMosaic: View {
    let tiles: [HomePhotoTile]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tiles.prefix(4)) { tile in
                ZStack(alignment: .bottomLeading) {
                    if let data = tile.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        MediaThumbnailView(
                            styleIndex: tile.styleIndex,
                            symbolName: tile.source == "Favorite" ? "star.fill" : "photo.fill"
                        )
                    }

                    LinearGradient(
                        colors: [Color.clear, Color("AppBackground").opacity(0.75)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    Text(tile.caption)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .padding(6)
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color("AppTextPrimary").opacity(0.22), Color("AppPrimary").opacity(0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
        }
    }
}

struct HomeStatWidget: View {
    let stat: HomeViewModel.QuickStat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadgeView(symbolName: stat.symbol, size: 34, filled: false)
            Text(stat.value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(stat.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(14)
        .glassCard(accentLeading: true)
    }
}

struct HomeWideWidget<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                IconBadgeView(symbolName: symbol, size: 32, filled: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
            }
            content()
        }
        .padding(14)
        .glassCard()
    }
}

struct HomeActionWidget: View {
    let title: String
    let subtitle: String
    let symbol: String
    var badge: String?

    var body: some View {
        HStack(spacing: 12) {
            IconBadgeView(symbolName: symbol, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppBackground"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AppAccent"))
                    .clipShape(Capsule())
            }
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
        }
        .padding(14)
        .glassCard(accentLeading: true)
    }
}

struct HomeRecentJournalWidget: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 12) {
            StoredPhotoView(
                data: entry.photoData,
                styleIndex: entry.thumbnailStyle,
                symbolName: "photo.fill"
            )
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.caption)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                if !entry.tags.isEmpty {
                    TagChipRowView(tags: entry.tags, maxVisible: 2)
                }
            }
            Spacer()
        }
    }
}

struct HomeTimelinePreviewWidget: View {
    let event: TimelineEvent
    let linkCount: Int

    var body: some View {
        HStack(spacing: 12) {
            IconBadgeView(symbolName: "calendar", emoji: event.icon, size: 44, filled: false)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Color("AppAccent"))
                MetaChipView(symbol: "link", text: "\(linkCount) links")
            }
            Spacer()
        }
    }
}

struct HomeQuickActionsRow: View {
    let onTimeline: () -> Void
    let onJournal: () -> Void
    let onDiscover: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            quickButton(title: "Timeline", symbol: "calendar", action: onTimeline)
            quickButton(title: "Journal", symbol: "square.and.pencil", action: onJournal)
            quickButton(title: "Discover", symbol: "sparkle.magnifyingglass", action: onDiscover)
        }
    }

    private func quickButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            FeedbackService.lightTap()
            action()
        }) {
            VStack(spacing: 8) {
                IconBadgeView(symbolName: symbol, size: 36, filled: false)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassCard(elevation: .flat)
        }
        .buttonStyle(.plain)
    }
}
