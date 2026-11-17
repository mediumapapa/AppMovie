import Foundation

// Contrato para las listas personalizadas.
// En la app lo cumple ListsService (SwiftData, Production) y en previews y pruebas MockListsService (Mock).
protocol ListsServiceProtocol {
    // Listas en el orden en que se crearon
    func fetchLists() -> [CustomList]
    // Crea una lista vacía. Lanza ListsError si el nombre está vacío o ya existe.
    @discardableResult
    func createList(named name: String) throws -> CustomList
    func deleteList(id: UUID)

    // Ids de las listas donde ya está la película
    func listIDs(containing movieID: Int) -> Set<UUID>
    // Nota personal que el usuario escribió para la película ("" si no tiene)
    func note(for movieID: Int) -> String
    // Deja la película exactamente en las listas indicadas, con esa nota:
    // la agrega donde falta, la quita de las que ya no se marcaron y actualiza la nota en todas.
    func save(movie: Movie, note: String, inLists listIDs: Set<UUID>)
    func remove(movieID: Int, fromList listID: UUID)
}

enum ListsError: LocalizedError, Equatable {
    case emptyName
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Escribe un nombre para la lista."
        case .duplicateName:
            return "Ya tienes una lista con ese nombre."
        }
    }
}

extension ListsServiceProtocol {
    // Regla compartida por el servicio real y el de prueba: nombre sin espacios sobrantes,
    // no vacío y sin repetir (sin importar mayúsculas)
    func validatedName(_ name: String, existing: [String]) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ListsError.emptyName }
        guard !existing.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw ListsError.duplicateName
        }
        return trimmed
    }
}
