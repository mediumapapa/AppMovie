import SwiftUI

/// Almacén de estado compartido para las películas favoritas del usuario.
/// Sigue la macro @Observable de SwiftUI y vive en el entorno (@Environment)
/// para que cualquier pantalla pueda consultar, añadir o eliminar favoritos en tiempo real.
@Observable
class FavoritesStore {
    var favorites: [Movie] = []
    
    init(initialFavorites: [Movie] = [Movie.sampleMovies[0]]) {
        // Inicializamos con una película de muestra para facilitar la visualización inmediata en pruebas
        self.favorites = initialFavorites
    }
    
    /// Comprueba si una película ya se encuentra en favoritos
    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains(where: { $0.id == movie.id })
    }
    
    /// Añade una película a favoritos si no esta
    func add(_ movie: Movie) {
        if !isFavorite(movie) {
            favorites.append(movie)
        }
    }
    
    /// Elimina una película de favoritos
    func remove(_ movie: Movie) {
        favorites.removeAll(where: { $0.id == movie.id })
    }
    
    /// Alterna el estado de favorito: si existe la quita, si no existe la agrega
    func toggle(_ movie: Movie) {
        if isFavorite(movie) {
            remove(movie)
        } else {
            add(movie)
        }
    }
}
