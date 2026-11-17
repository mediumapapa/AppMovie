import Foundation

// Forma del JSON que regresa TMDB en las listas de películas (/trending, /discover y /search):
// { "page": 1, "results": [ { "id": 155, "title": "...", "overview": "...", "poster_path": "/...jpg" } ], "total_pages": 30 }
// Solo se declaran los campos que usa la app; JSONDecoder ignora los demás.
struct TMDBMovieList: Decodable {
    let page: Int?
    let results: [TMDBMovie]
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
    }

    // TMDB no deja pedir más allá de la página 500 aunque total_pages diga más
    var moviePage: MoviePage {
        let currentPage = page ?? 1
        let lastPage = min(totalPages ?? currentPage, 500)
        return MoviePage(movies: results.map { $0.movie }, page: currentPage, totalPages: lastPage)
    }
}

struct TMDBMovie: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String? // Viene en null si la película no tiene póster

    // En el JSON el póster se llama poster_path
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
    }

    // Convierte la película de TMDB en el Movie que usan las vistas
    var movie: Movie {
        Movie(id: id, title: title, overview: overview, posterPath: posterPath ?? "")
    }
}
