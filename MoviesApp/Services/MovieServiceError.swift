import Foundation

// Errores que puede lanzar MovieService al consultar TMDB.
// errorDescription es el mensaje que el Home le muestra al usuario.
enum MovieServiceError: LocalizedError {
    case invalidURL          // No se pudo armar la URL
    case noConnection        // No hubo internet o la solicitud no llegó
    case invalidResponse     // La respuesta no fue HTTP
    case badStatus(Int)      // TMDB respondió con un código que no es 200...299
    case decodingFailed      // El JSON no tenía la forma esperada

    var errorDescription: String? {
        switch self {
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
            return "No se pudieron leer las películas que mandó TMDB."
        }
    }
}
