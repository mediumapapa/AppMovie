import Foundation

// Sesión abierta en TMDB. Se guarda en el Llavero (Keychain) del teléfono
// para que el usuario no tenga que volver a iniciar sesión cada vez que abre la app.
struct UserSession: Codable, Equatable {
    // session_id (cuenta de TMDB) o guest_session_id (invitado)
    let sessionID: String
    // Nombre de usuario de TMDB, o "Invitado"
    let username: String
    let isGuest: Bool
}
