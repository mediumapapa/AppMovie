//
//  HomeSearchTests.swift
//  MoviesAppTests
//
//  Pruebas del buscador del Home (HomeViewModel + MockMovieService).
//  Usan las películas locales de prueba, así el resultado siempre es el mismo y no se llama a TMDB.
//

import XCTest
@testable import movies_app

@MainActor
final class HomeSearchTests: XCTestCase {

    private func makeViewModel() -> HomeViewModel {
        HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            favoritesStore: .inMemory(),
            service: MockMovieService()
        )
    }

    // MARK: - Caso normal

    func testSearchFindsMovieIgnoringUppercase() {
        let viewModel = makeViewModel()

        viewModel.searchText = "INTERSTELLAR"

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults.map { $0.title }, ["Interstellar"])
    }

    // "Gotham" no está en ningún título, solo en la sinopsis de dos películas
    func testSearchAlsoLooksInOverview() {
        let viewModel = makeViewModel()

        viewModel.searchText = "gotham"

        XCTAssertEqual(viewModel.searchResults.map { $0.title }, ["The Dark Knight", "The Batman"])
    }

    // MARK: - Casos límite

    func testSearchIgnoresSpacesAroundText() {
        let viewModel = makeViewModel()

        viewModel.searchText = "   arrival  "

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults.map { $0.id }, [329865])
    }

    func testOnlySpacesIsNotASearch() {
        let viewModel = makeViewModel()

        viewModel.searchText = "     "

        XCTAssertFalse(viewModel.isSearching)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }

    // MARK: - Sin resultados

    func testSearchWithoutMatchesReturnsEmptyList() {
        let viewModel = makeViewModel()

        viewModel.searchText = "Titanic"

        XCTAssertTrue(viewModel.isSearching)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }
}
