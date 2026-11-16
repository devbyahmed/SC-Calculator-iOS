import Foundation

/// A shortcut tile in the vault that opens one of your (hidden) apps.
struct LauncherItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    /// What gets opened, e.g. "whatsapp://" or "shortcuts://run-shortcut?name=Open%20Bank".
    var link: String
    var symbol: String
    var tint: Int
    var group: String

    var url: URL? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else { return nil }
        return url
    }

    /// Builds a link that runs an Apple Shortcut by name (works for any app via "Open App").
    static func shortcutLink(named name: String) -> String {
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        return components.string ?? "shortcuts://"
    }

    /// The shortcut name, if this item runs a Shortcut.
    var shortcutName: String? {
        guard let comps = URLComponents(string: link), comps.scheme == "shortcuts",
              comps.host == "run-shortcut" else { return nil }
        return comps.queryItems?.first { $0.name == "name" }?.value
    }
}

/// Everything stored for one profile (real or decoy).
struct VaultData: Codable {
    var items: [LauncherItem] = []
    var groups: [String] = []

    static func starter(for profile: Profile) -> VaultData {
        switch profile {
        case .real: return VaultData(items: [], groups: ["Social", "Messages", "Money"])
        case .decoy: return VaultData(items: [], groups: ["Work", "Fitness"])
        }
    }
}

/// Symbols offered when customizing a tile.
enum TileSymbols {
    static let all: [String] = [
        "bubble.left.and.bubble.right.fill", "message.fill", "paperplane.fill", "phone.fill",
        "camera.fill", "photo.fill", "play.rectangle.fill", "film.fill",
        "music.note", "heart.fill", "person.2.fill", "globe",
        "envelope.fill", "briefcase.fill", "creditcard.fill", "dollarsign.circle.fill",
        "cart.fill", "map.fill", "car.fill", "gamecontroller.fill",
        "lock.fill", "star.fill", "bolt.fill", "sparkles",
    ]
}
