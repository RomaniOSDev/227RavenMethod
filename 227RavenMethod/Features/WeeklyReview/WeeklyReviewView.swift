import SwiftUI

struct WeeklyReviewView: View {
    @EnvironmentObject private var store: AppStorage
    @StateObject private var viewModel = WeeklyReviewViewModel()
    @Environment(\.dismiss) private var dismiss

    private var stepTitle: String {
        switch viewModel.step {
        case .overview: return "Overview"
        case .tags: return "Refine Tags"
        case .linkEvent: return "Link Event"
        case .favorites: return "Pick Favorites"
        case .reflection: return "Reflect"
        case .complete: return "Complete"
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    progressHeader
                    stepContent
                    navigationButtons
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome("Weekly Review")
        .onAppear { viewModel.start(with: store) }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(title: stepTitle, subtitle: "Guided session · ~5 min")
                Spacer()
                MetaChipView(symbol: "checkmark.seal", text: "\(store.reviewsCompleted) done")
            }
            ProgressView(
                value: Double(min(viewModel.step.rawValue, WeeklyReviewViewModel.Step.reflection.rawValue)),
                total: Double(WeeklyReviewViewModel.Step.reflection.rawValue)
            )
            .tint(Color("AppPrimary"))
            .scaleEffect(y: 1.4)
        }
        .padding(16)
        .glassCard(accentLeading: true)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .overview: overviewStep
        case .tags: tagsStep
        case .linkEvent: linkEventStep
        case .favorites: favoritesStep
        case .reflection: reflectionStep
        case .complete: completeStep
        }
    }

    private var overviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                IconBadgeView(symbolName: "calendar.badge.clock", size: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Review, tag, link, favorite, reflect.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            MetricTileView(value: "\(store.journalsFromLastWeek.count)", title: "Journal entries")
        }
        .padding(16)
        .glassCard()
    }

    private var tagsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Add or refine tags")
            if store.journalsFromLastWeek.isEmpty {
                InsightSuggestionCell(symbol: "info.circle", message: "No journals this week — you can still continue.")
            } else {
                ForEach(store.journalsFromLastWeek) { journal in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(journal.caption)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Tags", text: binding(for: journal.id))
                            .padding(12)
                            .background(Color("AppBackground").opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .padding(12)
                    .background(Color("AppBackground").opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var linkEventStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Link to timeline event")
            if store.events.isEmpty {
                InsightSuggestionCell(symbol: "calendar.badge.exclamationmark", message: "Create a timeline event first, then rerun your review.")
            } else {
                Picker("Event", selection: Binding(
                    get: { viewModel.selectedEventID ?? "" },
                    set: { viewModel.selectedEventID = $0.isEmpty ? nil : $0 }
                )) {
                    ForEach(store.events) { event in
                        Text("\(event.icon) \(event.title)").tag(event.id)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .glassCard()
            }
        }
        .padding(16)
        .glassCard()
    }

    private var favoritesStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Pick 1–2 favorites", subtitle: "Tap to select")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SampleMediaCatalog.items.prefix(8)) { item in
                    HighlightCardCell(
                        item: item,
                        isFavorite: viewModel.selectedFavoriteIDs.contains(item.id),
                        isScaled: viewModel.selectedFavoriteIDs.contains(item.id),
                        onStar: { viewModel.toggleFavorite(item.id) }
                    )
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var reflectionStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Short reflection", subtitle: "What stood out this week?")
            TextField("Write a few sentences…", text: $viewModel.reflection, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(Color("AppBackground").opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Color("AppTextPrimary"))
                .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
            if !viewModel.reflectionError.isEmpty {
                Text(viewModel.reflectionError).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(16)
        .glassCard()
    }

    private var completeStep: some View {
        VStack(spacing: 18) {
            IconBadgeView(symbolName: "checkmark.seal.fill", size: 72)
            Text("Review Complete")
                .font(.title2.bold())
                .foregroundStyle(Color("AppTextPrimary"))
            Text("Your media graph has been updated. Great work staying organized.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("AppTextSecondary"))
            Button("Done") {
                FeedbackService.lightTap()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
        .glassCard(accentLeading: true)
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.step != .overview && viewModel.step != .complete {
                Button("Back") { viewModel.back() }
                    .buttonStyle(SecondaryButtonStyle())
            }

            if viewModel.step == .reflection {
                Button("Finish Review") { _ = viewModel.finish(store: store) }
                    .buttonStyle(PrimaryButtonStyle())
            } else if viewModel.step != .complete {
                Button("Next") { viewModel.next(store: store) }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func binding(for journalID: String) -> Binding<String> {
        Binding(
            get: { viewModel.journalTagDrafts[journalID] ?? "" },
            set: { viewModel.journalTagDrafts[journalID] = $0 }
        )
    }
}
