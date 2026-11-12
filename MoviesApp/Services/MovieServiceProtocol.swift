import Foundation

// Contrato para obtener películas.
// En la app lo cumple MovieService (TMDB, Production) y en los previews y pruebas MockMovieService (Mock).
// Las funciones son async porque las películas llegan de internet, y throws porque la consulta puede fallar.
protocol MovieServiceProtocol {
    func popularMovies() async throws -> [Movie]
    func movies(forGenreID genreID: Int) async throws -> [Movie]
}
