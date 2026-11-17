import Foundation

// Respuestas JSON de los endpoints de autenticación de TMDB.
// https://developer.themoviedb.org/reference/authentication-how-do-i-generate-a-session-id

// GET /authentication/token/new y POST /authentication/token/validate_with_login
// { "success": true, "expires_at": "...", "request_token": "..." }
struct TMDBRequestToken: Decodable {
    let requestToken: String

    enum CodingKeys: String, CodingKey {
        case requestToken = "request_token"
    }
}

// POST /authentication/session/new → { "success": true, "session_id": "..." }
struct TMDBSessionResponse: Decodable {
    let sessionID: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
    }
}

// GET /authentication/guest_session/new → { "success": true, "guest_session_id": "...", "expires_at": "..." }
struct TMDBGuestSessionResponse: Decodable {
    let guestSessionID: String

    enum CodingKeys: String, CodingKey {
        case guestSessionID = "guest_session_id"
    }
}

// DELETE /authentication/session → { "success": true }
struct TMDBSuccessResponse: Decodable {
    let success: Bool
}
