//
//  HomeSearchTests.swift
//  MoviesAppTests
//
//  Pruebas del buscador del Home (HomeViewModel + MockMovieService).
//  El buscador consulta GET /search/movie de TMDB; aquí el mock hace ese papel y busca el texto
//  en el título y la sinopsis de las películas de muestra, así el resultado siempre es el mismo.
//

import XCTest
@testable import movies_app

@MainActor
final class HomeSearchTests: XCTestCase {

    private func makeViewModel(service: MockMovieService = MockMovieService()) -> HomeViewModel {
        HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            movieService: service,
            favoritesService: MockFavoritesService(),
            listsService: MockListsService()
        )
    }

    // MARK: - Caso normal

    // La búsqueda va a TMDB aunque el Home no haya cargado sus secciones
    func testSearchAsksTMDBWithoutLoadingHome() async {
        let service = MockMovieService()
        let viewModel = makeViewModel(service: service)

        viewModel.searchText = "INTERSTELLAR"
        await viewModel.search()

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(service.searchedQueries, ["INTERSTELLAR"])
        XCTAssertEqual(viewModel.searchState, .results([Movie.sampleMovies[1]], canLoadMore: false))
    }

    // MARK: - Casos límite

    // Los espacios alrededor no se mandan a TMDB
    func testSearchIgnoresSpacesAroundText() async {
        let service = MockMovieService()
        let viewModel = makeViewModel(service: service)

        viewModel.searchText = "   arrival  "
        await viewModel.search()

        XCTAssertEqual(service.searchedQueries, ["arrival"])
        guard case .results(let movies, _) = viewModel.searchState else {
            return XCTFail("Debería haber resultados")
        }
        XCTAssertEqual(movies.map { $0.id }, [329865])
    }

    // Solo espacios no es una búsqueda: no se consulta a TMDB
    func testOnlySpacesIsNotASearch() async {
        let service = MockMovieService()
        let viewModel = makeViewModel(service: service)

        viewModel.searchText = "     "
        await viewModel.search()

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchState, .idle)
        XCTAssertTrue(service.searchedQueries.isEmpty)
    }

    // MARK: - Paginación

    // "Cargar más resultados" pide la página 2 y la agrega sin repetir películas
    func testLoadMoreResultsAppendsNextPage() async {
        let darkKnight = Movie.sampleMovies[5]
        let batman = Movie.sampleMovies[7]
        let service = MockMovieService(pages: [1: [darkKnight], 2: [batman, darkKnight]], totalPages: 2)
        let viewModel = makeViewModel(service: service)
        viewModel.searchText = "Batman"
        await viewModel.search()
        XCTAssertEqual(viewModel.searchState, .results([darkKnight], canLoadMore: true))

        await viewModel.loadMoreSearchResults()

        XCTAssertEqual(viewModel.searchState, .results([darkKnight, batman], canLoadMore: false))
        XCTAssertEqual(service.requestedPages, [1, 2])
    }

    // MARK: - Sin resultados y errores

    func testSearchWithoutMatchesShowsEmpty() async {
        let viewModel = makeViewModel()

        viewModel.searchText = "Titanic"
        await viewModel.search()

        XCTAssertEqual(viewModel.searchState, .empty)
    }

    func testSearchErrorShowsMessage() async {
        let viewModel = makeViewModel(service: MockMovieService(errorToThrow: .noConnection))

        viewModel.searchText = "Dune"
        await viewModel.search()

        XCTAssertEqual(viewModel.searchState, .error("No se pudo conectar con TMDB. Revisa tu conexión a internet."))
    }

    // Al borrar el texto se regresa al Home
    func testClearingTextGoesBackToIdle() async {
        let viewModel = makeViewModel()
        viewModel.searchText = "Dune"
        await viewModel.search()

        viewModel.searchText = ""
        await viewModel.search()

        XCTAssertEqual(viewModel.searchState, .idle)
    }

    // MARK: - Regresar del detalle

    // Al regresar del detalle la vista vuelve a llamar search() con el mismo texto:
    // no debe volver a consultar ni perder las páginas que ya se cargaron
    func testReturningFromDetailKeepsLoadedResults() async {
        let darkKnight = Movie.sampleMovies[5]
        let batman = Movie.sampleMovies[7]
        let service = MockMovieService(pages: [1: [darkKnight], 2: [batman]], totalPages: 2)
        let viewModel = makeViewModel(service: service)
        viewModel.searchText = "Batman"
        await viewModel.search()
        await viewModel.loadMoreSearchResults()

        await viewModel.search()

        XCTAssertEqual(viewModel.searchState, .results([darkKnight, batman], canLoadMore: false))
        XCTAssertEqual(service.requestedPages, [1, 2])
    }

    // "Reintentar" y la tecla Buscar sí vuelven a consultar aunque el texto sea el mismo
    func testForcedSearchAsksTMDBAgain() async {
        let service = MockMovieService()
        let viewModel = makeViewModel(service: service)
        viewModel.searchText = "Dune"
        await viewModel.search()

        await viewModel.search(force: true)

        XCTAssertEqual(service.searchedQueries, ["Dune", "Dune"])
    }

    // Si el usuario busca otra cosa mientras llega la página 2 de la búsqueda anterior,
    // esa página vieja no se mezcla con los resultados nuevos
    func testOldLoadMoreResponseIsIgnoredAfterNewSearch() async throws {
        let service = ControlledSearchService()
        let controlledViewModel = HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            movieService: service,
            favoritesService: MockFavoritesService(),
            listsService: MockListsService()
        )
        controlledViewModel.searchText = "batman"
        await controlledViewModel.search()

        // Se pide la página 2 de "batman", pero TMDB todavía no responde
        let loadMore = Task { await controlledViewModel.loadMoreSearchResults() }
        for _ in 0..<1000 where !service.hasPendingPage {
            await Task.yield()
        }
        XCTAssertTrue(service.hasPendingPage)

        // Mientras tanto el usuario busca "dune"
        controlledViewModel.searchText = "dune"
        await controlledViewModel.search()
        let duneResults = controlledViewModel.searchState

        // Llega tarde la página 2 de "batman"
        service.resumePendingPage(with: [Movie.sampleMovies[7]])
        await loadMore.value

        XCTAssertEqual(controlledViewModel.searchState, duneResults)
    }
}

// Servicio de búsqueda que deja la página 2 esperando hasta que la prueba decida responder
private final class ControlledSearchService: MovieServiceProtocol {
    private let lock = NSLock()
    private var pending: CheckedContinuation<MoviePage, Error>?

    var hasPendingPage: Bool {
        lock.lock(); defer { lock.unlock() }
        return pending != nil
    }

    func resumePendingPage(with movies: [Movie]) {
        lock.lock()
        let continuation = pending
        pending = nil
        lock.unlock()
        continuation?.resume(returning: MoviePage(movies: movies, page: 2, totalPages: 2))
    }

    func popularMovies(page: Int) async throws -> MoviePage {
        MoviePage(movies: [], page: page, totalPages: 1)
    }

    func movies(forGenreID genreID: Int, page: Int) async throws -> MoviePage {
        MoviePage(movies: [], page: page, totalPages: 1)
    }

    func searchMovies(query: String, page: Int) async throws -> MoviePage {
        if page == 2 {
            return try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                pending = continuation
                lock.unlock()
            }
        }
        let movie = query == "dune" ? Movie.sampleMovies[0] : Movie.sampleMovies[5]
        return MoviePage(movies: [movie], page: 1, totalPages: 2)
    }
}
