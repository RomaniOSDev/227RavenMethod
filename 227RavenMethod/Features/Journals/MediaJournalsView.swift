import PhotosUI
import SwiftUI

struct MediaJournalsView: View {
    @EnvironmentObject private var store: AppStorage
    @StateObject private var viewModel = MediaJournalsViewModel()
    var ignoresBottomSafeArea: Bool = true

    var body: some View {
        ZStack {
            AppBackgroundView(ignoresBottomSafeArea: ignoresBottomSafeArea)

            VStack(spacing: 0) {
                if store.mediaJournals.isEmpty {
                    ScrollView {
                        EmptyStatePanel(
                            symbol: "square.and.pencil",
                            title: "No Journals Yet",
                            message: "No journals yet — tap 'Add Entry' to start your first entry.",
                            actionTitle: "Add Entry",
                            action: { viewModel.prepareNewEntry(draft: store.draftCaption) }
                        )
                        .padding(.horizontal, 16)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    List {
                    Section {
                        InfoBannerCell(
                            symbol: "photo.on.rectangle.angled",
                            message: "Tap any entry to edit, add photos, tags, and graph links."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }

                    Section {
                        ForEach(store.mediaJournals) { entry in
                            Button {
                                FeedbackService.lightTap()
                                viewModel.prepareEdit(entry, store: store)
                            } label: {
                                JournalEntryCell(
                                    entry: entry,
                                    linkedEventTitle: MediaGraphService.event(forJournalID: entry.id, store: store)?.title
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .scaleEffect(viewModel.bounceEntryID == entry.id ? 1.02 : 1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.bounceEntryID)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        store.deleteJournalEntry(id: entry.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .padding(.top, -8)
            }

            Button {
                viewModel.prepareNewEntry(draft: store.draftCaption)
            } label: {
                Label("Add Entry", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(16)
            }
        }
        .sheet(isPresented: $viewModel.showingForm) {
            JournalFormSheet(viewModel: viewModel)
                .environmentObject(store)
        }
    }
}

struct JournalFormSheet: View {
    @EnvironmentObject private var store: AppStorage
    @ObservedObject var viewModel: MediaJournalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Photo & Caption")
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                HStack(spacing: 14) {
                                    StoredPhotoView(
                                        data: viewModel.selectedPhotoData,
                                        styleIndex: 0,
                                        symbolName: "photo.badge.plus"
                                    )
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Add Photo")
                                            .font(.headline)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        Text("Pick from your library")
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                .padding(14)
                                .glassCard()
                            }
                            .onChange(of: photoPickerItem) { item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self) {
                                        await MainActor.run {
                                            viewModel.applyPhotoData(data)
                                        }
                                    }
                                }
                            }

                            TextField("Caption", text: $viewModel.caption, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(Color("AppSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .onChange(of: viewModel.caption) { store.draftCaption = $0 }
                                .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))

                            if !viewModel.captionError.isEmpty {
                                Text(viewModel.captionError).font(.caption).foregroundStyle(.red)
                            }

                            TextField("Tags (comma separated)", text: $viewModel.tagsText)
                                .padding(14)
                                .background(Color("AppSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        if !store.events.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "Link to Story")
                                Picker("Timeline Event", selection: Binding(
                                    get: { viewModel.selectedEventID ?? "" },
                                    set: { viewModel.selectedEventID = $0.isEmpty ? nil : $0 }
                                )) {
                                    Text("None").tag("")
                                    ForEach(store.events) { event in
                                        Text(event.title).tag(event.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(14)
                                .glassCard()
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Link Favorites")
                            if store.favoriteMedia.isEmpty {
                                Text("Star highlights first, then link them here.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .padding(14)
                                    .glassCard()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(store.favoriteMedia, id: \.self) { favoriteID in
                                        if let item = SampleMediaCatalog.items.first(where: { $0.id == favoriteID }) {
                                            Toggle(isOn: Binding(
                                                get: { viewModel.selectedFavoriteIDs.contains(favoriteID) },
                                                set: { enabled in
                                                    if enabled { viewModel.selectedFavoriteIDs.insert(favoriteID) }
                                                    else { viewModel.selectedFavoriteIDs.remove(favoriteID) }
                                                    FeedbackService.lightTap()
                                                }
                                            )) {
                                                HStack(spacing: 10) {
                                                    MediaThumbnailView(styleIndex: item.styleIndex, symbolName: item.symbolName)
                                                        .frame(width: 36, height: 36)
                                                    Text(item.title)
                                                        .foregroundStyle(Color("AppTextPrimary"))
                                                }
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            if favoriteID != store.favoriteMedia.last {
                                                Divider().background(Color("AppTextSecondary").opacity(0.2))
                                            }
                                        }
                                    }
                                }
                                .glassCard()
                            }
                        }
                    }
                    .appScreenContentPadding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(viewModel.editingEntryID == nil ? "New Journal Entry" : "Edit Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { FeedbackService.lightTap(); dismiss() }
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(using: store) { dismiss() }
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
