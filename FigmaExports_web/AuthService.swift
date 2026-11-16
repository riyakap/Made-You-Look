import Foundation
import Security
import CryptoKit

// MARK: - Types

enum AuthProvider: String, Codable, Identifiable {
    case email, google, apple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email: "email and password"
        case .google: "Google"
        case .apple: "Apple"
        }
    }
}

enum AuthError: LocalizedError, Equatable {
    case missingName
    case invalidEmail
    case weakPassword
    case passwordsDontMatch
    case noAccount
    case wrongPassword
    case wrongProvider(AuthProvider)
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .missingName: "Enter your name."
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Use a password with at least 8 characters."
        case .passwordsDontMatch: "The passwords don't match."
        case .noAccount: "We couldn't find an account for that email on this device. New here? Close this and tap Get Started."
        case .wrongPassword: "That password isn't right. Try again."
        case .wrongProvider(let provider): "That email was registered with \(provider.displayName). Use that option to sign in."
        case .couldNotSave: "We couldn't save your account. Please try again."
        }
    }
}

/// What is kept for the login. The password itself is never stored, only a salted hash.
struct StoredAccount: Codable, Equatable {
    var email: String
    var provider: AuthProvider
    var salt: Data?
    var passwordHash: Data?
}

// MARK: - Service

/// Saves and checks the login on this device.
///
/// The account lives in the iOS Keychain (with a UserDefaults fallback if the Keychain is not
/// available, for example on some Mac builds). Passwords are stored as a salted, repeatedly
/// hashed value, never as text.
///
/// This is a PROTOTYPE login: it protects the account on this device only. There is no server,
/// and Google / Apple sign-in are simulated. For real accounts you would use a backend (Firebase
/// Auth, Sign in with Apple, the Google Sign-In SDK with your own client ID, and so on).
enum AuthService {
    private static let fallbackKey = "MadeYouLook.account.fallback"
    private static let launchedKey = "MadeYouLook.hasLaunched"

    // MARK: Checks

    static func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidEmail(_ email: String) -> Bool {
        let value = normalized(email)
        guard !value.contains(" "), let at = value.firstIndex(of: "@") else { return false }
        let local = value[..<at]
        let domain = value[value.index(after: at)...]
        return !local.isEmpty && domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    // MARK: Account

    /// The account saved on this device, if any.
    static var account: StoredAccount? {
        let data = Keychain.read() ?? UserDefaults.standard.data(forKey: fallbackKey)
        return data.flatMap { try? JSONDecoder().decode(StoredAccount.self, from: $0) }
    }

    /// Saves a new account, replacing any account already on this device.
    static func register(email: String, password: String?, provider: AuthProvider) throws {
        let email = normalized(email)
        guard isValidEmail(email) else { throw AuthError.invalidEmail }

        var stored = StoredAccount(email: email, provider: provider)
        if provider == .email {
            guard let password, password.count >= 8 else { throw AuthError.weakPassword }
            let salt = randomSalt()
            stored.salt = salt
            stored.passwordHash = hash(password, salt: salt)
        }
        try save(stored)
    }

    /// Checks an email and password. Throws if they do not match the saved account.
    static func verify(email: String, password: String) throws {
        guard let stored = account, stored.email == normalized(email) else { throw AuthError.noAccount }
        guard stored.provider == .email, let salt = stored.salt, let expected = stored.passwordHash else {
            throw AuthError.wrongProvider(stored.provider)
        }
        guard hash(password, salt: salt) == expected else { throw AuthError.wrongPassword }
    }

    /// Checks a Google / Apple sign-in against the saved account.
    static func verify(email: String, provider: AuthProvider) throws {
        guard let stored = account, stored.email == normalized(email) else { throw AuthError.noAccount }
        guard stored.provider == provider else { throw AuthError.wrongProvider(stored.provider) }
    }

    static func removeAccount() {
        Keychain.delete()
        UserDefaults.standard.removeObject(forKey: fallbackKey)
    }

    /// Keychain items survive deleting the app, so a fresh install clears any leftover account.
    static func resetOnFreshInstall() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: launchedKey) else { return }
        removeAccount()
        defaults.set(true, forKey: launchedKey)
    }

    // MARK: Private

    private static func save(_ account: StoredAccount) throws {
        guard let data = try? JSONEncoder().encode(account) else { throw AuthError.couldNotSave }
        if Keychain.write(data) {
            UserDefaults.standard.removeObject(forKey: fallbackKey)
        } else {
            UserDefaults.standard.set(data, forKey: fallbackKey)
        }
    }

    private static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private static func hash(_ password: String, salt: Data) -> Data {
        var digest = Data(SHA256.hash(data: salt + Data(password.utf8)))
        for _ in 0..<20_000 {
            digest = Data(SHA256.hash(data: digest + salt))
        }
        return digest
    }
}

// MARK: - Keychain

private enum Keychain {
    private static let service = "com.madeyoulook.account"
    private static let account = "login"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static func read() -> Data? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    @discardableResult
    static func write(_ data: Data) -> Bool {
        delete()
        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
