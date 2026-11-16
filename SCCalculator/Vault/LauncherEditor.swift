import SwiftUI

/// Add or edit an app: pick a popular app, or enter a link / Shortcut name yourself.
/// Laid out like Reminders' list editor: big preview, then color and symbol pickers.
struct LauncherEditor: View {
    @Environment(\.dismiss) private var dismiss
    let store: VaultStore
    let original: LauncherItem?

    private enum OpenMethod: String, CaseIterable, Identifiable {
        case link = "App Link", shortcut = "Shortcut"
        var id: String { rawValue }
    }

    @State private var name: String
    @State private var link: String
    @State private var shortcutName: String
    @State private var method: OpenMethod
    @State private var symbol: String
    @State private var tint: Int
    @State private var group: String

    init(store: VaultStore, item: LauncherItem?, preferredGroup: String?) {
        self.store = store
        self.original = item
        let shortcut = item?.shortcutName
        _name = State(initialValue: item?.name ?? "")
        _link = State(initialValue: shortcut == nil ? (item?.link ?? "") : "")
        _shortcutName = State(initialValue: shortcut ?? "")
        _method = State(initialValue: shortcut == nil ? .link : .shortcut)
        _symbol = State(initialValue: item?.symbol ?? "app.fill")
        _tint = State(initialValue: item?.tint ?? 0)
        _group = State(initialValue: item?.group ?? preferredGroup ?? store.groups.first ?? "")
    }

    private var finalLink: String {
        switch method {
        case .link: return link.trimmingCharacters(in: .whitespacesAndNewlines)
        case .shortcut: return LauncherItem.shortcutLink(named: shortcutName.trimmingCharacters(in: .whitespaces))
        }
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespaces).isEmpty
        switch method {
        case .link: return hasName && URL(string: finalLink)?.scheme != nil
        case .shortcut: return hasName && !shortcutName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        AppIconView(symbol: symbol, tint: Theme.tint(tint), size: 88)
                        TextField("Name", text: $name)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(Theme.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.vertical, 8)
                }

                if original == nil {
                    Section {
                        NavigationLink {
                            CatalogPicker { app in apply(app) }
                        } label: {
                            Label {
                                Text("Choose a Popular App")
                            } icon: {
                                SettingsIcon(symbol: "square.grid.2x2.fill", tint: .blue)
                            }
                        }
                    }
                }

                Section {
                    Picker("Opens With", selection: $method) {
                        ForEach(OpenMethod.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    switch method {
                    case .link:
                        TextField("whatsapp://", text: $link)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .font(.body.monospaced())
                    case .shortcut:
                        TextField("Shortcut Name", text: $shortcutName)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Opens With")
                } footer: {
                    switch method {
                    case .link:
                        Text("The link that opens the app. Popular apps fill this in for you.")
                    case .shortcut:
                        Text("In Shortcuts, create a shortcut with one action, **Open App**, and choose the app. Enter its exact name here. Works with any app.")
                    }
                }

                Section("Group") {
                    Picker("Group", selection: $group) {
                        Text("None").tag("")
                        ForEach(store.groups, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(Theme.tints.indices, id: \.self) { index in
                            Circle()
                                .fill(Theme.tints[index])
                                .frame(width: 40, height: 40)
                                .padding(4)
                                .overlay {
                                    Circle()
                                        .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 3)
                                        .opacity(tint == index ? 1 : 0)
                                }
                                .onTapGesture { tint = index }
                                .accessibilityAddTraits(tint == index ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(TileSymbols.all, id: \.self) { name in
                            Image(systemName: name)
                                .font(.system(size: 18))
                                .foregroundStyle(symbol == name ? Color.white : Color.secondary)
                                .frame(width: 44, height: 44)
                                .background(symbol == name ? Theme.tint(tint) : Theme.fill, in: Circle())
                                .onTapGesture { symbol = name }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(original == nil ? "New App" : "Edit App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func apply(_ app: CatalogApp) {
        name = app.name
        link = app.link
        method = .link
        symbol = app.symbol
        tint = app.tint
        if store.groups.contains(app.group) { group = app.group }
    }

    private func save() {
        store.upsert(
            LauncherItem(
                id: original?.id ?? UUID(),
                name: name.trimmingCharacters(in: .whitespaces),
                link: finalLink,
                symbol: symbol,
                tint: tint,
                group: group
            )
        )
        dismiss()
    }
}

/// Searchable list of popular apps with known links.
struct CatalogPicker: View {
    @Environment(\.dismiss) private var dismiss
    var onPick: (CatalogApp) -> Void
    @State private var query = ""

    private var results: [CatalogApp] {
        let sorted = AppCatalog.apps.sorted { $0.name < $1.name }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(results) { app in
            Button {
                onPick(app)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    AppIconView(symbol: app.symbol, tint: Theme.tint(app.tint), size: 34)
                    Text(app.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(app.link)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Apps")
        .navigationTitle("Popular Apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}
