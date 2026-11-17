//
//  ListsTests.swift
//  MoviesAppTests
//
//  Pruebas de las listas personalizadas: crear listas, guardar películas con su nota,
//  moverlas entre listas, borrar y conservar lo guardado. Prueban ListsService con SwiftData
//  en memoria y los ViewModels de la pantalla de listas, la ventana "Agregar a lista" y el detalle.
//

import XCTest
import SwiftData
@testable import movies_app

@MainActor
final class ListsTests: XCTestCase {

    private let interstellar = Movie.sampleMovies[1]
    private let darkKnight = Movie.sampleMovies[5]

    private var container: ModelContainer!

    private func makeService(url: URL? = nil) throws -> ListsService {
        let configuration = url.map { ModelConfiguration(url: $0) } ?? ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: FavoriteMovie.self, MovieList.self, MovieListEntry.self,
            configurations: configuration
        )
        return ListsService(context: container.mainContext)
    }

    private func entryCount() throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<MovieListEntry>())
    }

    // MARK: - Caso normal

    func testSaveMovieWithNoteInList() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos de domingo")

        service.save(movie: interstellar, note: "  La vi con mi papá.  ", inLists: [classics.id])

        let list = try XCTUnwrap(service.fetchLists().first)
        XCTAssertEqual(list.name, "Clásicos de domingo")
        XCTAssertEqual(list.items, [ListItem(movie: interstellar, note: "La vi con mi papá.")])
        XCTAssertEqual(service.listIDs(containing: interstellar.id), [classics.id])
        XCTAssertEqual(service.note(for: interstellar.id), "La vi con mi papá.")
    }

    // Guardar otra vez deja la película solo en las listas marcadas y actualiza la nota
    func testSaveMovesMovieBetweenListsAndUpdatesNote() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        let grandkids = try service.createList(named: "Con los nietos")
        service.save(movie: interstellar, note: "Primera nota", inLists: [classics.id])

        service.save(movie: interstellar, note: "Nota nueva", inLists: [grandkids.id])

        XCTAssertEqual(service.listIDs(containing: interstellar.id), [grandkids.id])
        XCTAssertEqual(service.note(for: interstellar.id), "Nota nueva")
        XCTAssertEqual(try entryCount(), 1)
    }

    func testRemoveFromOneListKeepsTheOther() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        let grandkids = try service.createList(named: "Con los nietos")
        service.save(movie: darkKnight, note: "", inLists: [classics.id, grandkids.id])

        service.remove(movieID: darkKnight.id, fromList: classics.id)

        XCTAssertEqual(service.listIDs(containing: darkKnight.id), [grandkids.id])
    }

    // Al borrar una lista se borran también sus películas (deleteRule: .cascade)
    func testDeletingListDeletesItsMovies() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        service.save(movie: interstellar, note: "", inLists: [classics.id])
        service.save(movie: darkKnight, note: "", inLists: [classics.id])

        service.deleteList(id: classics.id)

        XCTAssertTrue(service.fetchLists().isEmpty)
        XCTAssertEqual(try entryCount(), 0)
    }

    // MARK: - Entrada inválida

    func testEmptyOrRepeatedNameIsRejected() throws {
        let service = try makeService()
        try service.createList(named: "Clásicos")

        XCTAssertThrowsError(try service.createList(named: "   ")) { error in
            XCTAssertEqual(error as? ListsError, .emptyName)
        }
        XCTAssertThrowsError(try service.createList(named: " clásicos ")) { error in
            XCTAssertEqual(error as? ListsError, .duplicateName)
        }
        XCTAssertEqual(service.fetchLists().count, 1)
    }

    // MARK: - Persistencia

    func testListsRemainAfterReopening() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("listas-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
            }
        }

        let firstService = try makeService(url: storeURL)
        let classics = try firstService.createList(named: "Clásicos")
        firstService.save(movie: interstellar, note: "Obra maestra", inLists: [classics.id])

        let reopenedService = try makeService(url: storeURL)

        XCTAssertEqual(reopenedService.fetchLists().first?.items, [ListItem(movie: interstellar, note: "Obra maestra")])
    }

    // MARK: - Pantalla "Mis listas"

    // Muestra 5 películas y el botón de tres puntos agrega 5 más cada vez
    func testListsScreenShowsFiveAtATimeAndLoadsMore() throws {
        let service = try makeService()
        let list = try service.createList(named: "Todas")
        for movie in Movie.sampleMovies + [Movie(id: 1, title: "Extra 1", overview: "", posterPath: ""),
                                           Movie(id: 2, title: "Extra 2", overview: "", posterPath: "")] {
            service.save(movie: movie, note: "", inLists: [list.id])
        }
        let viewModel = ListsViewModel(listsService: service)
        viewModel.loadLists()

        XCTAssertEqual(viewModel.visibleItems.count, 5)
        XCTAssertTrue(viewModel.canLoadMore)

        viewModel.loadMore()
        XCTAssertEqual(viewModel.visibleItems.count, 10)

        viewModel.loadMore()
        XCTAssertEqual(viewModel.visibleItems.count, 12)
        XCTAssertFalse(viewModel.canLoadMore)
    }

    // La flecha junto al nombre cambia de lista y vuelve a mostrar desde el principio
    func testSelectingAnotherListShowsItsMovies() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        let grandkids = try service.createList(named: "Con los nietos")
        service.save(movie: interstellar, note: "", inLists: [classics.id])
        service.save(movie: darkKnight, note: "Para el sábado", inLists: [grandkids.id])
        let viewModel = ListsViewModel(listsService: service)
        viewModel.loadLists()
        XCTAssertEqual(viewModel.selectedList?.name, "Clásicos")

        viewModel.select(grandkids.id)

        XCTAssertEqual(viewModel.visibleItems, [ListItem(movie: darkKnight, note: "Para el sábado")])
    }

    func testCreateListFromListsScreenSelectsIt() throws {
        let viewModel = ListsViewModel(listsService: try makeService())
        viewModel.loadLists()
        XCTAssertFalse(viewModel.hasLists)

        viewModel.startCreatingList()
        viewModel.newListName = "Favoritas de los 80"
        viewModel.createList()

        XCTAssertEqual(viewModel.selectedList?.name, "Favoritas de los 80")
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Ventana "Agregar a lista" y detalle

    // Caso reportado: crear una lista desde la ventana y cerrarla sin tocar otro botón.
    // La película debe quedar guardada en la lista nueva en cuanto se toca "Crear".
    func testCreatingListFromSheetAddsMovieImmediately() throws {
        let service = try makeService()
        let sheet = AddToListViewModel(movie: interstellar, listsService: service)

        sheet.newListName = "Ciencia ficción"
        sheet.createList()

        let list = try XCTUnwrap(service.fetchLists().first)
        XCTAssertEqual(list.name, "Ciencia ficción")
        XCTAssertEqual(list.items.map { $0.movie.id }, [interstellar.id])
        XCTAssertEqual(sheet.confirmationMessage, "Se creó Ciencia ficción y se guardó la película")
    }

    // Marcar o desmarcar una lista existente también se guarda al momento
    func testTogglingListInSheetSavesImmediately() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        let sheet = AddToListViewModel(movie: darkKnight, listsService: service)
        let classicsList = try XCTUnwrap(sheet.lists.first)

        sheet.toggle(classicsList)
        XCTAssertEqual(service.listIDs(containing: darkKnight.id), [classics.id])

        sheet.toggle(classicsList)
        XCTAssertTrue(service.listIDs(containing: darkKnight.id).isEmpty)
    }

    func testAddToListSheetCreatesListAndSavesNote() throws {
        let service = try makeService()
        let sheet = AddToListViewModel(movie: interstellar, listsService: service)

        sheet.newListName = "Ciencia ficción"
        sheet.createList()
        sheet.note = "La música de Hans Zimmer."
        sheet.save()

        let detail = MovieDetailViewModel(movie: interstellar, favoritesService: MockFavoritesService(), listsService: service)
        XCTAssertEqual(detail.listCount, 1)
        XCTAssertEqual(detail.listTitle, "En 1 lista")
        XCTAssertEqual(detail.personalNote, "La música de Hans Zimmer.")
    }

    // Al volver a abrir la ventana aparecen marcadas las listas donde ya está y su nota
    func testAddToListSheetRemembersSelectionAndNote() throws {
        let service = try makeService()
        let classics = try service.createList(named: "Clásicos")
        service.save(movie: darkKnight, note: "El mejor villano.", inLists: [classics.id])

        let sheet = AddToListViewModel(movie: darkKnight, listsService: service)

        XCTAssertEqual(sheet.selectedListIDs, [classics.id])
        XCTAssertEqual(sheet.note, "El mejor villano.")
    }

    func testNoteIsLimitedTo300Characters() throws {
        let sheet = AddToListViewModel(movie: interstellar, listsService: MockListsService())

        sheet.note = String(repeating: "a", count: 350)
        sheet.limitNote()

        XCTAssertEqual(sheet.note.count, AddToListViewModel.noteLimit)
    }
}
