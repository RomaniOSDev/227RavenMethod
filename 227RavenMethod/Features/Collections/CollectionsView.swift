import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var store: AppStorage
    @State private var showingForm = false
    @State private var editingCollection: CuratorCollection?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    if store.collections.isEmpty {
                        EmptyStatePanel(
                            symbol: "folder.badge.plus",
                            title: "No Collections Yet",
                            message: "Create curated sets like Summer 2025 or Family with smart tag rules.",
                            actionTitle: "Create Collection",
                            action: { showingForm = true }
                        )
                        .padding(.bottom, 8)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.collections) { collection in
                                NavigationLink(value: DiscoverRoute.collection(collection.id)) {
                                    CollectionCardCell(
                                        name: collection.name,
                                        itemCount: MediaGraphService.collectionItems(for: collection, store: store).count,
                                        styleIndex: collection.coverStyleIndex
                                    )
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded { FeedbackService.lightTap() })
                            }
                        }
                    }
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome("Collections")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    FeedbackService.lightTap()
                    editingCollection = nil
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            CollectionFormSheet(collection: editingCollection)
                .environmentObject(store)
        }
    }
}

struct CollectionDetailView: View {
    @EnvironmentObject private var store: AppStorage
    let collectionID: String
    @State private var showingEdit = false
    @State private var showingAddItems = false

    private var collection: CuratorCollection? {
        store.collections.first { $0.id == collectionID }
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    if let collection {
                        let items = MediaGraphService.collectionItems(for: collection, store: store)

                        CollectionCoverView(styleIndex: collection.coverStyleIndex, itemCount: items.count)
                            .frame(height: 168)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color("AppPrimary").opacity(0.35), lineWidth: 1)
                            )

                        rulesSummary(collection)

                        SectionHeaderView(title: "Items", trailing: "\(items.count)")

                        if items.isEmpty {
                            InsightSuggestionCell(
                                symbol: "tray",
                                message: "No items match this collection yet. Add manual items or adjust smart rules."
                            )
                        } else {
                            ForEach(items) { ref in
                                itemRow(ref)
                            }
                        }
                    }
                }
                .appScreenContentPadding()
            }
            .scrollContentBackground(.hidden)
        }
        .appNavigationChrome(collection?.name ?? "Collection")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Rules") {
                        FeedbackService.lightTap()
                        showingEdit = true
                    }
                    Button("Add Items") {
                        FeedbackService.lightTap()
                        showingAddItems = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let collection {
                CollectionFormSheet(collection: collection)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showingAddItems) {
            if let collection {
                CollectionAddItemsSheet(collectionID: collection.id)
                    .environmentObject(store)
            }
        }
    }

    private func rulesSummary(_ collection: CuratorCollection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !collection.ruleTags.isEmpty {
                TagChipRowView(tags: collection.ruleTags, maxVisible: 6)
            }
            HStack(spacing: 8) {
                if let date = collection.ruleAfterDate {
                    MetaChipView(symbol: "calendar", text: "After \(date.formatted(date: .abbreviated, time: .omitted))")
                }
                MetaChipView(symbol: "hand.tap", text: "\(collection.manualRefs.count) manual")
            }
        }
        .padding(16)
        .glassCard()
    }

    @ViewBuilder
    private func itemRow(_ ref: GraphNodeRef) -> some View {
        switch ref.kind {
        case .journal:
            if let journal = store.mediaJournals.first(where: { $0.id == ref.id }) {
                JournalEntryCell(entry: journal, linkedEventTitle: nil)
            }
        case .event:
            if let event = store.events.first(where: { $0.id == ref.id }) {
                TimelineEventCell(event: event, linkCount: 0)
            }
        case .favorite:
            if let item = SampleMediaCatalog.items.first(where: { $0.id == ref.id }) {
                HighlightCardCell(
                    item: item,
                    isFavorite: true,
                    isScaled: false,
                    onStar: {}
                )
            }
        }
    }
}

