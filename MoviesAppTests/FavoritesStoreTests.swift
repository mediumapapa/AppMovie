//
//  FavoritesStoreTests.swift
//  MoviesAppTests
//
//  Pruebas de la regla de favoritos: agregar, no duplicar, eliminar y conservar lo guardado.
//  Cada prueba arma su propio contenedor de SwiftData, así no comparte datos con otras pruebas
//  ni con los favoritos reales del simulador, y no depende de la API de TMDB.
//

import XCTest
import SwiftData
@testable import movies_app

@MainActor
final class FavoritesStoreTests: XCTestCase {

    // MARK: - Datos de prueba

    private var dune: Movie {
        Movie(id: 693134, title: "Dune: Parte Dos", overview: "Paul Atreides se une a los Fremen.", posterPath: "popcorn.fill")
    }

    private var interstellar: Movie {
        Movie(id: 157336, title: "Interstellar", overview: "Exploradores cruzan un agujero de gusano.", posterPath: "film.fill")
    }

    // MARK: - Ayudantes

    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: FavoriteMovie.self, configurations: configuration)
    }

    private func makeStore(container: ModelContainer) -> FavoritesStore {
        FavoritesStore(service: FavoritesService(container: container))
    }

    // Cuenta los registros que hay de verdad en SwiftData, sin pasar por el store
    private func savedCount(in container: ModelContainer) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<FavoriteMovie>())
    }

    // MARK: - Caso normal

    func testAddSavesMovieInFavorites() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)

        store.add(dune)

        XCTAssertEqual(store.favorites.map { $0.id }, [693134])
        XCTAssertTrue(store.isFavorite(dune))
        XCTAssertEqual(try savedCount(in: container), 1)
    }

    func testRemoveDeletesOnlyThatMovie() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)
        store.add(dune)
        store.add(interstellar)

        store.remove(dune)

        XCTAssertEqual(store.favorites.map { $0.id }, [157336])
        XCTAssertFalse(store.isFavorite(dune))
        XCTAssertEqual(try savedCount(in: container), 1)
    }

    // MARK: - Casos límite

    func testAddingSameMovieTwiceKeepsOneRecord() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)

        store.add(dune)
        store.add(dune)

        XCTAssertEqual(store.favorites.count, 1)
        XCTAssertEqual(try savedCount(in: container), 1)
    }

    // Si la misma película llega otra vez con otro texto (por ejemplo, actualizada desde la API),
    // se reconoce por su id de TMDB y no se guarda otra vez.
    func testMovieIsRecognizedByIdEvenIfTitleChanges() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)
        let duneFromAPI = Movie(id: 693134, title: "Dune: Part Two", overview: "Otro texto", posterPath: "/poster.jpg")

        store.add(dune)
        store.add(duneFromAPI)

        XCTAssertTrue(store.isFavorite(duneFromAPI))
        XCTAssertEqual(try savedCount(in: container), 1)
        XCTAssertEqual(store.favorites.first?.title, "Dune: Parte Dos")
    }

    func testToggleTwiceLeavesMovieOutOfFavorites() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)

        store.toggle(dune)
        XCTAssertTrue(store.isFavorite(dune))

        store.toggle(dune)
        XCTAssertFalse(store.isFavorite(dune))
        XCTAssertEqual(try savedCount(in: container), 0)
    }

    // MARK: - Sin resultados / entrada inválida

    func testNewStoreStartsWithoutFavorites() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)

        XCTAssertTrue(store.favorites.isEmpty)
        XCTAssertFalse(store.isFavorite(dune))
    }

    func testRemovingMovieThatIsNotSavedChangesNothing() throws {
        let container = try makeInMemoryContainer()
        let store = makeStore(container: container)
        store.add(dune)

        store.remove(interstellar)

        XCTAssertEqual(store.favorites.map { $0.id }, [693134])
        XCTAssertEqual(try savedCount(in: container), 1)
    }

    // MARK: - Persistencia

    // Simula cerrar y volver a abrir la app: se guarda en un archivo temporal,
    // se suelta ese contenedor y se abre otro nuevo apuntando al mismo archivo.
    func testFavoritesRemainAfterReopeningTheStore() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("favoritos-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
            }
        }

        do {
            let firstContainer = try ModelContainer(for: FavoriteMovie.self, configurations: ModelConfiguration(url: storeURL))
            let firstStore = makeStore(container: firstContainer)
            firstStore.add(dune)
            firstStore.add(interstellar)
            firstStore.remove(interstellar)
        }

        let reopenedContainer = try ModelContainer(for: FavoriteMovie.self, configurations: ModelConfiguration(url: storeURL))
        let reopenedStore = makeStore(container: reopenedContainer)

        XCTAssertEqual(reopenedStore.favorites.map { $0.id }, [693134])
        XCTAssertEqual(reopenedStore.favorites.first?.title, "Dune: Parte Dos")
    }
}
