import Foundation
import Observation

/// Almacén de estado compartido para la sesión de usuario.
/// Inicia y cierra sesión en TMDB con AuthServiceProtocol y guarda la sesión con SessionStorageProtocol,
/// así al volver a abrir la app el usuario entra directo al Home.
@MainActor
@Observable
final class AuthStore {
    private(set) var session: UserSession?

    private let authService: AuthServiceProtocol
    private let storage: SessionStorageProtocol

    init(authService: AuthServiceProtocol, storage: SessionStorageProtocol) {
        self.authService = authService
        self.storage = storage
        // Si había una sesión guardada, se recupera
        self.session = storage.load()
    }

    /// Atajo para previews y pruebas: sesión en memoria y servicio de prueba, sin internet ni Llavero.
    convenience init(isLoggedIn: Bool = false, currentUser: String = "") {
        let session = isLoggedIn
            ? UserSession(sessionID: "preview-session", username: currentUser, isGuest: false)
            : nil
        self.init(authService: MockAuthService(), storage: InMemorySessionStorage(session: session))
    }

    var isLoggedIn: Bool {
        session != nil
    }

    var currentUser: String {
        session?.username ?? ""
    }

    var isGuest: Bool {
        session?.isGuest ?? false
    }

    /// Inicia sesión con una cuenta de TMDB. Lanza el error de TMDB si las credenciales no son válidas.
    func login(username: String, password: String) async throws {
        let newSession = try await authService.login(username: username, password: password)
        start(newSession)
    }

    /// Entra como invitado (sesión de invitado de TMDB)
    func loginAsGuest() async throws {
        let newSession = try await authService.loginAsGuest()
        start(newSession)
    }

    /// Cierra la sesión: la app la olvida de inmediato y avisa a TMDB en segundo plano
    func logout() {
        guard let session else { return }
        self.session = nil
        storage.clear()

        let authService = self.authService
        Task {
            await authService.logout(session)
        }
    }

    private func start(_ newSession: UserSession) {
        storage.save(newSession)
        session = newSession
    }
}
