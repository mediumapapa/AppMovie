import Foundation

// Errores que pueden lanzar MovieService y AuthService al consultar TMDB.
// errorDescription es el mensaje que la app le muestra al usuario.
enum MovieServiceError: LocalizedError, Equatable {
    case missingToken        // APIKeys.swift no tiene un token (sigue el texto de la plantilla)
    case invalidURL          // No se pudo armar la URL
    case noConnection        // No hubo internet o la solicitud no llegó
    case invalidResponse     // La respuesta no fue HTTP
    case badStatus(Int)      // TMDB respondió con un código que no es 200...299
    case decodingFailed      // El JSON no tenía la forma esperada
    case invalidCredentials  // Usuario o contraseña de TMDB incorrectos (status_code 30)
    case emailNotVerified    // La cuenta de TMDB no ha confirmado su correo (status_code 32)
    case loginFailed         // TMDB no completó el inicio de sesión (status_code 3, 17 o 33)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Falta configurar el token de TMDB. Pega tu token en MoviesApp/Utils/APIKeys.swift y vuelve a ejecutar la app."
        case .invalidURL:
            return "No se pudo armar la dirección de la consulta."
        case .noConnection:
            return "No se pudo conectar con TMDB. Revisa tu conexión a internet."
        case .invalidResponse:
            return "TMDB regresó una respuesta que no se pudo leer."
        case .badStatus(401):
            return "TMDB rechazó el token (código 401). Revisa el archivo APIKeys.swift."
        case .badStatus(let code):
            return "TMDB respondió con un error (código \(code))."
        case .decodingFailed:
            return "No se pudieron leer los datos que mandó TMDB."
        case .invalidCredentials:
            return "Usuario o contraseña de TMDB incorrectos."
        case .emailNotVerified:
            return "Tu cuenta de TMDB aún no confirma su correo. Revisa tu bandeja de entrada."
        case .loginFailed:
            return "TMDB no pudo completar el inicio de sesión. Inténtalo de nuevo en un momento."
        }
    }
}
