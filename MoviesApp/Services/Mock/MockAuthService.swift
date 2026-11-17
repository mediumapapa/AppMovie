import Foundation

// Inicio de sesión de prueba para los #Preview y las pruebas: no usa internet.
// Acepta un usuario y contraseña fijos, o lanza el error que se le configure.
final class MockAuthService: AuthServiceProtocol {

    var validUsername: String
    var validPassword: String
    // Si no es nil, login y loginAsGuest lanzan este error
    var errorToThrow: MovieServiceError?

    private(set) var loggedOutSessions: [UserSession] = []

    init(validUsername: String = "demo", validPassword: String = "1234", errorToThrow: MovieServiceError? = nil) {
        self.validUsername = validUsername
        self.validPassword = validPassword
        self.errorToThrow = errorToThrow
    }

    func login(username: String, password: String) async throws -> UserSession {
        if let errorToThrow { throw errorToThrow }
        guard username == validUsername, password == validPassword else {
            throw MovieServiceError.invalidCredentials
        }
        return UserSession(sessionID: "session-\(username)", username: username, isGuest: false)
    }

    func loginAsGuest() async throws -> UserSession {
        if let errorToThrow { throw errorToThrow }
        return UserSession(sessionID: "guest-session", username: "Invitado", isGuest: true)
    }

    func logout(_ session: UserSession) async {
        loggedOutSessions.append(session)
    }
}

// Guarda la sesión solo en memoria: se pierde al cerrar la app. Para previews y pruebas.
final class InMemorySessionStorage: SessionStorageProtocol {

    private(set) var session: UserSession?

    init(session: UserSession? = nil) {
        self.session = session
    }

    func load() -> UserSession? {
        session
    }

    func save(_ session: UserSession) {
        self.session = session
    }

    func clear() {
        session = nil
    }
}
