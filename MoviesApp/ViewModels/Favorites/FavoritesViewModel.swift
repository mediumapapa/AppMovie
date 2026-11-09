import Foundation
import Observation

@Observable
final class FavoritesViewModel {
    private let favoritesService: FavoritesServiceProtocol

    private(set) var favorites: [Movie] = []

    init(favoritesService: FavoritesServiceProtocol) {
        self.favoritesService = favoritesService
    }

    var isEmpty: Bool {
        favorites.isEmpty
    }

    // Lee los favoritos guardados. La vista lo llama al aparecer, también al regresar del detalle
    // por si ahí se quitó alguno. No se llama en el init porque el Home crea este ViewModel cada vez que se redibuja.
    func loadFavorites() {
        favorites = favoritesService.fetchFavorites()
    }

    func remove(_ movie: Movie) {
        favoritesService.remove(movieID: movie.id)
        loadFavorites()
    }
}
