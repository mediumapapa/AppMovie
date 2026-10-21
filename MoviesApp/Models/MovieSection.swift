import Foundation

// Sección del Home (por ejemplo "Popular this week" o un género)
struct MovieSection: Identifiable {
    let title: String
    let movies: [Movie]

    var id: String { title }
}
