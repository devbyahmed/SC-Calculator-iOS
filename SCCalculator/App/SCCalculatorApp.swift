import SwiftUI

@main
struct SCCalculatorApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch model.screen {
            case .setup:
                SetupView()
                    .transition(.opacity)
            case .calculator:
                CalculatorView { code in model.submit(code: code) }
                    .transition(.opacity)
            case .vault:
                if let vault = model.vault {
                    VaultView(store: vault)
                        .transition(.opacity)
                }
            }

            if model.isObscured && model.isInVault {
                PrivacyCover()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            model.isObscured = phase != .active
            if phase == .background {
                model.lock()
            }
        }
    }
}

/// Shown over the vault in the app switcher so nothing private is visible.
private struct PrivacyCover: View {
    var body: some View {
        Color.black.ignoresSafeArea()
    }
}
