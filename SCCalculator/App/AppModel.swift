import SwiftUI
import Observation

/// Which screen is showing, and the lock/unlock logic.
@MainActor
@Observable
final class AppModel {
    enum Screen {
        case setup, calculator, vault
    }

    nonisolated static let requireAuthKey = "requireAuth"

    private(set) var screen: Screen
    /// The unlocked vault. Dropped from memory whenever the app locks.
    private(set) var vault: VaultStore?
    /// True while the app isn't active, to hide the vault in the app switcher.
    var isObscured = false

    private var isUnlocking = false

    init() {
        SecretStore.shared.wipeIfFreshInstall()
        UserDefaults.standard.register(defaults: [Self.requireAuthKey: true])
        screen = SecretStore.shared.hasCode(for: .real) ? .calculator : .setup
    }

    var isInVault: Bool { screen == .vault }

    /// Called when "<digits> =" is pressed on the calculator.
    func submit(code: String) {
        guard !isUnlocking, let profile = SecretStore.shared.match(code) else { return }
        isUnlocking = true
        Task {
            defer { isUnlocking = false }
            if UserDefaults.standard.bool(forKey: Self.requireAuthKey) {
                let ok = await Authenticator.authenticate(reason: "Unlock your space")
                guard ok else { return }
            }
            vault = VaultStore(profile: profile)
            withAnimation(.spring(duration: 0.45)) { screen = .vault }
        }
    }

    func lock() {
        guard screen == .vault else { return }
        withAnimation(.easeInOut(duration: 0.25)) { screen = .calculator }
        vault = nil
    }

    func finishSetup() {
        withAnimation(.easeInOut(duration: 0.3)) { screen = .calculator }
    }

    /// Deletes all codes, tiles and settings and returns to first-run setup.
    func eraseEverything() {
        SecretStore.shared.wipeAll()
        VaultStore.wipeAll()
        UserDefaults.standard.set(true, forKey: Self.requireAuthKey)
        vault = nil
        withAnimation { screen = .setup }
    }
}
