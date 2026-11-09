import Foundation

// Contrato para guardar y leer los favoritos.
// Los ViewModels solo conocen este protocolo, no saben que por debajo está SwiftData.
// En la app lo cumple FavoritesService (Production) y en los previews MockFavoritesService (Mock).
protocol FavoritesServiceProtocol {
    func fetchFavorites() -> [Movie]
    func isSaved(movieID: Int) -> Bool
    func add(_ movie: Movie)
    func remove(movieID: Int)
}
