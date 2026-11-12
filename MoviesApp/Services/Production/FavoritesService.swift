import Foundation
import SwiftData

// Guarda los favoritos en el teléfono con SwiftData.
// Solo recibe el ModelContext: el contenedor lo crea y lo conserva movies_appApp
// (en las pruebas, la propia prueba con un contenedor en memoria).
final class FavoritesService: FavoritesServiceProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Favoritos en el orden en que se agregaron
    func fetchFavorites() -> [Movie] {
        let descriptor = FetchDescriptor<FavoriteMovie>(
            sortBy: [SortDescriptor(\.addedAt)]
        )
        let saved = (try? context.fetch(descriptor)) ?? []
        return saved.map { $0.movie }
    }

    func isSaved(movieID: Int) -> Bool {
        savedFavorite(movieID: movieID) != nil
    }

    // Si la película ya está guardada no se vuelve a insertar
    func add(_ movie: Movie) {
        guard !isSaved(movieID: movie.id) else { return }

        context.insert(FavoriteMovie(movie: movie))
        save()
    }

    // Si la película no está guardada no hace nada
    func remove(movieID: Int) {
        guard let favorite = savedFavorite(movieID: movieID) else { return }

        context.delete(favorite)
        save()
    }

    // Busca el registro guardado con ese id de TMDB
    private func savedFavorite(movieID: Int) -> FavoriteMovie? {
        var descriptor = FetchDescriptor<FavoriteMovie>(
            predicate: #Predicate { $0.movieID == movieID }
        )
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("No se pudieron guardar los favoritos: \(error)")
        }
    }
}
