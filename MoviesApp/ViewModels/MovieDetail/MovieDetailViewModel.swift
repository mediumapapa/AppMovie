import Foundation
import Observation

@Observable
final class MovieDetailViewModel {
    private let favoritesService: FavoritesServiceProtocol

    let movie: Movie
    private(set) var isFavorite: Bool

    init(movie: Movie, favoritesService: FavoritesServiceProtocol) {
        self.movie = movie
        self.favoritesService = favoritesService
        self.isFavorite = favoritesService.isSaved(movieID: movie.id)
    }

    var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }

    var favoriteTitle: String {
        isFavorite ? "In Favorites" : "Add Favorite"
    }

    // Si ya está guardada la quita, si no la agrega.
    // Después vuelve a preguntar al servicio para que el botón muestre lo que de verdad quedó guardado.
    func toggleFavorite() {
        if isFavorite {
            favoritesService.remove(movieID: movie.id)
        } else {
            favoritesService.add(movie)
        }
        isFavorite = favoritesService.isSaved(movieID: movie.id)
    }
}
