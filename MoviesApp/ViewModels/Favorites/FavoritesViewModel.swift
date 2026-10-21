import Foundation
import Observation

@Observable
final class FavoritesViewModel {
    private let favoritesStore: FavoritesStore

    init(favoritesStore: FavoritesStore) {
        self.favoritesStore = favoritesStore
    }

    var favorites: [Movie] {
        favoritesStore.favorites
    }

    var isEmpty: Bool {
        favorites.isEmpty
    }

    func remove(_ movie: Movie) {
        favoritesStore.remove(movie)
    }
}
