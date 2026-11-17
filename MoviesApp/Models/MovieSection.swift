import Foundation

// De dónde salen las películas de una sección del Home
enum SectionKind: Hashable {
    case popular          // GET /trending/movie/week
    case genre(Int)       // GET /discover/movie?with_genres=<id>
}

// Sección del Home (por ejemplo "Populares de la semana" o un género).
// Guarda la última página que se pidió a TMDB para poder cargar más películas al final del carrusel.
// Equatable permite comparar el estado del Home en las pruebas.
struct MovieSection: Identifiable, Equatable {
    let title: String
    var movies: [Movie]
    var kind: SectionKind = .popular
    var page: Int = 1
    var totalPages: Int = 1

    var id: String { title }

    var canLoadMore: Bool {
        page < totalPages
    }
}
