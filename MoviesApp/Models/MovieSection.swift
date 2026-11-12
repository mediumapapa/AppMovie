import Foundation

// Sección del Home (por ejemplo "Popular this week" o un género)
// Equatable permite comparar el estado del Home en las pruebas
struct MovieSection: Identifiable, Equatable {
    let title: String
    let movies: [Movie]

    var id: String { title }
}
