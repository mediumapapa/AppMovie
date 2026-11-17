//
//  HomeStateTests.swift
//  MoviesAppTests
//
//  Pruebas de los estados del Home (Loading, Content, Empty y Error) y del botón Reintentar.
//  Usan MockMovieService configurado para simular cada respuesta, sin llamar a TMDB.
//

import XCTest
@testable import movies_app

@MainActor
final class HomeStateTests: XCTestCase {

    private func makeViewModel(service: MockMovieService) -> HomeViewModel {
        HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            movieService: service,
            favoritesService: MockFavoritesService(),
            listsService: MockListsService()
        )
    }

    // Lo que debe mostrar el Home cuando el mock regresa las películas de muestra
    private var expectedContent: HomeState {
        .content([
            MovieSection(title: "Populares de la semana", movies: Movie.sampleMovies, kind: .popular),
            MovieSection(title: "Acción", movies: Movie.sampleMovies, kind: .genre(28)),
            MovieSection(title: "Drama", movies: Movie.sampleMovies, kind: .genre(18))
        ])
    }

    // MARK: - Loading

    func testStartsLoading() {
        let viewModel = makeViewModel(service: MockMovieService())

        XCTAssertEqual(viewModel.state, .loading)
    }

    // MARK: - 1. Respuesta exitosa

    func testSuccessfulResponseShowsContent() async {
        let viewModel = makeViewModel(service: MockMovieService())

        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.state, expectedContent)
    }

    // MARK: - 2. Error

    // TMDB responde con un código HTTP que no es de éxito
    func testHTTPErrorShowsError() async {
        let viewModel = makeViewModel(service: MockMovieService(errorToThrow: .badStatus(500)))

        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.state, .error("TMDB respondió con un error (código 500)."))
    }

    // La solicitud no llega (sin internet)
    func testNoConnectionShowsError() async {
        let viewModel = makeViewModel(service: MockMovieService(errorToThrow: .noConnection))

        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.state, .error("No se pudo conectar con TMDB. Revisa tu conexión a internet."))
    }

    // MARK: - 3. Sin resultados

    func testEmptyResponseShowsEmpty() async {
        let viewModel = makeViewModel(service: MockMovieService(moviesToReturn: []))

        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.state, .empty)
    }

    // MARK: - Reintentar

    // Lo que hace el botón "Reintentar": volver a llamar loadMovies cuando ya hay internet
    func testRetryAfterErrorShowsContent() async {
        let service = MockMovieService(errorToThrow: .noConnection)
        let viewModel = makeViewModel(service: service)
        await viewModel.loadMovies()
        XCTAssertEqual(viewModel.state, .error("No se pudo conectar con TMDB. Revisa tu conexión a internet."))

        service.errorToThrow = nil
        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.state, expectedContent)
    }

    // MARK: - Navegación

    // Al regresar del detalle el Home vuelve a aparecer; si ya tiene películas no consulta otra vez
    func testLoadIfNeededKeepsContentWhenReturning() async {
        let service = MockMovieService()
        let viewModel = makeViewModel(service: service)
        await viewModel.loadMoviesIfNeeded()

        // Si volviera a consultar, ahora fallaría
        service.errorToThrow = .noConnection
        await viewModel.loadMoviesIfNeeded()

        XCTAssertEqual(viewModel.state, expectedContent)
    }

    // MARK: - Ver más (paginación de las secciones)

    // La tarjeta "Ver más" pide la página 2 y la agrega al final sin repetir películas
    func testLoadMoreAppendsNextPageWithoutDuplicates() async {
        let firstPage = Array(Movie.sampleMovies[0..<5])
        let secondPage = Array(Movie.sampleMovies[4..<10]) // Oppenheimer viene repetida
        let service = MockMovieService(pages: [1: firstPage, 2: secondPage], totalPages: 2)
        let viewModel = makeViewModel(service: service)
        await viewModel.loadMovies()

        await viewModel.loadMore(in: "Populares de la semana")

        guard case .content(let sections) = viewModel.state else {
            return XCTFail("El Home debería seguir mostrando películas")
        }
        XCTAssertEqual(sections[0].movies.map { $0.id }, Movie.sampleMovies.map { $0.id })
        XCTAssertEqual(sections[0].page, 2)
        XCTAssertFalse(sections[0].canLoadMore)
        // Las otras secciones no cambian
        XCTAssertEqual(sections[1].movies, firstPage)
        XCTAssertTrue(sections[1].canLoadMore)
    }

    // Si falla "Ver más", se avisa pero no se borran las películas que ya se veían
    func testLoadMoreErrorKeepsContent() async {
        let service = MockMovieService(totalPages: 3)
        let viewModel = makeViewModel(service: service)
        await viewModel.loadMovies()
        let before = viewModel.state

        service.errorToThrow = .noConnection
        await viewModel.loadMore(in: "Acción")

        XCTAssertEqual(viewModel.state, before)
        XCTAssertEqual(viewModel.loadMoreErrorMessage, "No se pudo conectar con TMDB. Revisa tu conexión a internet.")
    }
}
