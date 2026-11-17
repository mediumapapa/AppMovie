import Foundation

// Contrato para iniciar y cerrar sesión.
// En la app lo cumple AuthService (TMDB, Production) y en los previews y pruebas MockAuthService (Mock).
protocol AuthServiceProtocol {
    // Inicia sesión con el usuario y la contraseña de una cuenta de TMDB
    func login(username: String, password: String) async throws -> UserSession
    // Abre una sesión de invitado, para quien no tiene cuenta de TMDB
    func loginAsGuest() async throws -> UserSession
    // Cierra la sesión en TMDB. Si falla no importa: la app la olvida de todos modos.
    func logout(_ session: UserSession) async
}

// Dónde se guarda la sesión entre aperturas de la app.
// En la app es el Llavero (KeychainSessionStorage); en pruebas y previews, la memoria (InMemorySessionStorage).
protocol SessionStorageProtocol {
    func load() -> UserSession?
    func save(_ session: UserSession)
    func clear()
}
