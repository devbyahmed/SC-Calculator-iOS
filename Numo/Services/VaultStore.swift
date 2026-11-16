import Foundation
import Observation

/// Loads and saves one profile's tiles and groups as an encrypted-at-rest JSON file.
@Observable
final class VaultStore {
    let profile: Profile
    private(set) var data: VaultData

    init(profile: Profile) {
        self.profile = profile
        self.data = Self.load(profile) ?? .starter(for: profile)
    }

    var items: [LauncherItem] { data.items }
    var groups: [String] { data.groups }

    func items(in group: String?) -> [LauncherItem] {
        guard let group else { return data.items }
        return data.items.filter { $0.group == group }
    }

    // MARK: Tiles

    func upsert(_ item: LauncherItem) {
        if let index = data.items.firstIndex(where: { $0.id == item.id }) {
            data.items[index] = item
        } else {
            data.items.append(item)
        }
        if !item.group.isEmpty, !data.groups.contains(item.group) {
            data.groups.append(item.group)
        }
        save()
    }

    func delete(_ item: LauncherItem) {
        data.items.removeAll { $0.id == item.id }
        save()
    }

    func move(_ item: LauncherItem, to group: String) {
        guard let index = data.items.firstIndex(where: { $0.id == item.id }) else { return }
        data.items[index].group = group
        save()
    }

    // MARK: Groups

    func addGroup(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !data.groups.contains(trimmed) else { return }
        data.groups.append(trimmed)
        save()
    }

    /// Removes a group; its tiles stay, ungrouped.
    func removeGroup(_ name: String) {
        data.groups.removeAll { $0 == name }
        for index in data.items.indices where data.items[index].group == name {
            data.items[index].group = ""
        }
        save()
    }

    // MARK: Files

    private static func fileURL(_ profile: Profile) -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("vault-\(profile.rawValue).json")
    }

    private static func load(_ profile: Profile) -> VaultData? {
        guard let raw = try? Data(contentsOf: fileURL(profile)) else { return nil }
        return try? JSONDecoder().decode(VaultData.self, from: raw)
    }

    private func save() {
        guard let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: Self.fileURL(profile), options: [.atomic, .completeFileProtection])
    }

    static func wipeAll() {
        try? FileManager.default.removeItem(at: fileURL(.real))
        try? FileManager.default.removeItem(at: fileURL(.decoy))
    }
}
