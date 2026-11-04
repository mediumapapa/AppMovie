import SwiftUI

// Define la estructura Movie q representa una película con sus propiedades
// Posiblemente se agregue más propiedades en el futuro, como fecha de lanzamiento, calificación, etc.
// Hashable permite usar la película como valor en NavigationLink(value:)
struct Movie: Identifiable, Hashable {
    // Id de la película en TMDB. Antes era un UUID() que cambiaba cada vez que se abría la app;
    // con el id de TMDB la misma película se reconoce siempre, también en los favoritos guardados.
    let id: Int
    let title: String
    let overview: String
    let posterPath: String
}
