//
//  HomeSearchTests.swift
//  MoviesAppTests
//
//  Pruebas del buscador del Home (HomeViewModel + MockMovieService).
//  El buscador filtra las películas que ya se cargaron, así que cada prueba primero carga
//  las películas de muestra. No se llama a TMDB, así el resultado siempre es el mismo.
//

import XCTest
@testable import movies_app

@MainActor
final class HomeSearchTests: XCTestCase {

    // MockMovieService regresa las mismas 10 películas en las tres secciones
    private func makeLoadedViewModel() async -> HomeViewModel {
        let viewModel = HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            movieService: MockMovieService(),
            favoritesService: MockFavoritesService()
        )
        await viewModel.loadMovies()
        return viewModel
    }

    // MARK: - Caso normal

    // Interstellar viene en las tres secciones, pero en los resultados aparece una sola vez
    func testSearchFindsMovieIgnoringUppercase() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.searchText = "INTERSTELLAR"

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults.map { $0.title }, ["Interstellar"])
    }

    // "Gotham" no está en ningún título, solo en la sinopsis de dos películas
    func testSearchAlsoLooksInOverview() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.searchText = "gotham"

        XCTAssertEqual(viewModel.searchResults.map { $0.title }, ["The Dark Knight", "The Batman"])
    }

    // MARK: - Casos límite

    func testSearchIgnoresSpacesAroundText() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.searchText = "   arrival  "

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults.map { $0.id }, [329865])
    }

    func testOnlySpacesIsNotASearch() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.searchText = "     "

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }

    // MARK: - Sin resultados

    func testSearchWithoutMatchesReturnsEmptyList() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.searchText = "Titanic"

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }
}
