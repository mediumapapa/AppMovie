import Foundation
import SwiftData

// Lista personalizada guardada en el teléfono con SwiftData (por ejemplo "Clásicos de domingo").
// Al borrar la lista se borran también sus películas (deleteRule: .cascade).
@Model
final class MovieList {
    @Attribute(.unique) var listID: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MovieListEntry.list)
    var entries: [MovieListEntry] = []

    init(name: String, createdAt: Date = .now) {
        self.listID = UUID()
        self.name = name
        self.createdAt = createdAt
    }

    // Convierte el registro guardado en la CustomList que usan las vistas.
    // Las películas salen en el orden en que se agregaron.
    var customList: CustomList {
        let items = entries
            .sorted { $0.addedAt < $1.addedAt }
            .map { ListItem(movie: $0.movie, note: $0.note) }
        return CustomList(id: listID, name: name, items: items)
    }
}

// Película dentro de una lista, con la nota o sinopsis personal que escribió el usuario.
// Se guardan los datos mínimos de la película para mostrarla sin internet, igual que en FavoriteMovie.
@Model
final class MovieListEntry {
    var movieID: Int
    var title: String
    var overview: String
    var posterPath: String
    var note: String
    var addedAt: Date
    var list: MovieList?

    init(movie: Movie, note: String, addedAt: Date = .now) {
        self.movieID = movie.id
        self.title = movie.title
        self.overview = movie.overview
        self.posterPath = movie.posterPath
        self.note = note
        self.addedAt = addedAt
    }

    var movie: Movie {
        Movie(id: movieID, title: title, overview: overview, posterPath: posterPath)
    }
}

// Lo que ven las vistas: una lista con sus películas, sin SwiftData de por medio
struct CustomList: Identifiable, Equatable {
    let id: UUID
    let name: String
    let items: [ListItem]
}

struct ListItem: Identifiable, Equatable {
    let movie: Movie
    let note: String

    var id: Int { movie.id }
}
