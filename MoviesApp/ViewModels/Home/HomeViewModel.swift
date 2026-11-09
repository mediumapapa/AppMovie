import Foundation
import Observation

// @MainActor: el estado se actualiza siempre en el hilo principal, que es el que dibuja la pantalla.
// Mientras se espera a TMDB (await) el hilo principal queda libre, así la interfaz no se bloquea.
@MainActor
@Observable
final class HomeViewModel {
    private let authStore: AuthStore
    private let movieService: MovieServiceProtocol
    private let favoritesService: FavoritesServiceProtocol

    // Estado de la consulta a TMDB. La vista lo lee para decidir qué mostrar.
    private(set) var state: HomeState = .loading
    var searchText: String = ""
    var showLogoutAlert: Bool = false
    private(set) var hasFavorites: Bool = false

    init(authStore: AuthStore, movieService: MovieServiceProtocol, favoritesService: FavoritesServiceProtocol) {
        self.authStore = authStore
        self.movieService = movieService
        self.favoritesService = favoritesService
    }

    // MARK: - Películas de TMDB

    // Pide las tres secciones del Home, una después de otra.
    // Si cualquiera falla se muestra el error con su mensaje; no se esconde.
    // También la usa el botón "Reintentar".
    func loadMovies() async {
        state = .loading

        do {
            let popular = try await movieService.popularMovies()
            let action = try await movieService.movies(forGenreID: 28) // 28 = Action en TMDB
            let drama = try await movieService.movies(forGenreID: 18)  // 18 = Drama en TMDB

            // Solo se muestran las secciones que trajeron películas
            let sections = [
                MovieSection(title: "Popular this week", movies: popular),
                MovieSection(title: "Action", movies: action),
                MovieSection(title: "Drama", movies: drama)
            ].filter { !$0.movies.isEmpty }

            state = sections.isEmpty ? .empty : .content(sections)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // La vista lo llama cada vez que aparece. Al regresar del detalle o de Favoritos
    // el Home vuelve a aparecer; si ya tiene películas no las pide otra vez.
    func loadMoviesIfNeeded() async {
        if case .content = state {
            return
        }
        await loadMovies()
    }

    // MARK: - Búsqueda

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Busca por título o sinopsis entre las películas que ya llegaron de TMDB.
    // Una película puede venir en dos secciones (por ejemplo en Popular y en Action); se agrega una sola vez.
    var searchResults: [Movie] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, case .content(let sections) = state else { return [] }

        var results: [Movie] = []
        for section in sections {
            for movie in section.movies {
                let matches = movie.title.localizedCaseInsensitiveContains(text) ||
                    movie.overview.localizedCaseInsensitiveContains(text)
                let alreadyAdded = results.contains { $0.id == movie.id }

                if matches && !alreadyAdded {
                    results.append(movie)
                }
            }
        }
        return results
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
