import Foundation
import Observation

// Ventana que abre el botón "Agregar a lista" del detalle:
// el usuario marca en qué listas guardar la película, puede crear una lista nueva
// y escribe una nota o sinopsis personal para esa película.
//
// Cada cambio se guarda al momento (marcar una lista, crear una lista, cerrar la ventana),
// así no se pierde nada si el usuario cierra deslizando hacia abajo sin buscar un botón "Guardar".
@MainActor
@Observable
final class AddToListViewModel {
    private let listsService: ListsServiceProtocol

    let movie: Movie
    private(set) var lists: [CustomList] = []
    private(set) var selectedListIDs: Set<UUID> = []
    var note: String = ""
    var newListName: String = ""
    var errorMessage: String?
    // Confirmación que se muestra después de cada cambio, por ejemplo "Guardada en Clásicos"
    private(set) var confirmationMessage: String?

    // Máximo de caracteres de la nota, para que siga siendo "una pequeña sinopsis"
    static let noteLimit = 300

    init(movie: Movie, listsService: ListsServiceProtocol) {
        self.movie = movie
        self.listsService = listsService
        load()
    }

    // Carga las listas y marca las que ya tienen la película, con la nota que ya se había escrito
    func load() {
        lists = listsService.fetchLists()
        selectedListIDs = listsService.listIDs(containing: movie.id)
        note = listsService.note(for: movie.id)
    }

    func isSelected(_ list: CustomList) -> Bool {
        selectedListIDs.contains(list.id)
    }

    // Marcar o desmarcar una lista agrega o quita la película en ese momento
    func toggle(_ list: CustomList) {
        if selectedListIDs.contains(list.id) {
            selectedListIDs.remove(list.id)
            confirmationMessage = "Se quitó de \(list.name)"
        } else {
            selectedListIDs.insert(list.id)
            confirmationMessage = "Guardada en \(list.name)"
        }
        save()
    }

    // Crea la lista con el nombre escrito y guarda la película en ella de inmediato
    func createList() {
        do {
            let list = try listsService.createList(named: newListName)
            selectedListIDs.insert(list.id)
            save()
            lists = listsService.fetchLists()
            newListName = ""
            errorMessage = nil
            confirmationMessage = "Se creó \(list.name) y se guardó la película"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Recorta la nota si se pasa del límite (se llama cada vez que cambia el texto)
    func limitNote() {
        if note.count > Self.noteLimit {
            note = String(note.prefix(Self.noteLimit))
        }
    }

    // Deja la película solo en las listas marcadas, con su nota.
    // Se llama en cada cambio y al cerrar la ventana (botón "Listo" o deslizando hacia abajo).
    func save() {
        listsService.save(movie: movie, note: note, inLists: selectedListIDs)
    }
}
