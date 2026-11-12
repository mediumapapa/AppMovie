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
            favoritesService: MockFavoritesService()
        )
    }

    // Lo que debe mostrar el Home cuando el mock regresa las películas de muestra
    private var expectedContent: HomeState {
        .content([
            MovieSection(title: "Popular this week", movies: Movie.sampleMovies),
            MovieSection(title: "Action", movies: Movie.sampleMovies),
            MovieSection(title: "Drama", movies: Movie.sampleMovies)
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
}
