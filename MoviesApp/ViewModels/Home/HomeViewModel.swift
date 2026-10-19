import Foundation
import Observation

@Observable
final class HomeViewModel {
    private let authStore: AuthStore
    private let favoritesStore: FavoritesStore
    private let service: MovieServiceProtocol

    let sections: [MovieSection]
    var searchText: String = ""
    var showLogoutAlert: Bool = false

    init(authStore: AuthStore, favoritesStore: FavoritesStore, service: MovieServiceProtocol) {
        self.authStore = authStore
        self.favoritesStore = favoritesStore
        self.service = service

        sections = [
            MovieSection(title: "Popular this week", movies: service.popularMovies()),
            MovieSection(title: "Action", movies: service.movies(forGenre: "Action")),
            MovieSection(title: "Drama", movies: service.movies(forGenre: "Drama"))
        ]
    }

    // MARK: - Búsqueda

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var searchResults: [Movie] {
        service.searchMovies(matching: searchText)
    }

    // MARK: - Datos para la barra superior

    var hasFavorites: Bool {
        !favoritesStore.favorites.isEmpty
    }

    var currentUser: String {
        authStore.currentUser
    }

    // MARK: - Sesión

    func requestLogout() {
        showLogoutAlert = true
    }

    func logout() {
        authStore.logout()
    }

    // MARK: - ViewModels de las pantallas a las que navega el Home

    func makeMovieDetailViewModel(for movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(movie: movie, favoritesStore: favoritesStore)
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favoritesStore: favoritesStore)
    }
}
