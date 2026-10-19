import Foundation
import Observation

@Observable
final class MovieDetailViewModel {
    private let favoritesStore: FavoritesStore

    let movie: Movie

    init(movie: Movie, favoritesStore: FavoritesStore) {
        self.movie = movie
        self.favoritesStore = favoritesStore
    }

    var isFavorite: Bool {
        favoritesStore.isFavorite(movie)
    }

    var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }

    var favoriteTitle: String {
        isFavorite ? "In Favorites" : "Add Favorite"
    }

    func toggleFavorite() {
        favoritesStore.toggle(movie)
    }
}
