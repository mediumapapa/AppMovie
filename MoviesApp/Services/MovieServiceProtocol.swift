import Foundation

// Contrato para obtener películas.
// Hoy lo cumple MockMovieService; cuando se conecte TMDB se agrega un servicio real
// sin tener que cambiar los ViewModels.
protocol MovieServiceProtocol {
    func popularMovies() -> [Movie]
    func movies(forGenre genre: String) -> [Movie]
    func searchMovies(matching query: String) -> [Movie]
}
