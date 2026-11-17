import Foundation

// Listas de prueba para los #Preview y las pruebas que no revisan SwiftData.
// Las guarda en un arreglo, igual que MockFavoritesService.
final class MockListsService: ListsServiceProtocol {

    private var lists: [CustomList]

    init(lists: [CustomList] = []) {
        self.lists = lists
    }

    // Listas de ejemplo para ver la pantalla con contenido en los previews
    static var sample: MockListsService {
        let movies = Movie.sampleMovies
        return MockListsService(lists: [
            CustomList(id: UUID(), name: "Clásicos de domingo", items: [
                ListItem(movie: movies[1], note: "La vi con mi papá en el cine. La música me encanta."),
                ListItem(movie: movies[5], note: "El mejor villano de todos."),
                ListItem(movie: movies[3], note: "")
            ]),
            CustomList(id: UUID(), name: "Para ver con los nietos", items: [
                ListItem(movie: movies[6], note: "Larga, pero vale la pena.")
            ])
        ])
    }

    func fetchLists() -> [CustomList] {
        lists
    }

    @discardableResult
    func createList(named name: String) throws -> CustomList {
        let validName = try validatedName(name, existing: lists.map { $0.name })
        let list = CustomList(id: UUID(), name: validName, items: [])
        lists.append(list)
        return list
    }

    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
    }

    func listIDs(containing movieID: Int) -> Set<UUID> {
        Set(lists.filter { list in list.items.contains { $0.movie.id == movieID } }.map { $0.id })
    }

    func note(for movieID: Int) -> String {
        lists.flatMap { $0.items }.first { $0.movie.id == movieID && !$0.note.isEmpty }?.note ?? ""
    }

    func save(movie: Movie, note: String, inLists listIDs: Set<UUID>) {
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        lists = lists.map { list in
            var items = list.items
            if let index = items.firstIndex(where: { $0.movie.id == movie.id }) {
                if listIDs.contains(list.id) {
                    items[index] = ListItem(movie: items[index].movie, note: cleanNote)
                } else {
                    items.remove(at: index)
                }
            } else if listIDs.contains(list.id) {
                items.append(ListItem(movie: movie, note: cleanNote))
            }
            return CustomList(id: list.id, name: list.name, items: items)
        }
    }

    func remove(movieID: Int, fromList listID: UUID) {
        lists = lists.map { list in
            guard list.id == listID else { return list }
            return CustomList(id: list.id, name: list.name, items: list.items.filter { $0.movie.id != movieID })
        }
    }
}
