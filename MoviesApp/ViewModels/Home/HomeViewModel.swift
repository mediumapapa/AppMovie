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
    private let listsService: ListsServiceProtocol

    // Secciones del Home, en el orden en que aparecen
    static let sectionDefinitions: [(title: String, kind: SectionKind)] = [
        ("Populares de la semana", .popular),
        ("Acción", .genre(28)),   // 28 = Action en TMDB
        ("Drama", .genre(18))     // 18 = Drama en TMDB
    ]

    // Estado de la consulta a TMDB. La vista lo lee para decidir qué mostrar.
    private(set) var state: HomeState = .loading
    // Secciones que están pidiendo su siguiente página (para mostrar el indicador en esa tarjeta).
    // Es un conjunto para que cada sección pueda cargar más sin bloquear a las otras.
    private(set) var loadingMoreSectionIDs: Set<String> = []
    // Error al cargar más películas de una sección; no borra lo que ya se ve
    var loadMoreErrorMessage: String?

    var searchText: String = ""
    private(set) var searchState: SearchState = .idle
    private(set) var isLoadingMoreResults = false
    private var searchedQuery = ""
    private var searchPage = 1

    var showLogoutAlert: Bool = false
    private(set) var hasFavorites: Bool = false

    init(
        authStore: AuthStore,
        movieService: MovieServiceProtocol,
        favoritesService: FavoritesServiceProtocol,
        listsService: ListsServiceProtocol
    ) {
        self.authStore = authStore
        self.movieService = movieService
        self.favoritesService = favoritesService
        self.listsService = listsService
    }

    // MARK: - Películas de TMDB

    // Pide las tres secciones del Home al mismo tiempo (async let) y espera a que lleguen todas.
    // Si cualquiera falla se muestra el error con su mensaje; no se esconde.
    // También la usa el botón "Reintentar".
    func loadMovies() async {
        state = .loading

        do {
            async let popular = fetchPage(for: .popular, page: 1)
            async let action = fetchPage(for: Self.sectionDefinitions[1].kind, page: 1)
            async let drama = fetchPage(for: Self.sectionDefinitions[2].kind, page: 1)
            let pages = try await [popular, action, drama]

            // Solo se muestran las secciones que trajeron películas
            let sections = zip(Self.sectionDefinitions, pages).map { definition, page in
                MovieSection(
                    title: definition.title,
                    movies: Self.removingDuplicates(page.movies),
                    kind: definition.kind,
                    page: page.page,
                    totalPages: page.totalPages
                )
            }.filter { !$0.movies.isEmpty }

            state = sections.isEmpty ? .empty : .content(sections)
        } catch is CancellationError {
            // La vista desapareció antes de que llegara la respuesta; al volver se pide otra vez
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

    // Botón "Ver más" al final de cada carrusel: pide la siguiente página de esa sección
    // y la agrega al final, sin repetir películas que ya estaban.
    func loadMore(in sectionID: String) async {
        guard !loadingMoreSectionIDs.contains(sectionID),
              case .content(let sections) = state,
              let index = sections.firstIndex(where: { $0.id == sectionID }),
              sections[index].canLoadMore else { return }

        loadingMoreSectionIDs.insert(sectionID)
        defer { loadingMoreSectionIDs.remove(sectionID) }

        let section = sections[index]
        do {
            let nextPage = try await fetchPage(for: section.kind, page: section.page + 1)

            // El estado pudo cambiar mientras se esperaba (por ejemplo, con "Reintentar")
            guard case .content(var current) = state,
                  let currentIndex = current.firstIndex(where: { $0.id == sectionID }) else { return }
            current[currentIndex].movies = Self.removingDuplicates(current[currentIndex].movies + nextPage.movies)
            current[currentIndex].page = nextPage.page
            current[currentIndex].totalPages = nextPage.totalPages
            state = .content(current)
        } catch is CancellationError {
            return
        } catch {
            loadMoreErrorMessage = error.localizedDescription
        }
    }

    private func fetchPage(for kind: SectionKind, page: Int) async throws -> MoviePage {
        switch kind {
        case .popular:
            return try await movieService.popularMovies(page: page)
        case .genre(let genreID):
            return try await movieService.movies(forGenreID: genreID, page: page)
        }
    }

    // TMDB a veces repite una película entre páginas; se deja solo la primera vez que aparece
    private static func removingDuplicates(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        return movies.filter { seen.insert($0.id).inserted }
    }

    // MARK: - Búsqueda en TMDB

    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

    // Busca el texto en todo el catálogo de TMDB (GET /search/movie), no solo en las películas del Home.
    // La vista la llama un momento después de que el usuario deja de escribir.
    // Si ya hay resultados para ese mismo texto (por ejemplo, al regresar del detalle) no vuelve a consultar,
    // así se conservan las páginas que ya se cargaron. force: true la usan "Reintentar" y la tecla Buscar.
    func search(force: Bool = false) async {
        let query = trimmedSearchText
        guard !query.isEmpty else {
            searchState = .idle
            searchedQuery = ""
            return
        }

        if !force, query == searchedQuery {
            switch searchState {
            case .results, .empty:
                return
            case .idle, .loading, .error:
                break
            }
        }

        searchState = .loading
        do {
            let page = try await movieService.searchMovies(query: query, page: 1)
            // Si el usuario cambió el texto mientras se esperaba, esta respuesta ya no sirve
            guard query == trimmedSearchText else { return }

            searchedQuery = query
            searchPage = page.page
            let movies = Self.removingDuplicates(page.movies)
            searchState = movies.isEmpty ? .empty : .results(movies, canLoadMore: page.hasMore)
        } catch is CancellationError {
            return
        } catch {
            guard query == trimmedSearchText else { return }
            searchState = .error(error.localizedDescription)
        }
    }

    // Botón "Cargar más resultados" al final de la búsqueda
    func loadMoreSearchResults() async {
        guard !isLoadingMoreResults,
              case .results(_, true) = searchState,
              searchedQuery == trimmedSearchText else { return }

        // Se guarda qué búsqueda pidió esta página: si mientras se espera el usuario busca otra cosa,
        // la respuesta vieja no debe mezclarse con los resultados nuevos
        let query = searchedQuery
        let nextPage = searchPage + 1
        isLoadingMoreResults = true
        defer { isLoadingMoreResults = false }

        do {
            let page = try await movieService.searchMovies(query: query, page: nextPage)
            guard query == searchedQuery,
                  query == trimmedSearchText,
                  case .results(let latest, _) = searchState else { return }

            searchPage = page.page
            searchState = .results(Self.removingDuplicates(latest + page.movies), canLoadMore: page.hasMore)
        } catch is CancellationError {
            return
        } catch {
            loadMoreErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Datos para la barra superior

    var currentUser: String {
        authStore.currentUser
    }

    var isGuest: Bool {
        authStore.isGuest
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
        MovieDetailViewModel(movie: movie, favoritesService: favoritesService, listsService: listsService)
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favoritesService: favoritesService)
    }

    func makeListsViewModel() -> ListsViewModel {
        ListsViewModel(listsService: listsService)
    }
}
