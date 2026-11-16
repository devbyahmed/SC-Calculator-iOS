import SwiftUI

/// Step-by-step help for hiding apps with iOS's own tools (free, no developer account needed).
struct HideGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Topic: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let title: String
        let steps: [String]
        let note: String?
    }

    private let topics: [Topic] = [
        Topic(
            symbol: "eye.slash.fill", tint: .indigo, title: "Hide an App",
            steps: [
                "On the Home Screen, touch and hold the app's icon.",
                "Tap **Require Face ID**.",
                "Tap **Hide and Require Face ID**, then **Hide App**.",
            ],
            note: "The app disappears from the Home Screen and search, and its notifications are hidden. It stays in a locked Hidden folder at the bottom of the App Library. Requires iOS 18 or later. Some Apple apps can be locked but not hidden."
        ),
        Topic(
            symbol: "plus", tint: .blue, title: "Add It to SC Calculator",
            steps: [
                "In Apps, tap **+**.",
                "Choose it from **Popular Apps**, or enter its link.",
                "Tap the app any time to open it. iOS asks for Face ID.",
            ],
            note: nil
        ),
        Topic(
            symbol: "square.2.layers.3d.fill", tint: .pink, title: "Apps Without a Link",
            steps: [
                "In the **Shortcuts** app, tap **+**.",
                "Add the **Open App** action and choose the app.",
                "Name the shortcut, for example “Open Bank”.",
                "In SC Calculator, add an app, choose **Shortcut**, and enter that name.",
            ],
            note: "Works with any app. Shortcuts appears briefly while the app opens."
        ),
        Topic(
            symbol: "moon.fill", tint: .purple, title: "Hide on a Schedule",
            steps: [
                "Move the apps you want to hide onto their own Home Screen page.",
                "Go to **Settings › Focus**, tap **+**, then **Custom**.",
                "Under **Customize Screens**, choose only the pages to show, leaving the private page out.",
                "Tap **Add Schedule › Time** and choose when it turns on.",
            ],
            note: "While that Focus is on, the private page is hidden. The apps are still in the App Library and in SC Calculator."
        ),
        Topic(
            symbol: "square.stack.3d.up.fill", tint: .orange, title: "Hide Groups Together",
            steps: [
                "Give each group its own Home Screen page.",
                "Create a Focus for each group that hides its page.",
                "Turn a Focus on from Control Center to hide that group.",
            ],
            note: "Name your groups in SC Calculator the same way, so each set is easy to find."
        ),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        AppIconView(symbol: "eye.slash.fill", tint: .teal, size: 48)
                        Text("iOS hides the apps. SC Calculator is your disguised, locked way back to them.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }

                ForEach(topics) { topic in
                    Section {
                        ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                Text(LocalizedStringKey(step))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } header: {
                        Label {
                            Text(topic.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        } icon: {
                            SettingsIcon(symbol: topic.symbol, tint: topic.tint)
                        }
                        .padding(.bottom, 4)
                    } footer: {
                        if let note = topic.note {
                            Text(note)
                        }
                    }
                }
            }
            .navigationTitle("Hide Guide")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
