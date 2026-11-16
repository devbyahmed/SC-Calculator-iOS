import UIKit

/// The disguise icons bundled with the app. iOS shows a short system alert whenever the icon changes.
enum AppIconChoice: String, CaseIterable, Identifiable {
    case calculator, notes, weather, compass

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    /// nil = the primary icon (Calculator).
    var alternateIconName: String? {
        self == .calculator ? nil : "AppIcon-\(title)"
    }

    /// Image set used to show the icon inside the app.
    var previewImageName: String { "Preview-\(title)" }

    @MainActor
    static var current: AppIconChoice {
        let name = UIApplication.shared.alternateIconName
        return allCases.first { $0.alternateIconName == name } ?? .calculator
    }

    @MainActor
    func apply() async throws {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        try await UIApplication.shared.setAlternateIconName(alternateIconName)
    }
}
