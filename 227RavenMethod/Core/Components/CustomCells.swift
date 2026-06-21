import SwiftUI

// MARK: - Card & Layout

struct GlassCardModifier: ViewModifier {
    var accentLeading: Bool = false
    var cornerRadius: CGFloat = 18
    var elevation: CardElevation = .standard

    func body(content: Content) -> some View {
        content
            .background {
                DepthCardSurface(cornerRadius: cornerRadius, elevation: elevation)
            }
            .overlay(alignment: .leading) {
                if accentLeading {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4)
                        .padding(.vertical, 10)
                        .padding(.leading, 0)
                }
            }
    }
}

extension View {
    func glassCard(
        accentLeading: Bool = false,
        cornerRadius: CGFloat = 18,
        elevation: CardElevation = .standard
    ) -> some View {
        modifier(GlassCardModifier(
            accentLeading: accentLeading,
            cornerRadius: cornerRadius,
            elevation: elevation
        ))
    }

    func listCard(accentLeading: Bool = false, cornerRadius: CGFloat = 18) -> some View {
        glassCard(accentLeading: accentLeading, cornerRadius: cornerRadius, elevation: .flat)
    }

    func heroCard(cornerRadius: CGFloat = 22) -> some View {
        glassCard(cornerRadius: cornerRadius, elevation: .raised)
    }

    func appScreenPadding() -> some View {
        padding(.horizontal, 16)
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String?
    var trailing: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
            }

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .frame(maxWidth: 56)
        }
    }
}

// MARK: - Atoms

struct IconBadgeView: View {
    let symbolName: String
    var emoji: String?
    var size: CGFloat = 44
    var filled: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    filled
                        ? DepthGradients.primaryButton
                        : LinearGradient(
                            colors: [Color("AppSurface"), Color("AppBackground").opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            filled
                                ? Color("AppTextPrimary").opacity(0.12)
                                : Color("AppPrimary").opacity(0.2),
                            lineWidth: 1
                        )
                )
                .overlay(alignment: .topLeading) {
                    if filled {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppTextPrimary").opacity(0.22), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: size * 0.55, height: size * 0.55)
                            .offset(x: size * 0.08, y: size * 0.06)
                            .allowsHitTesting(false)
                    }
                }

            if let emoji {
                Text(emoji).font(.system(size: size * 0.42))
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(filled ? Color("AppBackground") : Color("AppTextSecondary"))
            }
        }
    }
}

struct TagChipView: View {
    let text: String
    var compact: Bool = false

    var body: some View {
        Text(text.hasPrefix("#") ? text : "#\(text)")
            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(Color("AppBackground"))
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(
                Capsule()
                    .fill(DepthGradients.chip)
            )
    }
}

struct TagChipRowView: View {
    let tags: [String]
    var maxVisible: Int = 4

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags.prefix(maxVisible), id: \.self) { tag in
                    TagChipView(text: tag, compact: true)
                }
                if tags.count > maxVisible {
                    Text("+\(tags.count - maxVisible)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}

struct MetricTileView: View {
    let value: String
    let title: String
    var accent: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(accent ? Color("AppPrimary") : Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(accent ? 0.32 : 0.22),
                            Color("AppSurface").opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct MetaChipView: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color("AppAccent"))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color("AppBackground").opacity(0.42), Color("AppSurface").opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color("AppPrimary").opacity(0.16), lineWidth: 1)
                )
        )
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppPrimary"))
            TextField(placeholder, text: $text)
                .foregroundStyle(Color("AppTextPrimary"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    FeedbackService.lightTap()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppBackground").opacity(0.42), Color("AppSurface").opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("AppPrimary").opacity(0.28), lineWidth: 1)
        )
    }
}

struct EmptyStatePanel: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AppSurface"), Color("AppBackground").opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.5), Color("AppAccent").opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: symbol)
                    .font(.system(size: 34))
                    .foregroundStyle(Color("AppPrimary"))
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
            }
        }
        .padding(24)
        .glassCard()
    }
}

struct CustomSegmentedControl<T: Hashable & CaseIterable & Identifiable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let titleForItem: (T) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(T.allCases)) { item in
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = item
                    }
                } label: {
                    Text(titleForItem(item))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(selection == item ? Color("AppBackground") : Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selection == item ? Color("AppPrimary") : Color("AppBackground").opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppSurface"), Color("AppBackground").opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.16), lineWidth: 1)
                )
        )
    }
}

// MARK: - Feature Cells

struct HubFeatureCell: View {
    let title: String
    let symbol: String
    let subtitle: String
    var badge: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                IconBadgeView(symbolName: symbol, size: 40)
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
            }
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .glassCard(accentLeading: true)
    }
}

struct SearchResultCell: View {
    let symbol: String
    let title: String
    let subtitle: String
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            IconBadgeView(symbolName: symbol, size: 36, filled: false)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .padding(12)
        .listCard(cornerRadius: 14)
    }
}

