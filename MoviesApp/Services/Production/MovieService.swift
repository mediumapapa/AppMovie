import Foundation

// Pide las películas a la API de TMDB con URLSession.
// Las vistas y los ViewModels no saben nada de URLs, tokens ni JSON:
// solo reciben [Movie] o un MovieServiceError.
struct MovieService: MovieServiceProtocol {

    private let baseURL = "https://api.themoviedb.org/3"

    // GET /trending/movie/week → sección "Popular this week" del Home
    func popularMovies() async throws -> [Movie] {
        try await fetchMovies(path: "/trending/movie/week")
    }

    // GET /discover/movie?with_genres=28 → secciones por género del Home (28 = Action, 18 = Drama)
    func movies(forGenreID genreID: Int) async throws -> [Movie] {
        try await fetchMovies(
            path: "/discover/movie",
            queryItems: [URLQueryItem(name: "with_genres", value: String(genreID))]
        )
    }

    // Hace la consulta completa: arma la URL, manda la solicitud, revisa el código HTTP y decodifica el JSON
    private func fetchMovies(path: String, queryItems: [URLQueryItem] = []) async throws -> [Movie] {
        // 1. Armar la URL con sus parámetros (títulos y sinopsis en español de México)
        guard var components = URLComponents(string: baseURL + path) else {
            throw MovieServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "language", value: "es-MX")] + queryItems

        guard let url = components.url else {
            throw MovieServiceError.invalidURL
        }

        // 2. Armar la solicitud. El token va en el encabezado Authorization, no en la URL.
        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIKeys.tmdbReadAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 3. Mandar la solicitud. await espera la respuesta sin bloquear la pantalla.
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw MovieServiceError.noConnection
        }

        // 4. Validar la respuesta HTTP: solo los códigos 200...299 son éxito
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MovieServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MovieServiceError.badStatus(httpResponse.statusCode)
        }

        // 5. Decodificar el JSON y convertir cada película de TMDB en Movie
        do {
            let movieList = try JSONDecoder().decode(TMDBMovieList.self, from: data)
            return movieList.results.map { $0.movie }
        } catch {
            throw MovieServiceError.decodingFailed
        }
    }
}
