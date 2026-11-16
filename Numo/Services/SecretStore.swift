import CryptoKit
import Foundation
import Security

/// Which space a code opens: your real vault or the harmless decoy.
enum Profile: String, Codable {
    case real, decoy
}

/// Stores salted SHA-256 hashes of the secret codes in the Keychain (never the codes themselves).
final class SecretStore {
    static let shared = SecretStore()

    private let service = "numo.secrets"
    private let installFlag = "numo.installed"

    private init() {}

    /// The Keychain survives app deletion, but the vault files don't.
    /// On a fresh install, clear old codes so the user starts clean.
    func wipeIfFreshInstall() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: installFlag) else { return }
        wipeAll()
        defaults.set(true, forKey: installFlag)
    }

    func hasCode(for profile: Profile) -> Bool {
        read(account(for: profile)) != nil
    }

    func setCode(_ code: String, for profile: Profile) {
        write(hash(code), account: account(for: profile))
    }

    func removeCode(for profile: Profile) {
        delete(account(for: profile))
    }

    /// Which profile this code unlocks, if any.
    func match(_ code: String) -> Profile? {
        let candidate = hash(code)
        if let real = read(account(for: .real)), real == candidate { return .real }
        if let decoy = read(account(for: .decoy)), decoy == candidate { return .decoy }
        return nil
    }

    func wipeAll() {
        delete(account(for: .real))
        delete(account(for: .decoy))
        delete("salt")
    }

    // MARK: Hashing

    private func account(for profile: Profile) -> String {
        "code.\(profile.rawValue)"
    }

    private func salt() -> Data {
        if let existing = read("salt") { return existing }
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let data = Data(bytes)
        write(data, account: "salt")
        return data
    }

    private func hash(_ code: String) -> Data {
        var input = salt()
        input.append(Data(code.utf8))
        return Data(SHA256.hash(data: input))
    }

    // MARK: Keychain

    private func query(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func read(_ account: String) -> Data? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private func write(_ data: Data, account: String) {
        delete(account)
        var q = query(account)
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    private func delete(_ account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
