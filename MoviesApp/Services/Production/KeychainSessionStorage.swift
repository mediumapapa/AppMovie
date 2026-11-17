import Foundation
import Security

// Guarda la sesión de TMDB en el Llavero (Keychain) del teléfono.
// El Llavero está cifrado por el sistema; es el lugar indicado para identificadores de sesión,
// a diferencia de UserDefaults, que es un archivo de texto sin cifrar.
struct KeychainSessionStorage: SessionStorageProtocol {

    private let service = "com.appmovie.movies-app.session"
    private let account = "tmdb"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func load() -> UserSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func save(_ session: UserSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        clear()

        var query = baseQuery
        query[kSecValueData as String] = data
        // Se puede leer desde que el teléfono se desbloquea por primera vez después de encenderlo
        // (iOS a veces prepara la app con el teléfono bloqueado) y no pasa a respaldos de otros dispositivos
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("No se pudo guardar la sesión en el Llavero (código \(status))")
        }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
