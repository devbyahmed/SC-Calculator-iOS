import Foundation

/// Popular apps and the links that open them. Apps can change their links;
/// if one stops working, use a Shortcut instead (see the guide).
struct CatalogApp: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let link: String
    let symbol: String
    let tint: Int
    let group: String
}

enum AppCatalog {
    static let apps: [CatalogApp] = [
        CatalogApp(name: "WhatsApp", link: "whatsapp://", symbol: "phone.fill", tint: 3, group: "Messages"),
        CatalogApp(name: "Telegram", link: "tg://", symbol: "paperplane.fill", tint: 1, group: "Messages"),
        CatalogApp(name: "Signal", link: "sgnl://", symbol: "bubble.left.and.bubble.right.fill", tint: 1, group: "Messages"),
        CatalogApp(name: "Messenger", link: "fb-messenger://", symbol: "message.fill", tint: 1, group: "Messages"),
        CatalogApp(name: "Viber", link: "viber://", symbol: "phone.fill", tint: 8, group: "Messages"),
        CatalogApp(name: "Discord", link: "discord://", symbol: "gamecontroller.fill", tint: 0, group: "Messages"),
        CatalogApp(name: "Slack", link: "slack://", symbol: "bubble.left.and.bubble.right.fill", tint: 8, group: "Messages"),
        CatalogApp(name: "Instagram", link: "instagram://", symbol: "camera.fill", tint: 6, group: "Social"),
        CatalogApp(name: "Facebook", link: "fb://", symbol: "person.2.fill", tint: 1, group: "Social"),
        CatalogApp(name: "Snapchat", link: "snapchat://", symbol: "camera.fill", tint: 5, group: "Social"),
        CatalogApp(name: "TikTok", link: "snssdk1233://", symbol: "music.note", tint: 9, group: "Social"),
        CatalogApp(name: "X", link: "twitter://", symbol: "bolt.fill", tint: 9, group: "Social"),
        CatalogApp(name: "Threads", link: "barcelona://", symbol: "at", tint: 9, group: "Social"),
        CatalogApp(name: "Reddit", link: "reddit://", symbol: "globe", tint: 4, group: "Social"),
        CatalogApp(name: "Pinterest", link: "pinterest://", symbol: "heart.fill", tint: 7, group: "Social"),
        CatalogApp(name: "LinkedIn", link: "linkedin://", symbol: "briefcase.fill", tint: 1, group: "Social"),
        CatalogApp(name: "Tinder", link: "tinder://", symbol: "heart.fill", tint: 6, group: "Social"),
        CatalogApp(name: "Bumble", link: "bumble://", symbol: "heart.fill", tint: 5, group: "Social"),
        CatalogApp(name: "YouTube", link: "youtube://", symbol: "play.rectangle.fill", tint: 7, group: "Social"),
        CatalogApp(name: "Twitch", link: "twitch://", symbol: "play.rectangle.fill", tint: 8, group: "Social"),
        CatalogApp(name: "Netflix", link: "nflx://", symbol: "film.fill", tint: 7, group: "Social"),
        CatalogApp(name: "Spotify", link: "spotify://", symbol: "music.note", tint: 3, group: "Social"),
        CatalogApp(name: "PayPal", link: "paypal://", symbol: "dollarsign.circle.fill", tint: 1, group: "Money"),
        CatalogApp(name: "Venmo", link: "venmo://", symbol: "dollarsign.circle.fill", tint: 1, group: "Money"),
        CatalogApp(name: "Gmail", link: "googlegmail://", symbol: "envelope.fill", tint: 7, group: "Messages"),
        CatalogApp(name: "Outlook", link: "ms-outlook://", symbol: "envelope.fill", tint: 1, group: "Messages"),
        CatalogApp(name: "Teams", link: "msteams://", symbol: "person.2.fill", tint: 0, group: "Messages"),
        CatalogApp(name: "Chrome", link: "googlechrome://", symbol: "globe", tint: 5, group: "Social"),
        CatalogApp(name: "Google Maps", link: "comgooglemaps://", symbol: "map.fill", tint: 3, group: "Social"),
        CatalogApp(name: "Uber", link: "uber://", symbol: "car.fill", tint: 9, group: "Social"),
        CatalogApp(name: "Amazon", link: "com.amazon.mobile.shopping://", symbol: "cart.fill", tint: 4, group: "Money"),
    ]
}
