import Foundation

// Pide las películas a la API de TMDB.
// Las vistas y los ViewModels no saben nada de URLs, tokens ni JSON:
// solo reciben un MoviePage o un MovieServiceError. El trabajo de HTTP lo hace TMDBClient.
struct MovieService: MovieServiceProtocol {

    private let client: TMDBClient

    init(client: TMDBClient = TMDBClient()) {
        self.client = client
    }

    // GET /trending/movie/week → sección "Populares de la semana" del Home
    func popularMovies(page: Int) async throws -> MoviePage {
        try await fetch("/trending/movie/week", page: page)
    }

    // GET /discover/movie?with_genres=28 → secciones por género del Home (28 = Acción, 18 = Drama)
    func movies(forGenreID genreID: Int, page: Int) async throws -> MoviePage {
        try await fetch("/discover/movie", page: page, extra: [
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false")
        ])
    }

    // GET /search/movie?query=... → buscador del Home. Busca en todo el catálogo de TMDB.
    func searchMovies(query: String, page: Int) async throws -> MoviePage {
        try await fetch("/search/movie", page: page, extra: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "include_adult", value: "false")
        ])
    }

    private func fetch(_ path: String, page: Int, extra: [URLQueryItem] = []) async throws -> MoviePage {
        let query = extra + [URLQueryItem(name: "page", value: String(page))]
        let list: TMDBMovieList = try await client.get(path, query: query)
        return list.moviePage
    }
}
