//
//  FavoritesTests.swift
//  MoviesAppTests
//
//  Pruebas de la regla de favoritos: agregar, no duplicar, eliminar y conservar lo guardado.
//  Prueban FavoritesService con SwiftData y los ViewModels que lo usan (Detalle, Favoritos y Home).
//  Cada prueba arma su propio contenedor de SwiftData en memoria, así no comparte datos con otras pruebas
//  y no depende de la API de TMDB.
//

import XCTest
import SwiftData
@testable import movies_app

@MainActor
final class FavoritesTests: XCTestCase {

    // MARK: - Datos de prueba

    private var dune: Movie {
        Movie(id: 693134, title: "Dune: Parte Dos", overview: "Paul Atreides se une a los Fremen.", posterPath: "popcorn.fill")
    }

    private var interstellar: Movie {
        Movie(id: 157336, title: "Interstellar", overview: "Exploradores cruzan un agujero de gusano.", posterPath: "film.fill")
    }

    // MARK: - Ayudantes

    // El servicio solo recibe el contexto, así que la prueba conserva el contenedor
    // mientras dura (igual que movies_appApp en la app). XCTest crea una instancia nueva por prueba.
    private var container: ModelContainer!

    private func makeService() throws -> FavoritesService {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: FavoriteMovie.self, configurations: configuration)
        return FavoritesService(context: container.mainContext)
    }

    // Cuenta los registros que hay de verdad en SwiftData, con un contexto aparte del que usa el servicio
    private func savedCount() throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<FavoriteMovie>())
    }

    // MARK: - Caso normal

    func testAddSavesMovieInFavorites() throws {
        let service = try makeService()

        service.add(dune)

        XCTAssertEqual(service.fetchFavorites().map { $0.id }, [693134])
        XCTAssertTrue(service.isSaved(movieID: dune.id))
        XCTAssertEqual(try savedCount(), 1)
    }

    // Lo que hace la "X" de la pantalla de Favoritos
    func testRemoveDeletesOnlyThatMovie() throws {
        let service = try makeService()
        service.add(dune)
        service.add(interstellar)
        let viewModel = FavoritesViewModel(favoritesService: service)
        viewModel.loadFavorites()

        viewModel.remove(dune)

        XCTAssertEqual(viewModel.favorites.map { $0.id }, [157336])
        XCTAssertFalse(service.isSaved(movieID: dune.id))
        XCTAssertEqual(try savedCount(), 1)
    }

    // El punto rojo del Home aparece después de guardar un favorito
    func testHomeShowsFavoritesIndicatorAfterRefresh() throws {
        let service = try makeService()
        let viewModel = HomeViewModel(
            authStore: AuthStore(isLoggedIn: true, currentUser: "Prueba"),
            movieService: MockMovieService(),
            favoritesService: service
        )
        viewModel.refreshFavorites()
        XCTAssertFalse(viewModel.hasFavorites)

        service.add(dune)
        viewModel.refreshFavorites()

        XCTAssertTrue(viewModel.hasFavorites)
    }

    // MARK: - Casos límite

    func testAddingSameMovieTwiceKeepsOneRecord() throws {
        let service = try makeService()

        service.add(dune)
        service.add(dune)

        XCTAssertEqual(service.fetchFavorites().count, 1)
        XCTAssertEqual(try savedCount(), 1)
    }

    // Si la misma película llega otra vez con otro texto (por ejemplo, actualizada desde la API),
    // se reconoce por su id de TMDB y no se guarda otra vez.
    func testMovieIsRecognizedByIdEvenIfTitleChanges() throws {
        let service = try makeService()
        let duneFromAPI = Movie(id: 693134, title: "Dune: Part Two", overview: "Otro texto", posterPath: "/poster.jpg")

        service.add(dune)
        service.add(duneFromAPI)

        XCTAssertTrue(service.isSaved(movieID: duneFromAPI.id))
        XCTAssertEqual(try savedCount(), 1)
        XCTAssertEqual(service.fetchFavorites().first?.title, "Dune: Parte Dos")
    }

    // Lo que hace el botón de corazón del detalle
    func testToggleTwiceLeavesMovieOutOfFavorites() throws {
        let service = try makeService()
        let viewModel = MovieDetailViewModel(movie: dune, favoritesService: service)

        viewModel.toggleFavorite()
        XCTAssertTrue(viewModel.isFavorite)

        viewModel.toggleFavorite()
        XCTAssertFalse(viewModel.isFavorite)
        XCTAssertEqual(try savedCount(), 0)
    }

    // MARK: - Sin resultados / entrada inválida

    func testFavoritesStartEmpty() throws {
        let service = try makeService()
        let viewModel = FavoritesViewModel(favoritesService: service)

        viewModel.loadFavorites()

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(service.isSaved(movieID: dune.id))
    }

    func testRemovingMovieThatIsNotSavedChangesNothing() throws {
        let service = try makeService()
        service.add(dune)

        service.remove(movieID: interstellar.id)

        XCTAssertEqual(service.fetchFavorites().map { $0.id }, [693134])
        XCTAssertEqual(try savedCount(), 1)
    }

    // MARK: - Persistencia

    // Simula cerrar y volver a abrir la app: se guarda en un archivo temporal,
    // se suelta ese contenedor y se abre otro nuevo apuntando al mismo archivo.
    func testFavoritesRemainAfterReopening() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("favoritos-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
            }
        }

        container = try ModelContainer(for: FavoriteMovie.self, configurations: ModelConfiguration(url: storeURL))
        let firstService = FavoritesService(context: container.mainContext)
        firstService.add(dune)
        firstService.add(interstellar)
        firstService.remove(movieID: interstellar.id)

        // Se reemplaza el contenedor por uno nuevo sobre el mismo archivo, como al volver a abrir la app
        container = try ModelContainer(for: FavoriteMovie.self, configurations: ModelConfiguration(url: storeURL))
        let reopenedService = FavoritesService(context: container.mainContext)

        XCTAssertEqual(reopenedService.fetchFavorites().map { $0.id }, [693134])
        XCTAssertEqual(reopenedService.fetchFavorites().first?.title, "Dune: Parte Dos")
    }
}