struct CollectionFormSheet: View {
    @EnvironmentObject private var store: AppStorage
    @Environment(\.dismiss) private var dismiss

    let collection: CuratorCollection?

    @State private var name = ""
    @State private var ruleTagsText = ""
    @State private var useDateRule = false
    @State private var ruleAfterDate = Date()
    @State private var coverStyleIndex = 0
    @State private var nameError = ""
    @State private var shakeTrigger: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: shakeTrigger))
                        if !nameError.isEmpty {
                            Text(nameError).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section("Smart Rules") {
                        TextField("Tags (comma separated)", text: $ruleTagsText)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Toggle("Only after date", isOn: $useDateRule)
                            .foregroundStyle(Color("AppTextPrimary"))
                        if useDateRule {
                            DatePicker("After", selection: $ruleAfterDate, displayedComponents: .date)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }
                    Section("Cover Style") {
                        Picker("Style", selection: $coverStyleIndex) {
                            ForEach(0..<6, id: \.self) { index in
                                Text("Style \(index + 1)").tag(index)
                            }
                        }
                        CollectionCoverView(styleIndex: coverStyleIndex, itemCount: 4)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(collection == nil ? "New Collection" : "Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let collection else { return }
        name = collection.name
        ruleTagsText = collection.ruleTags.joined(separator: ", ")
        useDateRule = collection.ruleAfterDate != nil
        ruleAfterDate = collection.ruleAfterDate ?? Date()
        coverStyleIndex = collection.coverStyleIndex
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            nameError = "Name is required."
            shakeTrigger += 1
            FeedbackService.warning()
            return
        }
        let tags = ruleTagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if var existing = collection {
            existing.name = trimmed
            existing.ruleTags = tags
            existing.ruleAfterDate = useDateRule ? ruleAfterDate : nil
            existing.coverStyleIndex = coverStyleIndex
            store.updateCollection(existing)
        } else {
            store.addCollection(
                CuratorCollection(
                    name: trimmed,
                    coverStyleIndex: coverStyleIndex,
                    ruleTags: tags,
                    ruleAfterDate: useDateRule ? ruleAfterDate : nil
                )
            )
        }
        FeedbackService.success()
        dismiss()
    }
}

struct CollectionAddItemsSheet: View {
    @EnvironmentObject private var store: AppStorage
    @Environment(\.dismiss) private var dismiss
    let collectionID: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section("Journals") {
                        ForEach(store.mediaJournals) { journal in
                            toggleRow(
                                title: journal.caption,
                                isOn: isManual(.journal(journal.id)),
                                action: { setManual(.journal(journal.id), enabled: $0) }
                            )
                        }
                    }
                    Section("Favorites") {
                        ForEach(store.favoriteMedia, id: \.self) { favoriteID in
                            if let item = SampleMediaCatalog.items.first(where: { $0.id == favoriteID }) {
                                toggleRow(
                                    title: item.title,
                                    isOn: isManual(.favorite(favoriteID)),
                                    action: { setManual(.favorite(favoriteID), enabled: $0) }
                                )
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        FeedbackService.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }

    private func isManual(_ ref: GraphNodeRef) -> Bool {
        guard let collection = store.collections.first(where: { $0.id == collectionID }) else { return false }
        return collection.manualRefs.contains(ref)
    }

    private func setManual(_ ref: GraphNodeRef, enabled: Bool) {
        guard var collection = store.collections.first(where: { $0.id == collectionID }) else { return }
        if enabled {
            if !collection.manualRefs.contains(ref) {
                collection.manualRefs.append(ref)
            }
        } else {
            collection.manualRefs.removeAll { $0 == ref }
        }
        store.updateCollection(collection)
        FeedbackService.lightTap()
    }

    private func toggleRow(title: String, isOn: Bool, action: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: action)) {
            Text(title)
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }
}
