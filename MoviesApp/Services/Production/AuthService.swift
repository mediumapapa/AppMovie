import Foundation

// Inicia sesión en TMDB con el flujo oficial de la API v3:
// 1. GET  /authentication/token/new                → token de solicitud temporal
// 2. POST /authentication/token/validate_with_login → TMDB revisa usuario y contraseña y aprueba el token
// 3. POST /authentication/session/new              → con el token aprobado se obtiene el session_id
// La contraseña solo viaja a TMDB por HTTPS; la app nunca la guarda.
struct AuthService: AuthServiceProtocol {

    private let client: TMDBClient

    init(client: TMDBClient = TMDBClient()) {
        self.client = client
    }

    func login(username: String, password: String) async throws -> UserSession {
        let newToken: TMDBRequestToken = try await client.get("/authentication/token/new")

        let validatedToken: TMDBRequestToken = try await client.send(
            method: "POST",
            path: "/authentication/token/validate_with_login",
            body: [
                "username": username,
                "password": password,
                "request_token": newToken.requestToken
            ]
        )

        let session: TMDBSessionResponse = try await client.send(
            method: "POST",
            path: "/authentication/session/new",
            body: ["request_token": validatedToken.requestToken]
        )

        return UserSession(sessionID: session.sessionID, username: username, isGuest: false)
    }

    // GET /authentication/guest_session/new
    func loginAsGuest() async throws -> UserSession {
        let guest: TMDBGuestSessionResponse = try await client.get("/authentication/guest_session/new")
        return UserSession(sessionID: guest.guestSessionID, username: "Invitado", isGuest: true)
    }

    // DELETE /authentication/session. Las sesiones de invitado no se pueden borrar en TMDB; vencen solas.
    func logout(_ session: UserSession) async {
        guard !session.isGuest else { return }
        let _: TMDBSuccessResponse? = try? await client.send(
            method: "DELETE",
            path: "/authentication/session",
            body: ["session_id": session.sessionID]
        )
    }
}
