import Foundation
import SwiftData

// Guarda las listas personalizadas en el teléfono con SwiftData.
// Usa el mismo ModelContext que FavoritesService (lo crea movies_appApp).
final class ListsService: ListsServiceProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchLists() -> [CustomList] {
        allLists().map { $0.customList }
    }

    @discardableResult
    func createList(named name: String) throws -> CustomList {
        let validName = try validatedName(name, existing: allLists().map { $0.name })
        let list = MovieList(name: validName)
        context.insert(list)
        save()
        return list.customList
    }

    // Por la regla .cascade, al borrar la lista se borran también sus películas
    func deleteList(id: UUID) {
        guard let list = savedList(id: id) else { return }
        context.delete(list)
        save()
    }

    func listIDs(containing movieID: Int) -> Set<UUID> {
        Set(entries(for: movieID).compactMap { $0.list?.listID })
    }

    func note(for movieID: Int) -> String {
        entries(for: movieID).first { !$0.note.isEmpty }?.note ?? ""
    }

    func save(movie: Movie, note: String, inLists listIDs: Set<UUID>) {
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        for list in allLists() {
            let existing = list.entries.first { $0.movieID == movie.id }
            let shouldContain = listIDs.contains(list.listID)

            switch (existing, shouldContain) {
            case (nil, true):
                let entry = MovieListEntry(movie: movie, note: cleanNote)
                context.insert(entry)
                entry.list = list
            case (let entry?, true):
                entry.note = cleanNote
            case (let entry?, false):
                context.delete(entry)
            case (nil, false):
                break
            }
        }
        save()
    }

    func remove(movieID: Int, fromList listID: UUID) {
        guard let entry = savedList(id: listID)?.entries.first(where: { $0.movieID == movieID }) else { return }
        context.delete(entry)
        save()
    }

    // MARK: - Consultas a SwiftData

    private func allLists() -> [MovieList] {
        let descriptor = FetchDescriptor<MovieList>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func savedList(id: UUID) -> MovieList? {
        var descriptor = FetchDescriptor<MovieList>(predicate: #Predicate { $0.listID == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func entries(for movieID: Int) -> [MovieListEntry] {
        let descriptor = FetchDescriptor<MovieListEntry>(
            predicate: #Predicate { $0.movieID == movieID },
            sortBy: [SortDescriptor(\.addedAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("No se pudieron guardar las listas: \(error)")
        }
    }
}
