import SwiftUI

// Define la estructura Movie q representa una película con sus propiedades
// Posiblemente se agregue más propiedades en el futuro, como fecha de lanzamiento, calificación, etc.
// Hashable permite usar la película como valor en NavigationLink(value:)
struct Movie: Identifiable, Hashable {
    var id = UUID()
    let title: String
    let overview: String
    let posterPath: String
}
