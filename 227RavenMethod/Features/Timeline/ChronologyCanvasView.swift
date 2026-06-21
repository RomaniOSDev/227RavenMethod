import SwiftUI

struct ChronologyCanvasView: View {
    @EnvironmentObject private var store: AppStorage
    @StateObject private var viewModel = ChronologyCanvasViewModel()
    @State private var presentedStoryEventID: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppBackgroundView()

                Group {
                    if store.events.isEmpty {
                        ScrollView {
                            EmptyStatePanel(
                                symbol: "calendar.badge.plus",
                                title: "No Events Added",
                                message: "Tap + to create your first life event and start building your chronology.",
                                actionTitle: "Add Event",
                                action: { viewModel.prepareNewEntry() }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        List {
                            Section {
                                InfoBannerCell(
                                    symbol: "hand.draw.fill",
                                    message: "Tap to edit · Swipe left for Story · Swipe right to delete · Edit to reorder"
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                            }

                            Section {
                                ForEach(store.events) { event in
                                    Button {
                                        FeedbackService.lightTap()
                                        store.lastOpenedEventID = event.id
                                        viewModel.prepareEdit(event)
                                    } label: {
                                        TimelineEventCell(
                                            event: event,
                                            linkCount: linkCount(for: event.id),
                                            isHighlighted: viewModel.animateNewEntryID == event.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .scaleEffect(viewModel.animateNewEntryID == event.id ? 1.02 : 1)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.animateNewEntryID)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                store.deleteTimelineEvent(id: event.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            FeedbackService.lightTap()
                                            presentedStoryEventID = event.id
                                        } label: {
                                            Label("Story", systemImage: "book.pages")
                                        }
                                        .tint(Color("AppPrimary"))
                                    }
                                }
                                .onMove { source, destination in
                                    store.moveTimelineEvents(from: source, to: destination)
                                    FeedbackService.lightTap()
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                        .padding(.top, -8)
                    }
                }

                FloatingAddButton {
                    viewModel.prepareNewEntry()
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
            .appNavigationChrome("Your Life Events")
            .toolbar {
                if !store.events.isEmpty {
                    EditButton()
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .sheet(isPresented: $viewModel.showingForm) {
                EventFormSheet(viewModel: viewModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: Binding(
                get: { presentedStoryEventID != nil },
                set: { if !$0 { presentedStoryEventID = nil } }
            )) {
                if let eventID = presentedStoryEventID {
                    NavigationStack {
                        StoryDetailView(eventID: eventID)
                            .environmentObject(store)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Close") {
                                        presentedStoryEventID = nil
                                    }
                                    .foregroundStyle(Color("AppPrimary"))
                                }
                            }
                    }
                }
            }
        }
    }

    private func linkCount(for eventID: String) -> Int {
        store.graphLinks.filter {
            ($0.kind == .journalEvent && $0.secondaryID == eventID) ||
            ($0.kind == .eventFavorite && $0.primaryID == eventID)
        }.count
    }
}

struct EventFormSheet: View {
    @EnvironmentObject private var store: AppStorage
    @ObservedObject var viewModel: ChronologyCanvasViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Event Details")
                            TextField("Title", text: $viewModel.title)
                                .padding(14)
                                .background(Color("AppSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))

                            if !viewModel.titleError.isEmpty {
                                Text(viewModel.titleError).font(.caption).foregroundStyle(.red)
                            }

                            TextField("Description", text: $viewModel.descriptionText, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(Color("AppSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))

                            DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(14)
                                .glassCard()
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Pick an Icon")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                                ForEach(viewModel.iconOptions, id: \.self) { icon in
                                    Button {
                                        FeedbackService.lightTap()
                                        viewModel.selectedIcon = icon
                                    } label: {
                                        Text(icon)
                                            .font(.title)
                                            .frame(width: 48, height: 48)
                                            .background(viewModel.selectedIcon == icon ? Color("AppPrimary") : Color("AppSurface"))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(viewModel.selectedIcon == icon ? Color("AppAccent") : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(14)
                            .glassCard()
                        }
                    }
                    .appScreenContentPadding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(viewModel.editingEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextPrimary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(using: store) {
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
