import Foundation

// Contrato para guardar y leer los favoritos.
// FavoritesStore solo conoce este protocolo, no sabe que por debajo está SwiftData.
protocol FavoritesServiceProtocol {
    func fetchFavorites() -> [Movie]
    func isSaved(movieID: Int) -> Bool
    func add(_ movie: Movie)
    func remove(movieID: Int)
}
