import Foundation

// Forma del JSON que regresa TMDB en las listas de películas (/trending y /discover):
// { "page": 1, "results": [ { "id": 155, "title": "...", "overview": "...", "poster_path": "/...jpg" } ] }
// Solo se declaran los campos que usa la app; JSONDecoder ignora los demás.
struct TMDBMovieList: Decodable {
    let results: [TMDBMovie]
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
