import Foundation
import SwiftData

// Película guardada en favoritos. Es lo único que la app guarda en el teléfono con SwiftData.
//
// movieID es el id de la película en TMDB. Con él se reconoce la misma película aunque sus datos
// vuelvan a llegar de la API, y @Attribute(.unique) impide que la base tenga dos registros con el mismo id.
// Del resto solo se guarda lo que necesita la tarjeta de Favoritos para mostrarse sin internet.
@Model
final class FavoriteMovie {
    @Attribute(.unique) var movieID: Int
    var title: String
    var overview: String
    var posterPath: String
    var addedAt: Date

    init(movie: Movie, addedAt: Date = .now) {
        self.movieID = movie.id
        self.title = movie.title
        self.overview = movie.overview
        self.posterPath = movie.posterPath
        self.addedAt = addedAt
    }

    // Convierte el registro guardado en el Movie que usan las vistas
    var movie: Movie {
        Movie(id: movieID, title: title, overview: overview, posterPath: posterPath)
    }
}
