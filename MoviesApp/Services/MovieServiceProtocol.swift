import Foundation

// Contrato para obtener películas.
// En la app lo cumple MovieService (TMDB, Production) y en los previews y pruebas MockMovieService (Mock).
// Las funciones son async porque las películas llegan de internet, y throws porque la consulta puede fallar.
// Todas reciben la página que se quiere (empieza en 1) para poder cargar más resultados.
protocol MovieServiceProtocol {
    func popularMovies(page: Int) async throws -> MoviePage
    func movies(forGenreID genreID: Int, page: Int) async throws -> MoviePage
    func searchMovies(query: String, page: Int) async throws -> MoviePage
}
