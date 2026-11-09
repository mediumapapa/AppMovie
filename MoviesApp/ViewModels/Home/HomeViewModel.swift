import Foundation
import Observation

@Observable
final class HomeViewModel {
    private let authStore: AuthStore
    private let movieService: MovieServiceProtocol
    private let favoritesService: FavoritesServiceProtocol

    let sections: [MovieSection]
    var searchText: String = ""
    var showLogoutAlert: Bool = false
    private(set) var hasFavorites: Bool = false

    init(authStore: AuthStore, movieService: MovieServiceProtocol, favoritesService: FavoritesServiceProtocol) {
        self.authStore = authStore
        self.movieService = movieService
        self.favoritesService = favoritesService

        sections = [
            MovieSection(title: "Popular this week", movies: movieService.popularMovies()),
            MovieSection(title: "Action", movies: movieService.movies(forGenre: "Action")),
            MovieSection(title: "Drama", movies: movieService.movies(forGenre: "Drama"))
        ]
    }

    // MARK: - Búsqueda

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var searchResults: [Movie] {
        movieService.searchMovies(matching: searchText)
    }

    // MARK: - Datos para la barra superior

    var currentUser: String {
        authStore.currentUser
    }

    // Revisa si hay favoritos guardados para el punto rojo del corazón.
    // La vista lo llama al aparecer, también al regresar del detalle o de Favoritos.
    func refreshFavorites() {
        hasFavorites = !favoritesService.fetchFavorites().isEmpty
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
        MovieDetailViewModel(movie: movie, favoritesService: favoritesService)
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favoritesService: favoritesService)
    }
}
