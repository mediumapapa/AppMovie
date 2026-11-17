import Foundation

// Hace las solicitudes HTTP a TMDB. Lo comparten MovieService (películas) y AuthService (inicio de sesión).
// Arma la URL, agrega el token, manda la solicitud, revisa el código HTTP y decodifica el JSON.
// Los demás servicios solo dicen qué endpoint quieren y qué tipo esperan de regreso.
struct TMDBClient {

    static let baseURL = "https://api.themoviedb.org/3"

    // Texto que trae APIKeys.swift.example. Si sigue ahí, el token no se ha configurado.
    static let placeholderToken = "PEGA_AQUI_TU_TOKEN"

    private let session: URLSession
    private let token: String

    // En la app se usa URLSession.shared y el token de APIKeys.swift.
    // Las pruebas pasan una URLSession falsa y un token de prueba.
    init(session: URLSession = .shared, token: String = APIKeys.tmdbReadAccessToken) {
        self.session = session
        self.token = token
    }

    // GET con parámetros en la URL
    func get<Response: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        try await send(method: "GET", path: path, query: query, body: nil)
    }

    // POST o DELETE con un cuerpo JSON sencillo (TMDB solo pide textos en el inicio de sesión)
    func send<Response: Decodable>(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        body: [String: String]?
    ) async throws -> Response {
        // 0. Sin token no tiene caso salir a internet: TMDB respondería 401
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty, trimmedToken != Self.placeholderToken else {
            throw MovieServiceError.missingToken
        }

        // 1. Armar la URL con sus parámetros (títulos y sinopsis en español de México)
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw MovieServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "language", value: "es-MX")] + query
        guard let url = components.url else {
            throw MovieServiceError.invalidURL
        }

        // 2. Armar la solicitud. El token va en el encabezado Authorization, nunca en la URL.
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }

        // 3. Mandar la solicitud. await espera la respuesta sin bloquear la pantalla.
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Si la consulta se canceló (por ejemplo, el usuario siguió escribiendo en el buscador)
            // no es un error de conexión: se avisa como cancelación para que nadie muestre un mensaje.
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                throw CancellationError()
            }
            throw MovieServiceError.noConnection
        }

        // 4. Validar la respuesta HTTP: solo los códigos 200...299 son éxito
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MovieServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.error(forStatus: httpResponse.statusCode, data: data)
        }

        // 5. Decodificar el JSON
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw MovieServiceError.decodingFailed
        }
    }

    // Cuando falla, TMDB manda { "status_code": 30, "status_message": "..." }.
    // Con ese código se distingue un usuario o contraseña incorrectos de un token inválido.
    // https://developer.themoviedb.org/docs/errors
    private static func error(forStatus httpStatus: Int, data: Data) -> MovieServiceError {
        let tmdbStatus = try? JSONDecoder().decode(TMDBStatus.self, from: data)
        switch tmdbStatus?.statusCode {
        case 30:
            return .invalidCredentials
        case 32:
            return .emailNotVerified
        // 3: autenticación fallida, 17: sesión denegada, 33: token de solicitud vencido o inválido.
        // Son fallas del inicio de sesión, no del token de APIKeys.swift.
        case 3, 17, 33:
            return .loginFailed
        default:
            return .badStatus(httpStatus)
        }
    }
}

// Cuerpo de error de TMDB
struct TMDBStatus: Decodable {
    let statusCode: Int
    let statusMessage: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