struct TimelineEventCell: View {
    let event: TimelineEvent
    let linkCount: Int
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color("AppPrimary"))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color("AppTextPrimary").opacity(0.25), lineWidth: 2)
                            .frame(width: 18, height: 18)
                    )
            }
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    IconBadgeView(symbolName: "calendar", emoji: event.icon, size: 48, filled: false)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(event.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                }

                HStack(spacing: 8) {
                    MetaChipView(symbol: "link", text: "\(linkCount) links")
                    if isHighlighted {
                        MetaChipView(symbol: "sparkles", text: "New")
                    }
                }
            }
            .padding(14)
            .listCard(accentLeading: true)
        }
    }
}

struct JournalEntryCell: View {
    let entry: JournalEntry
    var linkedEventTitle: String?

    var body: some View {
        HStack(spacing: 14) {
            StoredPhotoView(data: entry.photoData, styleIndex: entry.thumbnailStyle, symbolName: "photo.fill")
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(entry.photoData == nil ? 0 : 0.45), lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(entry.caption)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                if !entry.tags.isEmpty {
                    TagChipRowView(tags: entry.tags, maxVisible: 3)
                }

                if let linkedEventTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(Color("AppPrimary"))
                        Text(linkedEventTitle)
                            .lineLimit(1)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .padding(14)
        .listCard()
    }
}

struct HighlightCardCell: View {
    let item: MediaHighlightItem
    let isFavorite: Bool
    let isScaled: Bool
    let onStar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                MediaThumbnailView(styleIndex: item.styleIndex, symbolName: item.symbolName)
                    .frame(height: 128)
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color("AppBackground").opacity(0.55)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                Button(action: onStar) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isFavorite ? Color("AppBackground") : Color("AppTextPrimary"))
                        .frame(width: 38, height: 38)
                        .background(isFavorite ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            HStack {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                Spacer()
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color("AppSurface"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background {
            DepthCardSurface(cornerRadius: 16, elevation: .flat)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isFavorite
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color("AppTextPrimary").opacity(0.1)),
                    lineWidth: isFavorite ? 2 : 1
                )
        )
        .scaleEffect(isScaled ? 1.04 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isScaled)
    }
}

struct StoryListCell: View {
    let story: StoryBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                IconBadgeView(symbolName: "book.pages.fill", emoji: story.anchorEvent?.icon, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(story.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundStyle(Color("AppPrimary"))
            }

            HStack(spacing: 8) {
                MetaChipView(symbol: "square.and.pencil", text: "\(story.journals.count)")
                MetaChipView(symbol: "star.fill", text: "\(story.favorites.count)")
                MetaChipView(symbol: "tag.fill", text: "\(story.sharedTags.count)")
            }

            if !story.sharedTags.isEmpty {
                TagChipRowView(tags: story.sharedTags, maxVisible: 5)
            }
        }
        .padding(16)
        .listCard(accentLeading: true)
    }
}

struct AchievementBadgeCell: View {
    let achievement: AchievementDefinition
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                            ? LinearGradient(colors: [Color("AppPrimary"), Color("AppAccent")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color("AppSurface"), Color("AppBackground").opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 58, height: 58)
                Image(systemName: achievement.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(unlocked ? Color("AppBackground") : Color("AppTextSecondary"))
            }

            Text(achievement.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 168)
        .listCard()
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(unlocked ? Color("AppAccent").opacity(0.8) : Color.clear, lineWidth: 2)
        )
        .opacity(unlocked ? 1 : 0.82)
    }
}

struct InsightTagRowCell: View {
    let tag: String
    let count: Int
    let maxCount: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                TagChipView(text: tag, compact: true)
                Spacer()
                Text("\(count)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppPrimary"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("AppBackground").opacity(0.35))
                    Capsule()
                        .fill(Color("AppPrimary"))
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)))
                }
            }
            .frame(height: 6)
        }
    }
}

struct InsightSuggestionCell: View {
    let symbol: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadgeView(symbolName: symbol, size: 34, filled: false)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .listCard(cornerRadius: 14)
    }
}

struct SettingsMenuRow: View {
    let title: String
    let symbol: String
    var destructive: Bool = false
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            IconBadgeView(
                symbolName: symbol,
                size: 36,
                filled: !destructive
            )
            .opacity(destructive ? 0.85 : 1)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
    }
}

struct CollectionCardCell: View {
    let name: String
    let itemCount: Int
    let styleIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CollectionCoverView(styleIndex: styleIndex, itemCount: itemCount)
                .frame(height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
            HStack {
                MetaChipView(symbol: "square.stack.3d.up.fill", text: "\(itemCount) items")
                Spacer()
            }
        }
        .padding(12)
        .listCard(cornerRadius: 16)
    }
}

struct InfoBannerCell: View {
    let symbol: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Color("AppPrimary"))
            Text(message)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .listCard()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                LinearGradient(
                    colors: [Color("AppSurface"), Color("AppBackground").opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
