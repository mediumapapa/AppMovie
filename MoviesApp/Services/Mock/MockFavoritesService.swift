import Foundation

// Favoritos de prueba para los #Preview y para las pruebas que no revisan favoritos.
// Los guarda en un arreglo, sin SwiftData, igual que MockMovieService regresa películas locales.
final class MockFavoritesService: FavoritesServiceProtocol {

    private var favorites: [Movie]

    init(favorites: [Movie] = []) {
        self.favorites = favorites
    }

    func fetchFavorites() -> [Movie] {
        favorites
    }

    func isSaved(movieID: Int) -> Bool {
        favorites.contains { $0.id == movieID }
    }

    func add(_ movie: Movie) {
        guard !isSaved(movieID: movie.id) else { return }
        favorites.append(movie)
    }

    func remove(movieID: Int) {
        favorites.removeAll { $0.id == movieID }
    }
}
