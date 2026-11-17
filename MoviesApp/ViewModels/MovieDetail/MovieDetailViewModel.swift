import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    private let favoritesService: FavoritesServiceProtocol
    private let listsService: ListsServiceProtocol

    let movie: Movie
    private(set) var isFavorite: Bool
    // En cuántas listas personalizadas está la película
    private(set) var listCount: Int
    // Nota personal que el usuario escribió para la película
    private(set) var personalNote: String

    var showAddToList = false

    init(movie: Movie, favoritesService: FavoritesServiceProtocol, listsService: ListsServiceProtocol) {
        self.movie = movie
        self.favoritesService = favoritesService
        self.listsService = listsService
        self.isFavorite = favoritesService.isSaved(movieID: movie.id)
        self.listCount = listsService.listIDs(containing: movie.id).count
        self.personalNote = listsService.note(for: movie.id)
    }

    var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }

    var favoriteTitle: String {
        isFavorite ? "En favoritos" : "Agregar a favoritos"
    }

    var listIcon: String {
        listCount > 0 ? "checkmark.circle.fill" : "plus.circle"
    }

    var listTitle: String {
        switch listCount {
        case 0: return "Agregar a lista"
        case 1: return "En 1 lista"
        default: return "En \(listCount) listas"
        }
    }

    // Si ya está guardada la quita, si no la agrega.
    // Después vuelve a preguntar al servicio para que el botón muestre lo que de verdad quedó guardado.
    func toggleFavorite() {
        if isFavorite {
            favoritesService.remove(movieID: movie.id)
        } else {
            favoritesService.add(movie)
        }
        isFavorite = favoritesService.isSaved(movieID: movie.id)
    }

    func makeAddToListViewModel() -> AddToListViewModel {
        AddToListViewModel(movie: movie, listsService: listsService)
    }

    // Se llama al cerrar la ventana de listas y al volver a la pantalla
    func refresh() {
        isFavorite = favoritesService.isSaved(movieID: movie.id)
        listCount = listsService.listIDs(containing: movie.id).count
        personalNote = listsService.note(for: movie.id)
    }
}
