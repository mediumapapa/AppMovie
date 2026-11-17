import Foundation

// Una página de resultados de TMDB. TMDB regresa 20 películas por página;
// con page y totalPages se sabe si todavía hay más para pedir.
struct MoviePage: Equatable {
    let movies: [Movie]
    let page: Int
    let totalPages: Int

    var hasMore: Bool {
        page < totalPages
    }
}
