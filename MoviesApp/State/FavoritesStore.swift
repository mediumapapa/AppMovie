import SwiftUI
import SwiftData

/// Almacén de estado compartido para las películas favoritas del usuario.
/// Lo crea movies_appApp y se pasa por init a los ViewModels de Home, Detalle y Favoritos.
///
/// Los favoritos se guardan con SwiftData a través de FavoritesServiceProtocol.
/// `favorites` no se edita a mano: después de cada cambio se vuelve a leer de lo guardado,
/// así la base de SwiftData es la única fuente de verdad y las vistas siempre muestran lo que hay en ella.
@Observable
class FavoritesStore {
    private(set) var favorites: [Movie] = []

    private let service: FavoritesServiceProtocol

    init(service: FavoritesServiceProtocol) {
        self.service = service
        reload()
    }

    /// Comprueba si una película ya se encuentra en favoritos
    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains(where: { $0.id == movie.id })
    }

    /// Añade una película a favoritos. El servicio no la guarda dos veces.
    func add(_ movie: Movie) {
        service.add(movie)
        reload()
    }

    /// Elimina una película de favoritos
    func remove(_ movie: Movie) {
        service.remove(movieID: movie.id)
        reload()
    }

    /// Alterna el estado de favorito: si existe la quita, si no existe la agrega
    func toggle(_ movie: Movie) {
        if isFavorite(movie) {
            remove(movie)
        } else {
            add(movie)
        }
    }

    /// Vuelve a leer los favoritos guardados
    private func reload() {
        favorites = service.fetchFavorites()
    }
}

extension FavoritesStore {
    /// Store para los #Preview: usa SwiftData solo en memoria, no toca los favoritos reales.
    static func inMemory(with movies: [Movie] = []) -> FavoritesStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: FavoriteMovie.self, configurations: configuration)
        } catch {
            fatalError("No se pudo crear el contenedor en memoria: \(error)")
        }

        let store = FavoritesStore(service: FavoritesService(container: container))
        movies.forEach { store.add($0) }
        return store
    }
}
