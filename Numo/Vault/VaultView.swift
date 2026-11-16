import SwiftUI

/// The unlocked space: your hidden apps in a Home Screen–style grid, filtered by group.
struct VaultView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let store: VaultStore

    @State private var selectedGroup: String?
    @State private var searchText = ""
    @State private var editing: LauncherItem?
    @State private var isAdding = false
    @State private var showSettings = false
    @State private var showGuide = false
    @State private var failedItem: LauncherItem?
    @State private var newGroupName = ""
    @State private var isAddingGroup = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var visibleItems: [LauncherItem] {
        let items = store.items(in: selectedGroup)
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    filterBar

                    if store.items.isEmpty {
                        emptyState
                    } else {
                        appsSection
                    }

                    moreSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.groupedBackground)
            .navigationTitle("Apps")
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { model.lock() } label: {
                        Image(systemName: "lock")
                    }
                    .accessibilityLabel("Lock")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { isAdding = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add App")
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .sheet(isPresented: $isAdding) {
            LauncherEditor(store: store, item: nil, preferredGroup: selectedGroup)
        }
        .sheet(item: $editing) { item in
            LauncherEditor(store: store, item: item, preferredGroup: nil)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
        .sheet(isPresented: $showGuide) {
            HideGuideView()
        }
        .alert("Couldn't Open \(failedItem?.name ?? "App")", isPresented: Binding(
            get: { failedItem != nil },
            set: { if !$0 { failedItem = nil } }
        )) {
            Button("Edit Link") {
                editing = failedItem
                failedItem = nil
            }
            Button("OK", role: .cancel) { failedItem = nil }
        } message: {
            Text("The app may not be installed, or its link has changed. You can open it with a Shortcut instead — see Hide Guide.")
        }
        .alert("New Group", isPresented: $isAddingGroup) {
            TextField("Name", text: $newGroupName)
            Button("Cancel", role: .cancel) { newGroupName = "" }
            Button("Add") {
                let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addGroup(name)
                if !name.isEmpty { selectedGroup = name }
                newGroupName = ""
            }
        }
    }

    // MARK: Sections

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedGroup == nil) { selectedGroup = nil }
                ForEach(store.groups, id: \.self) { group in
                    FilterChip(title: group, isSelected: selectedGroup == group) { selectedGroup = group }
                        .contextMenu {
                            Button("Delete Group", systemImage: "trash", role: .destructive) {
                                if selectedGroup == group { selectedGroup = nil }
                                store.removeGroup(group)
                            }
                        }
                }
                Button { isAddingGroup = true } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Theme.secondaryFill, in: Circle())
                }
                .accessibilityLabel("New Group")
            }
        }
        .scrollIndicators(.hidden)
        .animation(.snappy(duration: 0.2), value: selectedGroup)
    }

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: selectedGroup ?? "All Apps", detail: "\(visibleItems.count)")

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(visibleItems) { item in
                    AppTile(item: item) { open(item) }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { editing = item }
                            Menu("Move to Group", systemImage: "folder") {
                                ForEach(store.groups, id: \.self) { group in
                                    Button(group) { store.move(item, to: group) }
                                }
                                Button("No Group") { store.move(item, to: "") }
                            }
                            Divider()
                            Button("Remove", systemImage: "trash", role: .destructive) { store.delete(item) }
                        }
                }
                if searchText.isEmpty {
                    AddTile { isAdding = true }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .card()
            .animation(.snappy(duration: 0.25), value: visibleItems)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Apps Yet", systemImage: "square.grid.2x2")
        } description: {
            Text("Add the apps you've hidden, so you can open them from here.")
        } actions: {
            Button("Add App") { isAdding = true }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 12)
        .card()
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Hiding", detail: nil)
            VStack(spacing: 0) {
                ListRow(symbol: "eye.slash.fill", tint: .teal, title: "Hide Guide",
                        subtitle: "Hide apps from your Home Screen") { showGuide = true }
                Divider().padding(.leading, 57)
                ListRow(symbol: "plus", tint: Theme.accent, title: "Add App",
                        subtitle: "From popular apps or a Shortcut") { isAdding = true }
            }
            .card()
        }
    }

    private func open(_ item: LauncherItem) {
        guard let url = item.url else {
            failedItem = item
            return
        }
        openURL(url) { accepted in
            if !accepted { failedItem = item }
        }
    }
}

// MARK: - Components

/// Capsule filter, like the category filters in Mail and Photos.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isSelected ? Theme.accent : Theme.secondaryFill, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Small section title above a card, like inset grouped list headers.
struct SectionHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let detail { Text(detail) }
        }
        .font(.footnote)
        .textCase(.uppercase)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
    }
}

/// One tappable row inside a card, with a Settings-style icon.
struct ListRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIcon(symbol: symbol, tint: tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
    }
}

/// A Home Screen–style app: icon and name.
struct AppTile: View {
    let item: LauncherItem
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AppIconView(symbol: item.symbol, tint: Theme.tint(item.tint), size: 60)
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(IconPressStyle())
    }
}

/// The "+" tile at the end of the grid.
struct AddTile: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 13.5, style: .continuous)
                    .fill(Theme.fill)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                Text("Add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(IconPressStyle())
    }
}

struct IconPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(uiColor: .systemGray4) : Color.clear)
    }
}
