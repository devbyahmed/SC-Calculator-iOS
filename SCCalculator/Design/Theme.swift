import SwiftUI

/// Apple-style design tokens. Everything uses system colors and system fonts,
/// so the app adapts to Dark Mode, Dynamic Type and Liquid Glass automatically.
enum Theme {
    /// The one accent color used for primary actions and selection.
    static let accent = Color.indigo

    /// Tile colors, chosen from Apple's system palette (stored by index).
    static let tints: [Color] = [.indigo, .blue, .teal, .green, .orange, .yellow, .pink, .red, .purple, .gray]

    static func tint(_ index: Int) -> Color {
        tints[((index % tints.count) + tints.count) % tints.count]
    }

    // Grouped surfaces, as in Settings and Health.
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let fill = Color(uiColor: .tertiarySystemFill)
    static let secondaryFill = Color(uiColor: .secondarySystemFill)
}

/// An app-icon style square: solid system color, white SF Symbol, continuous corners.
/// Same construction as the icons in the Settings app.
struct AppIconView: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 60

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(tint)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.44, weight: .medium))
                    .foregroundStyle(.white)
            }
    }
}

/// Small icon used at the start of list rows (29 pt, like Settings).
struct SettingsIcon: View {
    let symbol: String
    let tint: Color

    var body: some View {
        AppIconView(symbol: symbol, tint: tint, size: 29)
    }
}

/// A rounded card on the grouped background, like a section in an inset grouped list.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
