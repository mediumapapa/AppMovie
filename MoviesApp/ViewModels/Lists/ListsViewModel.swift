import Foundation
import Observation

// Pantalla "Mis listas": muestra una lista a la vez, con un selector para cambiar de lista,
// y va mostrando sus películas de pocas en pocas con el botón de tres puntos.
@MainActor
@Observable
final class ListsViewModel {
    // Cuántas películas se muestran al abrir una lista y cuántas más con cada toque al botón "..."
    static let pageSize = 5

    private let listsService: ListsServiceProtocol

    private(set) var lists: [CustomList] = []
    private(set) var selectedListID: UUID?
    private(set) var visibleCount = ListsViewModel.pageSize

    // Ventana para crear una lista nueva
    var showCreateListAlert = false
    var newListName = ""
    // Confirmación antes de borrar la lista seleccionada
    var showDeleteListAlert = false
    var errorMessage: String?

    init(listsService: ListsServiceProtocol) {
        self.listsService = listsService
    }

    var hasLists: Bool {
        !lists.isEmpty
    }

    var selectedList: CustomList? {
        lists.first { $0.id == selectedListID }
    }

    var visibleItems: [ListItem] {
        Array(selectedList?.items.prefix(visibleCount) ?? [])
    }

    var canLoadMore: Bool {
        (selectedList?.items.count ?? 0) > visibleCount
    }

    // La vista la llama al aparecer, también al regresar del detalle por si ahí se cambió algo
    func loadLists() {
        lists = listsService.fetchLists()
        if selectedList == nil {
            selectedListID = lists.first?.id
            visibleCount = Self.pageSize
        }
    }

    // Flecha junto al nombre de la lista: cambia a otra lista y vuelve a mostrar solo las primeras películas
    func select(_ listID: UUID) {
        guard listID != selectedListID else { return }
        selectedListID = listID
        visibleCount = Self.pageSize
    }

    // Botón de tres puntos al final: muestra las siguientes películas de la lista
    func loadMore() {
        guard canLoadMore else { return }
        visibleCount += Self.pageSize
    }

    func startCreatingList() {
        newListName = ""
        errorMessage = nil
        showCreateListAlert = true
    }

    // Crea la lista con el nombre escrito y la deja seleccionada
    func createList() {
        do {
            let list = try listsService.createList(named: newListName)
            lists = listsService.fetchLists()
            selectedListID = list.id
            visibleCount = Self.pageSize
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        newListName = ""
    }

    func deleteSelectedList() {
        guard let selectedListID else { return }
        listsService.deleteList(id: selectedListID)
        self.selectedListID = nil
        loadLists()
    }

    // Botón "X" de cada película: la quita solo de esta lista
    func remove(_ item: ListItem) {
        guard let selectedListID else { return }
        listsService.remove(movieID: item.movie.id, fromList: selectedListID)
        lists = listsService.fetchLists()
    }
}
